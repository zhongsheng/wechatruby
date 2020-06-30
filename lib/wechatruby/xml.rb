# frozen_string_literal: true

require 'nokogiri'

module Wechatruby
  # Handle wechat server request xml
  class Xml
    def self.parse(xml)
      new(Nokogiri::XML(xml))
    end

    # 支付成功返回的xml
    def self.pay_success
      _xml = <<~XML
        <xml>
              <return_code><![CDATA[SUCCESS]]></return_code>
              <return_msg><![CDATA[OK]]></return_msg>
        </xml>
      XML
    end

    attr_reader :openid, :event
    def initialize(doc)
      @noko = doc
      @openid = get_value 'FromUserName'
      type = get_value 'MsgType'
      @event = type == 'event' ? get_value('Event') : type
    end

    def get_value(param)
      @noko.css(param).text
    end

    # 转发用户信息给客服处理
    def reward_to_customer_service
      _xml = <<~RES
         <xml>
         <ToUserName><![CDATA[#{openid}]]></ToUserName>
         <FromUserName><![CDATA[#{get_value('ToUserName')}]]></FromUserName>
          <CreateTime>#{Time.now.to_i}</CreateTime>
          <MsgType><![CDATA[transfer_customer_service]]></MsgType>
        </xml>
      RES
    end

    # def method_missing(name, *args)
    # end

    # def respond_to_missing?(method_name, include_private = false)
    # end
  end
end
