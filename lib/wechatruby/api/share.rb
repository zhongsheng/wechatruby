# frozen_string_literal: true


module Wechatruby::Api
  # Share
  module Share
    private

    def get_data(action, params)
      url = [
        @server_address,
        action,
        "?access_token=#{@token}&#{params.to_query}"
      ].join

      resp = RestClient.get(url, accept: :json)
      pp resp
      JSON.parse resp.body
    end

    def fetch_data(action, params)
      url = [
        @server_address,
        action,
        "?access_token=#{@token}"
      ].join

      resp = RestClient.post(url, params.to_json, content_type: :json, accept: :json)
      JSON.parse resp.body
    end
  end
end
