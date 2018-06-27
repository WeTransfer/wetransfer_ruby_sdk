# WeTransfer Ruby SDK

An open source Ruby SDK for the WeTransfer Public API

For your API key and additional info please visit our [developer portal](https://developers.wetransfer.com).

[![Build Status](https://travis-ci.com/WeTransfer/wetransfer_ruby_sdk.svg?token=fYsuJT8hjJt2hyWqaLsM&branch=master)](https://travis-ci.com/WeTransfer/wetransfer_ruby_sdk) [![Gem Version](https://badge.fury.io/rb/wetransfer.svg)](https://badge.fury.io/rb/wetransfer)

## Table of Contents

1. [Installation](#installation)
2. [Usage](#usage)
3. [Super simple transfers](#super-simple-transfers)
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

### Minimalist transfers

You'll need to retrieve an API key from [our developer portal](https://developers.wetransfer.com).

Be sure to not commit this key to Github! If you do though, no worries, you can always revoke & create a new key from within the portal.

For configuring and storing secrets - like this API key - there are a variety of solutions. The smoothest here is creating a .env file:

Now that you've got a wonderful WeTransfer API key, create a .env file in your project folder:

    $ touch .env

Check your `.gitignore` file and make sure it has `.env` listed!

Now, open the file in your text editor and add this line:

`WT_API_KEY=<your api key>` (without the <> brackets!)

Great! Now you can go to your project file and create the client:

```ruby
# In your project file:
require 'we_transfer_client'

@client = WeTransferClient.new(api_key: ENV.fetch('WT_API_KEY'))
```

Now that you've got the client set up you can use  `create_transfer` to, well, create a transfer!

```ruby
transfer = @client.create_transfer(name: "My wonderful transfer", description: "I'm so excited to share this") do |upload|
  upload.add_file_at(path: '/path/to/local/file.jpg')
  upload.add_file_at(path: '/path/to/another/local/file.jpg')
  upload.add_file(name: 'README.txt', io: StringIO.new("This is the contents of the file"))
  upload.add_web_content(path: "https://www.the.url.you.want.to.share.com"))
<<<<<<< HEAD
  upload.add_file_from_url(path: "https://path.to/images.jpg")
=======
>>>>>>> master
end

transfer.shortened_url => "https://we.tl/SSBsb3ZlIHJ1Ynk="
```

The upload will be performed at the end of the block.

## Development
You'll need to retrieve an API key from [our developer portal](https://developers.wetransfer.com), and as described above, store it in a local `.env` file. As always, do not commit this file to github! :)

After forking and cloning down the repo, run `bundle install` to install dependencies. Then, run `bundle exec rspec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

```
$ git clone <your fork>
$ cd wetransfer_ruby_sdk
$ bundle install
```

To install this gem onto your local machine, run `bundle exec rake install`.

To execute to ruby specs, run:

```
$ bundle exec rspec
```

Please note that we use rubocop to lint this gem -- be sure to run it prior to submitting a PR for maximum mergeability.

    $ bundle exec rubocop

If any violations can be handled by rubocop, you can run auto-fix and it'll handle them for you, though do run the tests again and make sure it hasn't done something ... unexpected.

    $ bundle exec rubocop -a

Hooray!

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/wetransfer/wetransfer_ruby_sdk. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct. More extensive contribution guidelines can be found [here](https://github.com/WeTransfer/wetransfer_ruby_sdk/blob/master/.github/CONTRIBUTING.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT) - the in-repo version of the license is [here](https://github.com/WeTransfer/wetransfer_ruby_sdk/blob/master/LICENSE.txt).

## Code of Conduct

Everyone interacting in the WeTransfer Ruby SDK project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/WeTransfer/wetransfer_ruby_sdk/blob/master/.github/CODE_OF_CONDUCT.md).