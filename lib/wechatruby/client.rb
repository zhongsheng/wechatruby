module Wechatruby
  class Client
    attr_accessor :id, :secret, :mch_id, :key
    def initialize(options)
      @id = options[:id]
      @secret = options[:secret]
      @mch_id = options[:mch_id]
      @key = options[:key]
    end

    def code_request_url(callback_url, scope='snsapi_userinfo')
      query = {
        appid: self.id,
        redirect_uri: callback_url,
        response_type: 'code',
        scope: scope,
        state: 'wechatruby',
      }.to_query
      return "https://open.weixin.qq.com/connect/oauth2/authorize?#{query}#wechat_redirect"
    end

    def get_user_info(code)
      auth_data = access_token(code)
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

    private
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
