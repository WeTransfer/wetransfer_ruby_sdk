# WeTransfer's Ruby SDK

An open source Ruby SDK for the WeTransfer Open API

For API Keys etc please visit our [developer portal](https://developers.wetransfer.com).

## Table of Contents

1. [Installation](#installation)
2. [Usage](#usage)
3. [Methods](#methods)
4. [Development](#development)
5. [Contributing](#contributing)
6. [License](#license)
7. [Code of Conduct](#code-of-conduct)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'wetransfer'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install wetransfer

## Usage

### Super simple transfers

You'll need to retrieve an API key from [our developer portal](https://developers.wetransfer.com).

Be sure to not commit this key to github! If you do though, no worries, you can always revoke & create a new key from within the portal.

Now that you've got a wonderful WeTransfer API key, you can create a Client object like so:

```ruby
@client = WeTransfer::Client.new(api_key: 'api key')
```

Now that you've got the client set up you can use the `create_transfer` to, well, create a transfer!

If you pass item paths to the method it will handle the upload process itself, otherwise you can omit them and
use the `add_items` method once the transfer has been created.

```ruby
@client.create_transfer(name: "My wonderful transfer", description: "I'm so excited to share this", items: ["/path/to/local/file_1.jpg", "/path/to/local/file_2.png", "/path/to/local/file_3.key"])`
```

## Item upload flow

### `add_items`

If you want slightly more granular control over your transfer, create it without an `items` array, and then use `add_items` with the resulting transfer object.

```ruby
@transfer = WeTransfer::Transfers.new(@client).add_items(transfer: @transfer, items: ["/path/to/local/file_1.jpg", "/path/to/local/file_2.png", "/path/to/local/file_3.key"])
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bundle exec rspec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/wetransfer/wetransfer. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the WetransferRubySdk project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/wetransfer/wetransfer/blob/master/CODE_OF_CONDUCT.md).