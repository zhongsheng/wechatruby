require "base64"
require "pp"
RSpec.describe Wechatruby do
  it "has a version number" do
    expect(Wechatruby::VERSION).not_to be nil
  end

  it "encrypt and decrypt" do
    data = '[1,2,4]'
    iv = "a\x03$Q]\x99\xA9\xFB\x80\xD0\xD3\xEB\x11P\xD8\xD6"
    session_key = "\x9EC\xEC\xF4\xBE\xC3\xD7\x1E\x81\x80\xFAZ\x8A\xBC\xED\x90"

    encrypted_data = Base64.encode64(Wechatruby.encrypt(data, session_key, iv))
    iv = Base64.encode64(iv)
    session_key = Base64.encode64(session_key)

    expect( Wechatruby.decrypt(encrypted_data, session_key, iv) ).to eq(JSON.parse(data))
  end

  it "get session" do
    expect(Wechatruby.session("123")["errcode"]).to eq(40013)
  end

end
