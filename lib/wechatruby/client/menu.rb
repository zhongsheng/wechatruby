# frozen_string_literal: true

# 自定义菜单
class Wechatruby::Client::Menu
  MENU_URL = 'https://api.weixin.qq.com/cgi-bin/menu/create?access_token=%{token}'
  def initialize(token)
    @token = token
  end

  def create(params)
    url = format(MENU_URL, token: @token)
    pp url
    params = params.to_json
    resp = RestClient.post(url, params, content_type: :json, accept: :json)
    JSON.parse resp.body
  end
end
