# frozen_string_literal: true

module Wechatruby::Api
  # 自定义菜单
  class Menu
    def initialize(token)
      @token = token
    end

    def create(params)
      url = "https://api.weixin.qq.com/cgi-bin/menu/create?access_token=#{@token}"
      resp = RestClient.post(url, params.to_json, content_type: :json, accept: :json)
      JSON.parse resp.body
    end
  end
end
