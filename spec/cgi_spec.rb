# mp_spec.rb

RSpec.describe Wechatruby do
  let(:wechat) do
    Wechatruby::Client.new(
      id: ENV.fetch('WX_KEY_1'),
      secret: ENV.fetch('WX_SECRET_1')
    )
  end

  it 'can get callback ip list' do
    result = wechat.cgi.callback_ip_list
    expect(result).not_to be nil
  end

  it 'long url to short' do
    url = 'http://www.baidu.com'
    short_url = wechat.cgi.short_url(url)
    pp short_url
    expect(short_url).not_to be nil
  end

  it 'subscribed' do
    result = wechat.cgi.subscribed?("oY98t6BQs0wbmSgcpn2lseEV9N4k")
    pp result
    expect(result).not_to be nil
  end

  it 'can get temp qrcode' do
    result = wechat.cgi.scene_qrcode('12sdj_asldfji_saldf_jisd3456789', expire_seconds: 9999)
    pp result
    expect(result).not_to be nil
  end
end
