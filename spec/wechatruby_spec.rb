require "base64"
require "pp"
RSpec.describe Wechatruby do
  it "has a version number" do
    expect(Wechatruby::VERSION).not_to be nil
  end

  it "encrypt and decrypt" do
    data = "the messages need to encrypt"
    iv = 'p2V6Xab2rS3cltGLhU6auA=='
    session_key = 'AvCwYZDUREcAvnBbSXGTUg=='

    encrypted_data = Base64.encode64(Wechatruby.encrypt(data, session_key, iv))
    iv = Base64.encode64('p2V6Xab2rS3cltGLhU6auA==')
    session_key = Base64.encode64('AvCwYZDUREcAvnBbSXGTUg==')


    expect( Wechatruby.decrypt(encrypted_data, session_key, iv) ).to eq(data)
  end
end
