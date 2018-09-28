require "wechatruby/version"
require 'openssl'
require 'base64'

module Wechatruby
  CIPHER_TYPE = "AES-128-CBC"
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
    aes.update(aes_cipher) + aes.final
  end
end
