# frozen_string_literal: true

module Wechatruby::Api
  # 微信小店
  class Shop
    STATUS = { paid: 2, shipping: 3, finish: 5, trouble: 8 }.freeze
    SERVER_ADDRESS = 'https://api.weixin.qq.com/merchant/'

    def initialize(token)
      @token = token
    end

    # Get orders
    def orders(begin_time, end_time, status)
      fetch_data('order/getbyfilter',
                 status: STATUS[status],
                 begintime: begin_time.to_i,
                 endtime: end_time.to_i)
    end

    # close
    def close_order(order_id)
      fetch_data('order/close', order_id: order_id)
    end

    private

    def fetch_data(action, params)
      url = [
        SERVER_ADDRESS,
        action,
        "?access_token=#{@token}"
      ].join

      resp = RestClient.post(url, params.to_json, content_type: :json, accept: :json)
      JSON.parse resp.body
    end
  end
end
