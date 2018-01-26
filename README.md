# MostMoneyOts

[Most Money](https://customer.mostmoney.mn/index.aspx?page=content/uctrademerchant#content~share)
External Protocol

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'most_ots'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install most_ots

## Usage

```ruby
  service = MostOts::Service.new(
    most_pem_location: '[PATH TO MOST PUBLIC KEY]', 
    cipher_key: '[YOUR CYPHER KEY]', # can be nil in order to use random key
    cipher_iv: [0x9C], # Most Provided cipher byte array for example [0x9C, 0xC6, 0x60, 0xD0, 0x1A, 0x13, 0x2C, 0x62, 0x68, 0x79, 0x92, 0x84, 0x71, 0xA6, 0x05, 0x13]
    src_inst_id: '300000',
    channel: '20', # 
    lang: '0', # 0: Монгол, 1, English
    tran_cur: 'MNT', # Transaction Currency
    pos_no: '1234',
    payee_id: '0',
    qr_account_name: '0',
    qr_account_number: '0',
    qr_bank_code: '0',
    protocol_version: '05'
  )
  
  response = service.purchase_qr(
    traceNo: '2017052405430504',
    tranAmount: '1.0',
    tranDesc: 'Test: QR Purchase'
  )
```



## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/ssxenon01/most_ots. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the MostOts project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/ssxenon01/most_ots/blob/master/CODE_OF_CONDUCT.md).
