require "wechatruby/version"
require 'openssl'
require 'base64'
require 'json'
require 'open-uri'

module Wechatruby
  CIPHER_TYPE = "AES-128-CBC"
  APP = {
    id: 'appid',
    secret: 'secret'
  }
  # encrypt data
  def self.encrypt(data, key, iv)
    aes = OpenSSL::Cipher::Cipher.new(CIPHER_TYPE)
    aes.encrypt
    aes.key = key
    aes.iv = iv if iv != nil
    aes.update(data) + aes.final
  end

  # decrypt data
  def self.decrypt(encrypted_data, session_key, iv)
    aes_key = Base64.decode64(session_key)
    aes_iv  = Base64.decode64(iv)
    aes_cipher = Base64.decode64(encrypted_data)

    aes = OpenSSL::Cipher::Cipher.new(CIPHER_TYPE)
    aes.decrypt
    aes.key = aes_key
    aes.iv = aes_iv
    JSON.parse(aes.update(aes_cipher) + aes.final)
  end

  def self.session(code)
    wx_url = "https://api.weixin.qq.com/sns/jscode2session?appid=#{APP[:id]}&secret=#{APP[:secret]}&js_code=#{code}&grant_type=authorization_code"

    open(wx_url) do |resp|
      JSON.parse(resp.read)
    end
  end

end
