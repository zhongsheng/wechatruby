# coding: utf-8
require 'rest-client'
require 'pry'
require 'json'

# 素材管理
module Wechatruby
  class Assets
    UPLOAD_URL = "https://api.weixin.qq.com/cgi-bin/media/upload?access_token=%{token}&type=%{type}"
    def initialize(token)
      @token = token
    end

    # 媒体文件在微信后台保存时间为3天，即3天后media_id失效。
    # 图片（image）: 2M，支持PNG\JPEG\JPG\GIF格式
    # 语音（voice）：2M，播放长度不超过60s，支持AMR\MP3格式
    # 视频（video）：10MB，支持MP4格式
    # 缩略图（thumb）：64KB，支持JPG格式
    def tmp_add(type,file_path)
      url = sprintf(UPLOAD_URL, {token: @token, type: type})
      pp url
      resp = RestClient.post( url, :media=> File.new(file_path, 'rb'))
      JSON.parse resp.body
    end

  end
end
