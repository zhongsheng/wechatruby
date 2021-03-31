# frozen_string_literal: true

module Wechatruby::Client::MpApi
  # 公众号号api

  # js sdk config
  #
  def web_jsapi_params(url, debug, *args)
    token = jsapi_access_token
    pp token
    begin
      ticket = jsapi_ticket(token)
    rescue Wechatruby::TicketError
      # 清空token缓存,重新尝试
      ::Wechatruby::Client.clear_token
      token = jsapi_access_token
      ticket = jsapi_ticket(token)
    end

    jsapi_params = {
      # :appId => self.id,
      timestamp: Time.now.to_i.to_s, # 微信的坑, 不能用整数
      jsapi_ticket: ticket,
      noncestr: nonce_str,
      url: url
    }
    pp jsapi_params
    sign = []
    jsapi_params.sort.each do |p|
      sign << p[0].to_s + '=' + p[1].to_s
    end
    pp sign.join('&')

    {
      debug: debug,
      appId: id,
      timestamp: jsapi_params[:timestamp],
      nonceStr: jsapi_params[:noncestr],
      signature: Digest::SHA1.hexdigest(sign.join('&')),
      url: url,
      jsApiList: args
    }
  end

  # api 接口token, 需要进行缓存
  # 正常返回: {"access_token":"ACCESS_TOKEN","expires_in":7200}
  # 说明文档 https://developers.weixin.qq.com/doc/offiaccount/Basic_Information/Get_access_token.html
  def jsapi_access_token
    if ::Wechatruby::Client.token(id)
      return ::Wechatruby::Client.token(id)
    end
    query = {
      appid: id,
      secret: secret,
      grant_type: 'client_credential'
    }.to_query
    wx_url = "https://api.weixin.qq.com/cgi-bin/token?#{query}"
    resp = RestClient.get(wx_url, accept: :json)
    result = JSON.parse resp.body

    raise 'Cant get access_token' unless result['access_token']

    ::Wechatruby::Client.token(id, result)
    ::Wechatruby::Client.token(id)
  end

  # {
  #   "errcode":0,
  #   "errmsg":"ok",
  #   "ticket":"bxL.........",
  #   "expires_in":7200
  # }
  def jsapi_ticket(token)
    wx_url = "https://api.weixin.qq.com/cgi-bin/ticket/getticket?access_token=#{token}&type=jsapi"
    resp = RestClient.get(wx_url, accept: :json)
    result = JSON.parse resp.body
    raise Wechatruby::TicketError, result['errmsg'] if result['errcode'] != 0

    result['ticket']
  end

  private

  def fetch_data(action, params)
    server_address = 'https://api.weixin.qq.com/cgi-bin/'
    url = "#{server_address}#{action}?access_token=#{jsapi_access_token}"
    pp params

    resp = RestClient.post(url, params.to_json, content_type: :json, accept: :json)
    JSON.parse resp.body
  end
end
