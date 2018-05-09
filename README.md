# WeTransfer's Ruby SDK

An open source Ruby SDK for the WeTransfer Open API

For your API key please visit our [developer portal](https://developers.wetransfer.com).

[![Build Status](https://travis-ci.com/WeTransfer/wetransfer_ruby_sdk.svg?token=fYsuJT8hjJt2hyWqaLsM&branch=master)](https://travis-ci.com/WeTransfer/wetransfer_ruby_sdk) [![Gem Version](https://badge.fury.io/rb/wetransfer.svg)](https://badge.fury.io/rb/wetransfer)

## Table of Contents

1. [Installation](#installation)
2. [Usage](#usage)
3. [Configuration](#configuration)
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

Be sure to not commit this key to Github! If you do though, no worries, you can always revoke & create a new key from within the portal. You will most likely want to pass this to the client setter using an environment variable.

Now that you've got a wonderful WeTransfer API key, you can create a Client object like so:

```ruby
# In your project file:
@client = WeTransferClient.new(api_key: ENV.fetch('WT_API_KEY'))
```

Now that you've got the client set up you can use the `create_transfer` to, well, create a transfer!

```ruby
transfer = @client.create_transfer(name: "My wonderful transfer", description: "I'm so excited to share this") do |upload|
  upload.add_file_at(path: '/path/to/local/file.jpg')
  upload.add_file_at(path: '/path/to/another/local/file.jpg')
  upload.add_file(name: 'README.txt', io: StringIO.new("This is the contents of the file"))
end

transfer.shortened_url => "https://we.tl/SSBsb3ZlIHJ1Ynk="
```

The upload will be performed at the end of the block.

## Development

After forking and cloning down the repo, run `bin/setup` to install dependencies. Then, run `bundle exec rspec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/wetransfer/wetransfer. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the WetransferRubySdk project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/wetransfer/wetransfer/blob/master/CODE_OF_CONDUCT.md).
