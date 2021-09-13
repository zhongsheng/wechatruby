# frozen_string_literal: true

# 素材管理
class Wechatruby::Client::Messages
  SEND_URL = 'https://api.weixin.qq.com/cgi-bin/message/custom/send?access_token=%{token}'
  TEMPLATE_URL = 'https://api.weixin.qq.com/cgi-bin/message/template/send?access_token=%{token}'
  PREVIEW_MASS_URL = 'https://api.weixin.qq.com/cgi-bin/message/mass/preview?access_token=%{token}'
  MASS_URL = 'https://api.weixin.qq.com/cgi-bin/message/mass/send?access_token=%{token}'
  def initialize(token)
    @token = token
  end

  def send_text(user_id, text)
    url = format(SEND_URL, token: @token)
    params = {
      touser: user_id,
      msgtype: 'text',
      text: {
        content: text
      }
    }
    http_post(url, params)
  end

  # 发送图片给客户
  # {"errcode"=>0, "errmsg"=>"ok"}
  #
  def send_image(user_id, media_id)
    url = format(SEND_URL, token: @token)
    params = {
      touser: user_id,
      msgtype: 'image',
      image: {
        media_id: media_id
      }
    }
    http_post(url, params)
  end

  def send_template(params)
    url = format(TEMPLATE_URL, token: @token)
    http_post(url, params)
  end

  def preview_text_to_mass(account, content)
    url = format(PREVIEW_MASS_URL, token: @token)
    params = {
      towxname: account,
      text: { "content": content },
      msgtype: 'text'
    }
    http_post(url, params)
  end

  def text_to_mass(openids, content)
    url = format(MASS_URL, token: @token)
    params = {
      tousr: openids,
      text: { "content": content },
      msgtype: 'text'
    }
    http_post(url, params)
  end

  def images_to_mass(openids, media_ids)
    url = format(MASS_URL, token: @token)
    params = {
      tousr: openids,
      images: {media_ids: media_ids},
      msgtype: 'image'
    }
    http_post(url, params)
  end

  private

  def http_post(url, params)
    resp = RestClient.post(url, params.to_json, content_type: :json, accept: :json)
    JSON.parse resp.body
  end
end
