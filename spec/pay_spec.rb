# pay_spec.rb

# mp_spec.rb

RSpec.describe Wechatruby do
  let(:client) do
        Wechatruby::Client.new(
      id: ENV.fetch('WX_KEY_1'),
      secret: ENV.fetch('WX_SECRET_1'),
      mch_id: ENV.fetch('WX_mch_id_1'),
      key: ENV.fetch('WX_key_1'),
      cert_no: ENV.fetch('WX_cert_no_1'),
      cert_pem: File.read( ENV.fetch('WX_cert_pem_1')),
      private_key: File.read(ENV.fetch('WX_private_key_1')),
      v3_key: ENV.fetch('WX_v3_key_1')
    )

  end

  let(:openid) do
    'oLAujs8Ll_vjCpFfnBkRITqiBOhc'
  end

  let(:wxpay) do
    client.pay3
  end

  it 'can send money to me' do
    client.pension_to(openid, {ip: '106.15.187.220'})
  end

  # it 'have api v3 key' do
  #   expect(wxpay).not_to be nil
  # end

  # it 'have signed string' do
  #   uri = URI('https://api.mch.weixin.qq.com/v3/certificates?hi=1')
  #   v = wxpay.sign_str(:get, uri)
  #   puts v
  #   expect(v).not_to be nil
  # end

  # it 'encrypt' do
  #   str = 'Tj9ex4DZg26it6lfBppTeNOrNM2tj2X1Pdvhavx2veSLDxE9y7geMAmyPeSUKkm8saFmgXS7oj0t6mPW+Op18Szl0ztF/1W/tly38YxMvaSL9Isvc+RHAqZG0HPNQ76GyQhgOFCbyy9myR8NtXlU/AS0UsoOijtDR/29Q4odPNeWWe7SQ+kRTR9TmjbREo2uiRyCg1P+HO8x3sLTcwE9OnB/hM0c+V6BlkRqpUOQqqj2faY61NCyih3htAXSxTeYeAodZ3yFYwI6/akNnT5ArJqOeu7c86nc0c+oLPPbWEAevukGMsUYpk9RHV4Quo27yVe9JLY8hK0Utm6fIELoHg=='
  #   v = wxpay.encrypt('GET')
  #   expect(v).not_to be('')
  #   expect(v).to eq(str)
  # end
  it 'can send coupon to user' do
    v = wxpay.deliver_coupon_to("oLAujs8Ll_vjCpFfnBkRITqiBOhc", {
                                  stock_id: '15226825'
                                })
    pp v
    expect(v).not_to be('')
  end

  it 'can get user coupons' do
    v = wxpay.user_coupon_info("oLAujs8Ll_vjCpFfnBkRITqiBOhc")
    pp v

    expect(v).not_to be('')
  end

  it 'can get coupon information ' do
    v = wxpay.coupon_info_at('15226825')
    pp v
    expect(v).not_to be('')
  end

end
