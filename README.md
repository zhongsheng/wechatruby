# Wechatruby

Welcome to your new gem! In this directory, you'll find the files you need to be able to package up your Ruby library into a gem. Put your Ruby code in the file `lib/wechatruby`. To experiment with that code, run `bin/console` for an interactive prompt.

TODO: Delete this and the text above, and describe your gem

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'wechatruby'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install wechatruby

## Usage

Configure AppID and SecretID

```ruby
Wechatruby::APP[:id] = 'appid'
Wechatruby::APP[:secret] = 'secret'
```

Wechatruby.session(code) return a hash object contain
openid	string	用户唯一标识
session_key	string	会话密钥
unionid	string	用户在开放平台的唯一标识符，在满足 UnionID 下发条件的情况下会返回，详见 UnionID 机制说明。
errcode	number	错误码
errMsg	string	错误信息

Wechatruby.decrypt encryptedData, return a hash object
{
    "openId": "OPENID",
    "nickName": "NICKNAME",
    "gender": GENDER,
    "city": "CITY",
    "province": "PROVINCE",
    "country": "COUNTRY",
    "avatarUrl": "AVATARURL",
    "unionId": "UNIONID",
    "watermark": {
        "appid": "APPID",
        "timestamp": TIMESTAMP
    }
}

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Wechatruby project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/wechatruby/blob/master/CODE_OF_CONDUCT.md).
