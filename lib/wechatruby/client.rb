# coding: utf-8
module Wechatruby
  class Client
    attr_accessor :id, :secret, :mch_id, :key
    def initialize(options)
      @id = options[:id]
      @secret = options[:secret]
      @mch_id = options[:mch_id]
      @key = options[:key]
    end

    def qr_code_url(callback_url)
      query = {
        appid: id,
        redirect_uri: callback_url,
        response_type: 'code',
        scope: 'snsapi_login',
        state: 'qr_code',
      }.to_query

      return "https://open.weixin.qq.com/connect/qrconnect?#{query}#wechat_redirect"
    end

    def code_request_url(callback_url, scope='snsapi_userinfo')
      query = {
        appid: self.id,
        redirect_uri: callback_url,
        response_type: 'code',
        scope: scope,
        state: 'web_code',
      }.to_query
      return "https://open.weixin.qq.com/connect/oauth2/authorize?#{query}#wechat_redirect"
    end

    def get_user_info(code)
      auth_data = access_token(code)
      pp '-----------------------'
      pp auth_data
      query = {
        access_token: auth_data['access_token'],
        openid: auth_data['openid'],
        lang: 'zh_CN'
      }.to_query
      url = "https://api.weixin.qq.com/sns/userinfo?#{query}"
      open(url) do |resp|
        JSON.parse(resp.read)
      end
    end

    # 用于小程序端获取openid
    def get_session_by(code)
      wx_url = "https://api.weixin.qq.com/sns/jscode2session?appid=#{self.id}&secret=#{self.secret}&js_code=#{code}&grant_type=authorization_code"

      open(wx_url) do |resp|
        JSON.parse(resp.read)
      end
    end

    # js sdk config
    #
    # TODO cache access_token
    def web_jsapi_params(url, *args)
      token = jsapi_access_token['access_token']
      pp token
      ticket = jsapi_ticket(token)

      jsapi_params = {
        # :appId => self.id,
        :timestamp => Time.now.to_i.to_s,  # 微信的坑, 不能用整数
        :jsapi_ticket => ticket,
        :noncestr => nonce_str(),
        :url => url
      }
      pp jsapi_params
      sign = []
      jsapi_params.sort.each { |p|
        sign << p[0].to_s + '=' + p[1].to_s
      }
      pp sign.join('&')

      return {
        debug: true,
        appId: self.id,
        timestamp: jsapi_params[:timestamp],
        nonceStr: jsapi_params[:noncestr],
        signature: Digest::SHA1.hexdigest( sign.join('&') ),
        url: url,
        jsApiList: args
      }
    end


    def prepay_params(code, options)
      # 第一步: 取得openid
      #--------------------
      auth_data = access_token(code)
      pp auth_data
      time_stamp = Time.now.to_i.to_s
      #--------------------
      # 第二步: 下订单,获取prepay_id
      #--------------------
      wx_params = {
        :appid => self.id,
        :body  => 'JSAPIpaytest',
        :mch_id => self.mch_id,
        :nonce_str => nonce_str(), # 随机字符,不超过32位
        :notify_url => options[:redirect_url],
        :out_trade_no =>  time_stamp,
        :openid => auth_data['openid'],
        :spbill_create_ip => options[:ip].to_s,
        :trade_type => 'JSAPI',
        :total_fee =>  (options[:fee] * 100).to_i, # 坑,分为单位,微信的傻逼们不知道怎么处理小数点
      }
      pp wx_params
      # 得到参数签名(sign)
      wx_params[:sign] = sign_digest(wx_params)
      prepay_id, order_des = order(wx_params)

      pp "order: params"
      pp prepay_id
      pp order_des

      #--------------------
      # 第三步: 组织传给前端wx js的 json 数据
      #--------------------
      # 是否成功获得prepay_id
      if prepay_id
        # 参数参考
        # https://pay.weixin.qq.com/wiki/doc/api/jsapi.php?chapter=7_7&index=6
        jsapi_params = {
          :appId => self.id,
          :timeStamp => Time.now.to_i.to_s,  # 微信的坑, 不能用整数
          :nonceStr => nonce_str(),
          :package => "prepay_id=#{prepay_id}",
          :signType => "MD5",
        }
        jsapi_params[:paySign] = sign_digest( jsapi_params )

        pp jsapi_params
        return jsapi_params
      else
        # else
        raise 'error: can not fetch prepay_id'
      end

    end

    private
    ##
    # 发送参数参考
    # https://pay.weixin.qq.com/wiki/doc/api/jsapi.php?chapter=9_1
    # 发送xml, 返回xml, 解析获取 prepay_id, 用于传送给 wx jsapi
    def order(params)
      xml = params.to_xml
      uri = URI( 'https://api.mch.weixin.qq.com/pay/unifiedorder' )
      req = Net::HTTP::Post.new( uri )
      req.body = xml
      req.content_type = 'multipart/form-data'
      res = Net::HTTP.start(uri.hostname, uri.port, :use_ssl => true) {|http|
        http.request(req)
      }
      doc = REXML::Document.new res.body
      if doc.root.elements['prepay_id']
        [doc.root.elements['prepay_id'].text, 'success']
      else
        [nil, doc.root.elements['return_msg'].text]
      end
    end


    # 随机字符,不超过32位
    def nonce_str
      Digest::MD5.hexdigest(Random.new_seed.to_s)
    end

    ##
    # digest hash to sign, reference:
    # https://pay.weixin.qq.com/wiki/doc/api/jsapi.php?chapter=4_3
    def sign_digest(params)
      sign = ''
      params.sort.each { |p|
        sign << p[0].to_s + '=' + p[1].to_s + '&'
      }
      sign << "key=#{self.key}"
      return Digest::MD5.hexdigest(sign).upcase
    end

    def jsapi_access_token
      query = {
        appid: self.id,
        secret: self.secret,
        grant_type: 'client_credential'
      }.to_query
      wx_url = "https://api.weixin.qq.com/cgi-bin/token?#{query}"

      result =open(wx_url) do |resp|
        JSON.parse(resp.read)
      end
      pp result
      return result
    end

    # {
    #   "errcode":0,
    #   "errmsg":"ok",
    #   "ticket":"bxL.........",
    #   "expires_in":7200
    # }
    def jsapi_ticket(token)
      wx_url = "https://api.weixin.qq.com/cgi-bin/ticket/getticket?access_token=#{token}&type=jsapi"

      result = open(wx_url) do |resp|
        JSON.parse(resp.read)
      end
      pp result
      return result['ticket']
    end

    def access_token(code)
      query = {
        appid: self.id,
        secret: self.secret,
        code: code,
        grant_type: 'authorization_code'
      }.to_query
      wx_url = "https://api.weixin.qq.com/sns/oauth2/access_token?#{query}"

      open(wx_url) do |resp|
        JSON.parse(resp.read)
      end
    end
  end
end
