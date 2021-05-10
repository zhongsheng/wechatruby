# frozen_string_literal: true

require 'openssl'
require 'base64'
require 'digest'
require 'securerandom'

require 'net/http'
require 'uri'
require 'active_support/all'

require 'rest-client'
require 'builder'
require 'rexml/document'
require 'json'
require 'zeitwerk'
loader = Zeitwerk::Loader.for_gem
loader.setup # ready!

# 微信公众平台API
module Wechatruby
  class TicketError < StandardError
  end

  CIPHER_TYPE = 'AES-128-CBC'
  # encrypt data
  def self.encrypt(data, key, iv)
    aes = OpenSSL::Cipher.new(CIPHER_TYPE)
    aes.encrypt
    aes.key = key
    aes.iv = iv unless iv.nil?
    aes.update(data) + aes.final
  end

  # decrypt data
  def self.decrypt(encrypted_data, session_key, iv)
    aes_key = Base64.decode64(session_key)
    aes_iv  = Base64.decode64(iv)
    aes_cipher = Base64.decode64(encrypted_data)

    aes = OpenSSL::Cipher.new(CIPHER_TYPE)
    aes.decrypt
    aes.key = aes_key
    aes.iv = aes_iv
    JSON.parse(aes.update(aes_cipher) + aes.final)
  end

end
