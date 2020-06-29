# frozen_string_literal: true

module Wechatruby
  class Client
    include Pay
    include MpApi
    attr_accessor :id, :secret, :mch_id, :key
    @@ip_list = nil
    class << self
      # 缓存access_token
      def token(app_id, params = nil)
        @token ||= {}
        # set params
        if params
          @token[app_id] = params
          @token[app_id]['expired_at'] = Time.now + params['expires_in'] - 1000
          pp @token
          return true
        end
        return nil unless @token[app_id]

        pp 'check token-------------------------'
        pp @token
        if @token[app_id]['expired_at'] > Time.now
          return @token[app_id]['access_token']
        else
          return nil
        end
      end # token ending

      def clear_token
        @token = nil
      end
    end

    def initialize(options)
      @id = options[:id]
      @secret = options[:secret]
      @mch_id = options[:mch_id]
      @key = options[:key]
    end

    def ip_list
      @@ip_list ||= cgi.callback_ip_list
    end

    def cgi
      Api::Cgi.new(jsapi_access_token)
    end

    def shop
      Api::Shop.new(jsapi_access_token)
    end

    def messages
      Messages.new(jsapi_access_token)
    end

    def assets
      Assets.new(jsapi_access_token)
    end

    def menu
      Api::Menu.new(jsapi_access_token)
    end

    # web app 扫码登录
    def qr_code_url(callback_url)
      query = {
        appid: id,
        redirect_uri: callback_url,
        response_type: 'code',
        scope: 'snsapi_login',
        state: 'qr_code'
      }.to_query

      "https://open.weixin.qq.com/connect/qrconnect?#{query}#wechat_redirect"
    end

    # 公众号验证登录
    def code_request_url(callback_url, scope = 'snsapi_userinfo')
      query = {
        appid: id,
        redirect_uri: callback_url,
        response_type: 'code',
        scope: scope,
        state: 'mp_code'
      }.to_query
      "https://open.weixin.qq.com/connect/oauth2/authorize?#{query}#wechat_redirect"
    end

    # 公众号通过openid 获取用户信息
    # 必须是已经关注过公众号的用户
    def get_user_by_id(openid)
      query = {
        access_token: jsapi_access_token,
        openid: openid,
        lang: 'zh_CN'
      }.to_query
      url = "https://api.weixin.qq.com/cgi-bin/user/info?#{query}"
      open(url) do |resp|
        JSON.parse(resp.read)
      end
    end

    # scope : snsapi_base
    # 可直接获取openid
    def get_openid_by_code(code)
      auth_data = access_token(code)
      auth_data['openid']
    end

    # 通过微信的登录验证code来获取用户信息.
    # 用户不必关注公众号
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
      wx_url = "https://api.weixin.qq.com/sns/jscode2session?appid=#{id}&secret=#{secret}&js_code=#{code}&grant_type=authorization_code"

      open(wx_url) do |resp|
        JSON.parse(resp.read)
      end
    end

    private

    # ##
    # # digest hash to sign, reference:
    # # https://pay.weixin.qq.com/wiki/doc/api/jsapi.php?chapter=4_3
    # def sign_digest(params)
    #   sign = ''
    #   params.sort.each { |p|
    #     sign << p[0].to_s + '=' + p[1].to_s + '&'
    #   }
    #   sign << "key=#{self.key}"
    #   return Digest::MD5.hexdigest(sign).upcase
    # end

    # 登录验证token
    # 和公众号小程序的api接口token不同
    def access_token(code)
      query = {
        appid: id,
        secret: secret,
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
