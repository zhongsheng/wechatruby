# coding: utf-8
module Wechatruby::Client::MpApi
  # 公众号号api

  # openid 是否订阅
  def subscribed?(openid)
    query = {
      access_token: jsapi_access_token,
      openid: openid,
      lang: 'zh_CN'
    }.to_query
    url = "https://api.weixin.qq.com/cgi-bin/user/info?#{query}"
    data = open(url) do |resp|
      JSON.parse(resp.read)
    end
    pp data

    data['subscribe'].to_i != 0
  end

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
      debug: debug,
      appId: self.id,
      timestamp: jsapi_params[:timestamp],
      nonceStr: jsapi_params[:noncestr],
      signature: Digest::SHA1.hexdigest( sign.join('&') ),
      url: url,
      jsApiList: args
    }
  end

  # api 接口token, 需要进行缓存
  # 正常返回: {"access_token":"ACCESS_TOKEN","expires_in":7200}
  # 说明文档 https://developers.weixin.qq.com/doc/offiaccount/Basic_Information/Get_access_token.html
  def jsapi_access_token
    if ::Wechatruby::Client.token(self.id)
      pp '######### debug:: Use cached token.'
      return ::Wechatruby::Client.token(self.id)
    end
    query = {
      appid: self.id,
      secret: self.secret,
      grant_type: 'client_credential'
    }.to_query
    wx_url = "https://api.weixin.qq.com/cgi-bin/token?#{query}"

    result =open(wx_url) do |resp|
      JSON.parse(resp.read)
    end
    pp 'Got access token from wechat server'
    pp result
    unless result['access_token']
      raise 'Cant get access_token'
    end
    ::Wechatruby::Client.token(self.id, result)
    return ::Wechatruby::Client.token(self.id)
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
    if result['errcode'] != 0
      raise Wechatruby::TicketError, result['errmsg']
    end
    pp result
    return result['ticket']
  end


end
