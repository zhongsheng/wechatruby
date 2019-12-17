# coding: utf-8

RSpec.describe Wechatruby do
  let(:wechat) {
    Wechatruby::Client.new({
                             id: 'wx802a93ee50c6477a',
                             secret: '9f3c51e0faaaf95310107078f6b7c59e'
                           })
  }
  it "can get token" do
    params = wechat.jsapi_access_token
    expect(wechat.jsapi_access_token).not_to be nil
    # expect(Wechatruby::Client.token(wechat.id, params ) ).to be false
  end

  it 'can translate long url to short' do
    url = 'https://developers.weixin.qq.com/doc/offiaccount/Account_Management/URL_Shortener.html'
    result = wechat.get_short_url(url)
    pp result
    expect(result).not_to be nil
  end

  it 'can get temp qrcode' do
    result = wechat.scene_qrcode('12sdj_asldfji_saldf_jisd3456789', {expire_seconds: 9999})
    pp result
    expect(result).not_to be nil
  end

  it 'can get media id' do
    result = wechat.assets.tmp_add('image', '/home/zhong/a.png')

    media_id = result['media_id']
    pp result
    expect(media_id).not_to be nil
    pp wechat.messages.send_image('osip61TslXFOq134R4pc2tI9qQrk', media_id)
  end

  it 'can get use info by openid' do
    result = wechat.get_user_by_id("osip61TslXFOq134R4pc2tI9qQrk")
    pp result
    expect(result).not_to be nil
  end

  it 'can send template messages' do
    params =
      {
        touser: 'osip61TslXFOq134R4pc2tI9qQrk',
        # template_id: "uQtXKW0Uz-STOVXb2ra-SYYrPpzoeshgbahX4Kg2F9Y",
        template_id: 'ItWRq3Qm-qcEUWw79sSADu6axa38reZUqTWJE2tsos0',
        data: {
          first: {
            value: "Welcome"
          },
          orderno: {
            value: "123456789"
          },
          amount: {
            value: 123
          },
          remark: {
            value: "Thanks"
          }
        }
      }
    result = wechat.messages.send_template(params)

    pp result
    expect(result['errcode']).to be 0
  end

  it 'can create menu' do
    params = {
      "button":[
                  {
                    "type":"click",
                    "name":"今日歌曲",
                    "key":"V1001_TODAY_MUSIC"
                  },
                  {
                    "name":"菜单",
                    "sub_button":[
                                    {
                                      "type":"view",
                                      "name":"搜索",
                                      "url":"http://www.soso.com/"
                                    },
                                    {
                                      "type":"click",
                                      "name":"赞一下我们",
                                      "key":"V1001_GOOD"
                                    }]
                  }]
    }
    result = wechat.menu.create(params)
    pp result
    expect(result['errcode']).to be 0
  end

  it 'raise ticket_error exception' do
    expect{wechat.jsapi_ticket('123')}.to raise_error(Wechatruby::TicketError)
  end

end
