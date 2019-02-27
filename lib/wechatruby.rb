# coding: utf-8
require "wechatruby/version"
require 'openssl'
require 'base64'
require 'digest'

require 'open-uri'
require 'net/http'
require "uri"

require 'builder'
require "rexml/document"
require 'json'

module Wechatruby
  CIPHER_TYPE = "AES-128-CBC"
  APP = {
    id: '公众号appid',
    secret: '公众号api密匙',
    mch_id: '商户支付平台id',
    key: '商户支付平台设置的api密匙', # https://pay.weixin.qq.com/index.php/core/cert/api_cert
  }
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

  def self.session(code)
    wx_url = "https://api.weixin.qq.com/sns/jscode2session?appid=#{APP[:id]}&secret=#{APP[:secret]}&js_code=#{code}&grant_type=authorization_code"

    open(wx_url) do |resp|
      JSON.parse(resp.read)
    end
  end

  class << self
    # 随机字符,不超过32位
    def nonce_str
      Digest::MD5.hexdigest(Random.new_seed.to_s)
    end

    ##
    # digest hash to sign, reference:
    # https://pay.weixin.qq.com/wiki/doc/api/jsapi.php?chapter=4_3
    def sign_digest(params)
      sign = ''
      params.sort.each { |p|
        sign << p[0].to_s + '=' + p[1].to_s + '&'
      }
      sign << "key=#{APP[:key]}"
      return Digest::MD5.hexdigest(sign).upcase
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

    def get_user_info(code)
      auth_data = get_access_token(code)
      url = 'https://api.weixin.qq.com/sns/userinfo?access_token='
      url += auth_data["access_token"]
      url += "&openid=#{auth_data['openid']}"
      url += '&lang=zh_CN'
      open(url) do |resp|
        JSON.parse(resp.read)
      end
    end

    def code_redirect_url(url, scope='snsapi_userinfo')
      {
        appid: APP[:id]
        redirect_uri: url,
        response_type: 'code',
        scope: scope,
        state: 'wechatruby',
      }.to_query
    end

    ##
    # 发送参数参考
    # https://pay.weixin.qq.com/wiki/doc/api/jsapi.php?chapter=9_1
    # 发送xml, 返回xml, 解析获取 prepay_id, 用于传送给 wx jsapi
    def order(params)
      xml = params.to_xml
      uri = URI( 'https://api.mch.weixin.qq.com/pay/unifiedorder' )
      req = Net::HTTP::Post.new( uri )
      req.body = xml
      req.content_type = 'multipart/form-data'
      res = Net::HTTP.start(uri.hostname, uri.port, :use_ssl => true) {|http|
        http.request(req)
      }
      doc = REXML::Document.new res.body
      if doc.root.elements['prepay_id']
        [doc.root.elements['prepay_id'].text, 'success']
      else
        [nil, doc.root.elements['return_msg'].text]
      end
    end

  end
end

##
# A simple monkey patch to Hash class
#  {key: 'value'}.to_xml
#  #=> <xml><key>value</key></xml>
class Hash
  def to_xml
    params = self
    x_builder = Builder::XmlMarkup.new
    xml = x_builder.xml { |x|
      params.each { |p|
        eval("x.#{p[0].to_s} '#{p[1]}'")
      }
    }
    return xml
  end
end
