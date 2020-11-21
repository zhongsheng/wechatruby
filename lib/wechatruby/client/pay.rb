# frozen_string_literal: true

module Wechatruby::Client::Pay
  # 支付模块

  def red_pack_to(openid, options)
    time_stamp = Time.now.to_i.to_s
    wx_params = {
      nonce_str: nonce_str, # 随机字符,不超过32位
      mch_billno: time_stamp,
      mch_id: @mch_id,
      wxappid: @id,
      re_openid: openid,
      # send_name: 'Lefin',
      # total_amount: 100,
      # total_num: 1,
      # wishing: 'Thanks',
      # client_ip: nil,
      # act_name: 'Lefin Milk Reward',
      # remark: 'Good'
    }.merge(options)
    wx_params[:sign] = sign_digest(wx_params)
    post_with_cert(wx_params)
  end

  # options: {:redirect_url :ip :fee }
  # openid
  def prepay_params(openid, options)
    # 第一步: 取得openid
    #--------------------
    time_stamp = Time.now.to_i.to_s
    #--------------------
    # 第二步: 下订单,获取prepay_id
    #--------------------
    wx_params = {
      appid: @id,
      body: (options[:body] || 'wechatruby'),
      mch_id: @mch_id,
      nonce_str: nonce_str, # 随机字符,不超过32位
      notify_url: options[:redirect_url],
      out_trade_no: time_stamp,
      openid: openid,
      spbill_create_ip: options[:ip].to_s,
      trade_type: 'JSAPI',
      total_fee: (options[:fee] * 100).to_i # 坑,分为单位,微信的傻逼们不知道怎么处理小数点
    }
    # 得到参数签名(sign)
    wx_params[:sign] = sign_digest(wx_params)
    prepay_id, order_des = order(wx_params)


    #--------------------
    # 第三步: 组织传给前端wx js的 json 数据
    #--------------------
    # 是否成功获得prepay_id
    if prepay_id
      # 参数参考
      # https://pay.weixin.qq.com/wiki/doc/api/jsapi.php?chapter=7_7&index=6
      jsapi_params = {
        appId: id,
        timeStamp: Time.now.to_i.to_s, # 微信的坑, 不能用整数
        nonceStr: nonce_str,
        package: "prepay_id=#{prepay_id}",
        signType: 'MD5'
      }
      jsapi_params[:paySign] = sign_digest(jsapi_params)

      pp jsapi_params
      return jsapi_params
    else
      raise 'error: can not fetch prepay_id'
    end
  end

  private

  ##
  # digest hash to sign, reference:
  # https://pay.weixin.qq.com/wiki/doc/api/jsapi.php?chapter=4_3
  def sign_digest(params)
    sign = []
    params.sort.each do |p|
      sign << p[0].to_s + '=' + p[1].to_s + '&'
    end
    sign << "key=#{@key}"
    Digest::MD5.hexdigest(sign.join).upcase
  end

  # TODO remove eval
  def to_xml(params)
    x_builder = Builder::XmlMarkup.new
    xml = x_builder.xml do |x|
      params.each do |p|
        eval("x.#{p[0].to_s} '#{p[1]}'")
      end
    end
    xml
  end

  ##
  # 发送参数参考
  # https://pay.weixin.qq.com/wiki/doc/api/jsapi.php?chapter=9_1
  # 发送xml, 返回xml, 解析获取 prepay_id, 用于传送给 wx jsapi
  def order(params)
    xml = to_xml(params)
    uri = URI('https://api.mch.weixin.qq.com/pay/unifiedorder')
    req = Net::HTTP::Post.new(uri)
    req.body = xml
    req.content_type = 'multipart/form-data'
    res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(req)
    end
    doc = REXML::Document.new res.body
    if doc.root.elements['prepay_id']
      [doc.root.elements['prepay_id'].text, 'success']
    else
      [nil, doc.root.elements['return_msg'].text]
    end
  end

  # https://pay.weixin.qq.com/wiki/doc/api/tools/cash_coupon.php?chapter=13_4&index=3
  def post_with_cert(params)
    xml = to_xml(params)
    url = 'https://api.mch.weixin.qq.com/mmpaymkttransfers/sendredpack'
    res = RestClient::Resource.new(
      url,
      :ssl_client_cert  =>  OpenSSL::X509::Certificate.new(@cert_pem),
      :ssl_client_key   =>  OpenSSL::PKey::RSA.new(@private_key),
      :verify_ssl       =>  OpenSSL::SSL::VERIFY_PEER
    ).post(xml)
    res.body
  end

  # 随机字符,不超过32位
  def nonce_str
    Digest::MD5.hexdigest(Random.new_seed.to_s)
  end
end
