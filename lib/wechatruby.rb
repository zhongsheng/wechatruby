# coding: utf-8
require 'openssl'
require 'base64'
require 'digest'

require 'open-uri'
require 'net/http'
require "uri"
require 'active_support/all'

require 'rest-client'
require 'builder'
require "rexml/document"
require 'json'
require "zeitwerk"
loader = Zeitwerk::Loader.for_gem
loader.setup # ready!

module Wechatruby

  class TicketError < StandardError
  end

  CIPHER_TYPE = "AES-128-CBC"

  # APP = {
  #   id: 'appid',
  #   secret: 'api',
  #   mch_id: '商户支付平台id',
  #   key: '商户支付平台设置的api密匙', # https://pay.weixin.qq.com/index.php/core/cert/api_cert
  # }
  # encrypt data
  def self.encrypt(data, key, iv)
    aes = OpenSSL::Cipher.new(CIPHER_TYPE)
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

    aes = OpenSSL::Cipher.new(CIPHER_TYPE)
    aes.decrypt
    aes.key = aes_key
    aes.iv = aes_iv
    JSON.parse(aes.update(aes_cipher) + aes.final)
  end

  # TODO 小程序会话使用
  # def self.session(code)
  #   wx_url = "https://api.weixin.qq.com/sns/jscode2session?appid=#{APP[:id]}&secret=#{APP[:secret]}&js_code=#{code}&grant_type=authorization_code"

  #   open(wx_url) do |resp|
  #     JSON.parse(resp.read)
  #   end
  # end

  class << self

    def app_client
      @app_client ||= Wechatruby::Client.new(Rails.application.credentials.dig(:wechat_web_app))
    end

    def rails_client
      @client ||= Wechatruby::Client.new(Rails.application.credentials.dig(:wechat_mp))
    end

    ##
    # 返回json, 参考
    # https://mp.weixin.qq.com/wiki?t=resource/res_main&id=mp1421140842
    #  { "access_token":"ACCESS_TOKEN",
    #  "expires_in":7200,
    #  "refresh_token":"REFRESH_TOKEN",
    #  "openid":"OPENID",
    #  "scope":"SCOPE" }
    def get_access_token(code)
      wx_url = "https://api.weixin.qq.com/sns/oauth2/access_token?appid=#{APP[:id]}&secret=#{APP[:secret]}&code=#{code}&grant_type=authorization_code"

      open(wx_url) do |resp|
        JSON.parse(resp.read)
      end
    end


  end
end
