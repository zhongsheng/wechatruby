# frozen_string_literal: true

RSpec.describe Wechatruby do

  let(:userid) { 'osip61TslXFOq134R4pc2tI9qQrk' }
  it 'can parse text' do
    xml = '<xml>
<ToUserName><![CDATA[toUser]]></ToUserName>
<FromUserName><![CDATA[osip61TslXFOq134R4pc2tI9qQrk]]></FromUserName>
<CreateTime>123456789</CreateTime>
<MsgType><![CDATA[text]]></MsgType>
<Content><![CDATA[hi]]></Content>
<MsgId>22811083100541224</MsgId>
</xml>'
    result = Wechatruby::Xml.parse(xml)
    expect(result.openid).to eq(userid)
    expect(result.event).to eq('text')
    expect(result.get_value('Content')).to eq('hi')
  end

  it 'can parse xml' do
    xml = '<xml>
<ToUserName><![CDATA[toUser]]></ToUserName>
<FromUserName><![CDATA[osip61TslXFOq134R4pc2tI9qQrk]]></FromUserName>
<CreateTime>123456789</CreateTime>
<MsgType><![CDATA[event]]></MsgType>
<Event><![CDATA[CLICK]]></Event>
<EventKey><![CDATA[EVENTKEY]]></EventKey>
</xml>'
    result = Wechatruby::Xml.parse(xml)
    expect(result.openid).to eq(userid)
    expect(result.event).to eq('CLICK')
    expect(result.get_value('EventKey')).to eq('EVENTKEY')
  end

  it 'can parse location' do
    xml = '<xml><ToUserName><![CDATA[gh_e136c6e50636]]></ToUserName>
<FromUserName><![CDATA[oMgHVjngRipVsoxg6TuX3vz6glDg]]></FromUserName>
<CreateTime>1408091189</CreateTime>
<MsgType><![CDATA[event]]></MsgType>
<Event><![CDATA[location_select]]></Event>
<EventKey><![CDATA[6]]></EventKey>
<SendLocationInfo><Location_X><![CDATA[23]]></Location_X>
<Location_Y><![CDATA[113]]></Location_Y>
<Scale><![CDATA[15]]></Scale>
<Label><![CDATA[ 广州市海珠区客村艺苑路 106号]]></Label>
<Poiname><![CDATA[]]></Poiname>
</SendLocationInfo>
</xml>'
    result = Wechatruby::Xml.parse(xml)
    expect(result.get_value('Location_Y')).to eq('113')
  end
end
