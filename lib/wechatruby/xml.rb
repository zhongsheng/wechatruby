# frozen_string_literal: true

require 'nokogiri'

module Wechatruby
  class Xml
    def self.parse(xml)
      new(Nokogiri::XML(xml))
    end

    attr_reader :openid, :event
    def initialize(doc)
      @noko = doc
      @openid = get_value 'FromUserName'
      type = get_value 'MsgType'
      @event = get_value('Event') if type == 'event'
    end

    def get_value(param)
      @noko.css(param).text
    end

    # def method_missing(name, *args)
    # end

    # def respond_to_missing?(method_name, include_private = false)
    # end
  end
end
