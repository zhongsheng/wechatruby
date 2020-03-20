# mp_spec.rb


RSpec.describe Wechatruby do
  let(:wechat) do
    Wechatruby::Client.new(
      id: ENV.fetch('WX_KEY_3'),
      secret: ENV.fetch('WX_SECRET_3')
    )
  end
  it 'long url to short' do
    url = 'http://www.baidu.com'
    short_url = wechat.cgi.short_url(url)
    pp short_url
    expect(short_url).not_to be nil
  end

  it 'subscribed' do
    result = wechat.cgi.subscribed?("osip61TslXFOq134R4pc2tI9qQrk")
    pp result
    expect(result).not_to be nil
  end

  it 'can get temp qrcode' do
    result = wechat.cgi.scene_qrcode('12sdj_asldfji_saldf_jisd3456789', expire_seconds: 9999)
    pp result
    expect(result).not_to be nil
  end
end
