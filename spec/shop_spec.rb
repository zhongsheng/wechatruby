# frozen_string_literal: true

RSpec.describe Wechatruby do
  let(:wechat) do
    Wechatruby::Client.new(
      id: ENV.fetch('WX_KEY_1'),
      secret: ENV.fetch('WX_SECRET_1')
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

  it 'can close order' do
    result = wechat.shop.close_order '12944202038177310886'
    pp result
    expect( result['errcode'] ).to be 0
  end
end
