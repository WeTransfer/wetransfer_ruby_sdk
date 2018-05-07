# WeTransfer's Ruby SDK

An open source Ruby SDK for the WeTransfer Open API

For your API key please visit our [developer portal](https://developers.wetransfer.com).

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

### Configuration

The gem allows you to configure several settings using environment variables.

- `WT_API_LOGGING_ON` can be set to (a string) "true" if you want to switch Faraday's default logging on.

- `WT_API_URL` can be set to a staging or test URL (something we do not offer yet, but plan to in the future)

- `WT_API_CONNECTION_PATH` can be set to prefix the paths passed to faraday - for example if you're testing against a test API or a different version.

### Super simple transfers

You'll need to retrieve an API key from [our developer portal](https://developers.wetransfer.com).

Be sure to not commit this key to github! If you do though, no worries, you can always revoke & create a new key from within the portal. You will most likely want to pass this to the client setter using an environment variable.

Now that you've got a wonderful WeTransfer API key, you can create a Client object like so:

```ruby
# In a .env or other secret handling file, not checked in to version control:
WT_API_KEY=<your API key>

# In your project file:
@client = WeTransfer::Client.new(api_key: ENV['WT_API_KEY'])
```

Now that you've got the client set up you can use the `create_transfer` to, well, create a transfer!

If you pass item paths to the method it will handle the upload process itself, otherwise you can omit them and
use the `add_items` method once the transfer has been created.

```ruby
transfer = @client.create_transfer(name: "My wonderful transfer", description: "I'm so excited to share this", items: ["/path/to/local/file_1.jpg", "/path/to/local/file_2.png", "/path/to/local/file_3.key"])

transfer.shortened_url = "https://we.tl/SSBsb3ZlIHJ1Ynk="
```

## Item upload flow

### `add_items`

If you want slightly more granular control over your transfer, create it without an `items` array, and then use `add_items` with the resulting transfer object.

```ruby
transfer = @client.create_transfer(name: "My wonderful transfer", description: "I'm so excited to share this")

@client.add_items(transfer: @transfer, items: ["/path/to/local/file_1.jpg", "/path/to/local/file_2.png", "/path/to/local/file_3.key"])

transfer.shortened_url = "https://we.tl/d2V0cmFuc2Zlci5ob21lcnVuLmNv"
```

## Development

After forking and cloning down the repo, run `bin/setup` to install dependencies. Then, run `bundle exec rspec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/wetransfer/wetransfer. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the WetransferRubySdk project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/wetransfer/wetransfer/blob/master/CODE_OF_CONDUCT.md).