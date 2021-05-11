# frozen_string_literal: true

module Wechatruby
  # 微信支付api V3
  class Pay3
    V3_PATH = 'https://api.mch.weixin.qq.com/v3'
    def initialize(client)
      @client = client
    end

    def prepay_id(order_id:, desc:, notify_url:, total:, openid:)
      url = V3_PATH + '/pay/transactions/jsapi'

      params = {
        appid: @client.id,
        mchid: @client.mch_id,
        out_trade_no: order_id,
        description: desc,
        notify_url: notify_url,
        amount: { total: (total.to_f * 100).to_i, currency: 'CNY' },
        payer: { openid: openid }
      }.to_json
      refresh_nonce
      res = post url, params
      res['prepay_id']
    end

    def mini_params(pay_id)
      refresh_nonce
      payload = {
        timeStamp: @timestamp.to_s,
        nonceStr: @nonce,
        package: "prepay_id=#{pay_id}",
        signType: 'RSA'
      }
      payload['paySign'] = pay_sign(payload)
      pp payload
      payload
    end

    # 发放代金券
    #  options = {
    #  stock_id: '代金券批次号', # 必填
    #  out_request_no: '商户单据号', # 必填
    #  coupon_value: '指定面额发券，面额',
    #  coupon_minimum: '指定面额发券，券门槛'
    #  }
    #
    def deliver_coupon_to(openid, options = {})
      url = "#{V3_PATH}/marketing/favor/users/#{openid}/coupons"
      refresh_nonce
      params = {
        out_request_no: SecureRandom.uuid,
        appid: @client.id,
        stock_creator_mchid: @client.mch_id
      }.merge(options)
      post url, params.to_json
    end

    def user_coupon_info(openid)
      url = [
        V3_PATH,
        "/marketing/favor/users/#{openid}/coupons",
        "?available_mchid=#{@client.mch_id}&",
        "appid=#{@client.id}"
      ].join
      refresh_nonce
      query url
    end

    # 查询指定批次的代金券
    # https://pay.weixin.qq.com/wiki/doc/apiv3/wxpay/marketing/convention/chapter3_5.shtml
    def coupon_info_at(stock_id)
      url = "#{V3_PATH}/marketing/favor/stocks/#{stock_id}?stock_creator_mchid=#{@client.mch_id}"
      refresh_nonce
      query url
    end

    private

    def pay_sign(payload)
      str = [
        @client.id,
        payload[:timeStamp],
        payload[:nonceStr],
        payload[:package] + "\n"
      ].join("\n")
      pp str
      encrypt str
    end

    def refresh_nonce
      @timestamp = Time.now.to_i
      @nonce = Digest::MD5.hexdigest(@timestamp.to_s).upcase
    end

    def post(url, payload)
      encrypted_data = encrypt sign_str(:post, url, payload)
      res = RestClient.post(url, payload,
                            {
                              content_type: :json, accept: :json,
                              'Authorization' => auth_header(encrypted_data)
                            })
      JSON.parse res.body
    rescue RestClient::ExceptionWithResponse => e
      pp e.response
      JSON.parse e.response.body
    end

    # 构造签名串
    def sign_str(method, uri, body = '')
      method = method.to_s.upcase
      uri = URI(uri)
      uri_ary = [uri.path]
      uri_ary << "?#{uri.query}" if uri.query
      [
        method, uri_ary.join, @timestamp.to_s, @nonce, body + "\n"
      ].join("\n")
    end

    # 加密构造签名串
    def encrypt(str)
      key = OpenSSL::PKey::RSA.new @client.private_key
      digest = OpenSSL::Digest.new('SHA256')
      Base64.strict_encode64(key.sign(digest, str))
    end

    # 设置HTTP头
    # Authorization: 认证类型 签名信息
    def auth_header(signature)
      schema = ' WECHATPAY2-SHA256-RSA2048 '
      token = format(
        'mchid="%s",nonce_str="%s",timestamp="%d",serial_no="%s",signature="%s"',
        @client.mch_id, @nonce, @timestamp, @client.cert_no, signature
      )
      schema + token
    end

    def query(url)
      encrypted_data = encrypt sign_str(:get, url)
      res = RestClient.get(
        url,
        accept: :json,
        'Authorization' => auth_header(encrypted_data)
      )
      JSON.parse res.body
    rescue RestClient::ExceptionWithResponse => e
      pp e.response
      JSON.parse e.response.body
    end
  end
end
