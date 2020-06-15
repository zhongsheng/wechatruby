# frozen_string_literal: true

# lib/cgi.rb

module Wechatruby::Api
  # cgi-bin
  class Cgi
    include Share

    def initialize(token)
      @token = token
      @server_address = 'https://api.weixin.qq.com/cgi-bin/'
    end

    def callback_ip_list
      result = get_data('getcallbackip', {})
      raise result['errmsg'] + result['errcode'].to_s if result['ip_list'].nil?

      result['ip_list']
    end

    # openid 是否订阅
    def subscribed?(openid)
      query = {
        openid: openid,
        lang: 'zh_CN'
      }
      result = get_data('user/info', query)

      result['subscribe'].to_i != 0
    end

    # 长链接转短链接
    # 微信生产的url不被支付宝识别
    def short_url(long_url)
      params = {
        action: 'long2short',
        long_url: long_url
      }
      result = fetch_data('shorturl', params)
      raise result['errmsg'] + result['errcode'].to_s if result['errcode'] != 0

      result['short_url']
    end

    # 获取带场景二维码
    # 获取临时 scene_qrcode('123', {expire_seconds: 999})
    # 永久 scene_qrcode('123', {action_name: 'QR_LIMIT_SCENE'})
    # 返回图片url
    # 参考: https://developers.weixin.qq.com/doc/offiaccount/Account_Management/Generating_a_Parametric_QR_Code.html
    # resp_data['expire_seconds'] # 60秒后过期
    # resp_data['url'] # 二维码的内容是个url, 可以自行生产二维码
    def scene_qrcode(scene_id, options = {})
      params = {
        action_name: 'QR_STR_SCENE',
        action_info: { scene: { scene_str: scene_id } }
      }
      resp_data = fetch_data('qrcode/create', params.merge(options))

      "https://mp.weixin.qq.com/cgi-bin/showqrcode?ticket=#{resp_data['ticket']}"
    end
  end
end
