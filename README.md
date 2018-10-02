# WeTransfer Ruby SDK

The Ruby SDK that makes interacting with WeTransfer's Public API a breeze

This gem can be used to create transfers (as seen on WeTransfer.com) and boards (as seen in our [iOS app](https://itunes.apple.com/app/apple-store/id765359021?pt=10422800&ct=wetransfer-developer-portal&mt=8) and [Android app](https://play.google.com/store/apps/details?id=com.wetransfer.app.live&referrer=utm_source%3Dwetransfer%26utm_medium%3Ddeveloper-portal) ) alike.

For your API key and additional info please visit our [developer portal](https://developers.wetransfer.com).

[![Build Status](https://travis-ci.com/WeTransfer/wetransfer_ruby_sdk.svg?token=fYsuJT8hjJt2hyWqaLsM&branch=master)](https://travis-ci.com/WeTransfer/wetransfer_ruby_sdk) [![Gem Version](https://badge.fury.io/rb/wetransfer.svg)](https://badge.fury.io/rb/wetransfer)

## Table of Contents

1. [Installation](#installation)
1. [Getting started](#getting-started)
1. [Transfers](#transfers)
    * [Minimalist transfers](#minimalist-transfers)
    * [Deep dive into transfers](#deep-dive-into-transfers)
1. [Boards](#boards)
1. [Development](#development)
1. [Contributing](#contributing)
1. [License](#license)
1. [Code of Conduct](#code-of-conduct)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'wetransfer'
```

And then execute:

    bundle install

Or install it yourself as:

    gem install wetransfer

## Getting started

You'll need to retrieve an API key from [our developer portal](https://developers.wetransfer.com).

Be sure to not commit this key to Github! If you do though, you can always revoke it and create a new key from within the portal.

For configuring and storing secrets - like this API key - there are a variety of solutions. The smoothest here is creating a `.env` file:

Now that you've got a wonderful WeTransfer API key, create a .env file in your project folder:

    touch .env

You don't want the contents of this file to leave your system. Ever.

If the `.env` file is new, make sure to add it to your `.gitignore`, using the following command:

    echo .env >> .gitignore

Open the file in your text editor and add this line:

    WT_API_KEY=<your api key>

Make sure to replace `<your api key>` by your actual api key. Don't include the pointy brackets!

Great! Now you can go to your project file and use the client.

## Transfers

A transfer is a collection of files that can be created once, and downloaded many times. Once a transfer is created, it is closed for modifications.

### Minimalist transfers

```ruby
# In your project file:
require 'we_transfer_client'

client = WeTransfer::Client.new(api_key: ENV.fetch('WT_API_KEY'))
```

Now that you've got the client set up you can use  `create_transfer` to, well, create a transfer!

```ruby
transfer = client.create_transfer_and_upload_files(message: 'All the Things') do |upload|
  upload.add_file_at(path: '/path/to/local/file.jpg')
  upload.add_file_at(path: '/path/to/another/local/file.jpg')
  upload.add_file(name: 'README.txt', io: StringIO.new("You should read All the Things!"))
end

transfer.url => "https://we.tl/t-123234="
```

The upload will be performed at the end of the block. Depending on your file sizes and network connection speed, this might take some time.

What are you waiting for? Open that link in your browser! Chop chop.

### Deep dive into transfers

More control over your transfers? We've got you covered!

1. do this
2. do that


### Boards

A board is a collection of files and links, but it is open for modifications. Like your portfolio: While working, you can make adjustments to it. A board is a fantastic place for showcasing your work in progress.

## Development

You'll need to retrieve an API key from [our developer portal](https://developers.wetransfer.com), and as described above, store it in a local `.env` file. As always, do not commit this file to github! :)

After forking and cloning down the repo, run `bundle install` to install dependencies. Then, run `bundle exec rspec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

    git clone <your fork> ./wetransfer_ruby_sdk
    cd wetransfer_ruby_sdk
    bundle install

To install this gem onto your local machine, run `bundle exec rake install`.

To execute to ruby specs, run:

    bundle exec rspec

Please note that we use rubocop to lint this gem -- be sure to run it prior to submitting a PR for maximum mergeability.

    bundle exec rubocop

If any violations can be handled by rubocop, you can run auto-fix and it'll handle them for you, though do run the tests again and make sure it hasn't done something... unexpected.

    bundle exec rubocop -a

For more convenience you also can run Guard, this checks all the tests and runs rubocop every time you save your files.

    bundle exec guard

Hooray!

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/wetransfer/wetransfer_ruby_sdk. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct. More extensive contribution guidelines can be found [here](https://github.com/WeTransfer/wetransfer_ruby_sdk/blob/master/.github/CONTRIBUTING.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT) - the in-repo version of the license is [here](https://github.com/WeTransfer/wetransfer_ruby_sdk/blob/master/LICENSE.txt).

## Code of Conduct

Everyone interacting in the WeTransfer Ruby SDK project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/WeTransfer/wetransfer_ruby_sdk/blob/master/.github/CODE_OF_CONDUCT.md).
