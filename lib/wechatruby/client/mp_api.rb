# frozen_string_literal: true

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

  # 长链接转短链接
  # 微信生产的url不被支付宝识别
  def get_short_url(long_url)
    params = {
      action: 'long2short',
      long_url: long_url
    }
    fetch_data('shorturl', params)['short_url']
  end

  # 获取带场景二维码
  # 获取临时 scene_qrcode('123', {expire_seconds: 999})
  # 永久 scene_qrcode('123', {action_name: 'QR_LIMIT_SCENE'})
  # 返回图片url
  # 参考: https://developers.weixin.qq.com/doc/offiaccount/Account_Management/Generating_a_Parametric_QR_Code.html
  def scene_qrcode(scene_id, options = nil)
    params = {
      action_name: 'QR_STR_SCENE',
      action_info: { scene: { scene_str: scene_id } }
    }
    params.merge(options) unless options.nil?
    resp_data = fetch_data('qrcode/create', params)
    # resp_data['expire_seconds'] # 60秒后过期
    # resp_data['url'] # 二维码的内容是个url, 可以自行生产二维码

    "https://mp.weixin.qq.com/cgi-bin/showqrcode?ticket=#{resp_data['ticket']}"
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
      pp '######### debug:: Use cached token.'
      return ::Wechatruby::Client.token(id)
    end
    query = {
      appid: id,
      secret: secret,
      grant_type: 'client_credential'
    }.to_query
    wx_url = "https://api.weixin.qq.com/cgi-bin/token?#{query}"

    result = open(wx_url) do |resp|
      JSON.parse(resp.read)
    end
    pp 'Got access token from wechat server'
    pp result
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

    result = open(wx_url) do |resp|
      JSON.parse(resp.read)
    end
    raise Wechatruby::TicketError, result['errmsg'] if result['errcode'] != 0

    pp result
    result['ticket']
  end

  private

  def fetch_data(action, params)
    server_address = 'https://api.weixin.qq.com/cgi-bin/'
    url = "#{server_address}#{action}?access_token=#{jsapi_access_token}"

    resp = RestClient.post(url, params.to_json, content_type: :json, accept: :json)
    JSON.parse resp.body
  end
end
