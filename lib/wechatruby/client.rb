# frozen_string_literal: true

module Wechatruby
  class Client
    include Pay
    include MpApi
    attr_accessor :id, :secret, :mch_id, :key, :cert_no, :cert_pem, :private_key, :v3_key

    @@ip_list = nil

    TOKEN_FILE = '/tmp/wechat_token'
    class << self
      def cache_token(token)
        File.write(TOKEN_FILE, token.to_json)
      end

      def read_token
        return nil unless File.exist?(Wechatruby::Client::TOKEN_FILE)

        JSON.parse File.read(Wechatruby::Client::TOKEN_FILE)
      end

      # 缓存access_token
      def token(app_id, params = nil)
        @token ||= {}
        # set params
        if params
          @token[app_id] = params
          @token[app_id]['expired_at'] = Time.now + params['expires_in'] - 600
          cache_token @token
          return true
        end
        return nil unless @token[app_id]

        @token[app_id]['access_token'] if @token[app_id]['expired_at'] > Time.now
      end

      def clear_token
        @token = nil
      end
    end

    def initialize(options)
      @id = options[:id]
      @secret = options[:secret]
      @mch_id = options[:mch_id]
      @key = options[:key]
      @cert_no = options[:cert_no]
      @cert_pem = options[:cert_pem]
      @private_key = options[:private_key]
      @v3_key = options[:v3_key]
    end

    def ip_list
      @@ip_list ||= cgi.callback_ip_list
    end

    def pay3
      Pay3.new(self)
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
      resp = RestClient.get(url, accept: :json)
      JSON.parse resp.body
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
      resp = RestClient.get(url, accept: :json)
      JSON.parse resp.body
    end

    # 用于小程序端获取openid
    def get_session_by(code)
      wx_url = "https://api.weixin.qq.com/sns/jscode2session?appid=#{id}&secret=#{secret}&js_code=#{code}&grant_type=authorization_code"
      resp = RestClient.get(url, accept: :json)
      JSON.parse resp.body
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
      url = "https://api.weixin.qq.com/sns/oauth2/access_token?#{query}"
      resp = RestClient.get(url, accept: :json)
      JSON.parse resp.body
    end
    @token = read_token
  end
end
