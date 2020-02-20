# frozen_string_literal: true

RSpec.describe Wechatruby do
  let(:wechat) do
    Wechatruby::Client.new(
      id: 'wxc0ce78295911428d',
      secret: '898f2e2a189e96fb9ebe7c42e325f663'
    )
  end
  it 'can get shop' do
    shop = wechat.shop
    expect(shop).not_to be nil
    # expect(Wechatruby::Client.token(wechat.id, params ) ).to be false
  end

  it 'can get orders' do
    begin_time = Time.now.to_i
    end_time = begin_time - 24*3600
    orders = wechat.shop.orders(end_time, begin_time, :paid)
    pp orders
    expect( orders['errcode'] ).to be 0
  end
end
