# WeTransfer Ruby SDK

The Ruby SDK that makes interacting with WeTransfer's Public API a breeze

This gem can be used to create transfers (as seen on WeTransfer.com) and boards (as seen in our [iOS app](https://itunes.apple.com/app/apple-store/id765359021?pt=10422800&ct=wetransfer-developer-portal&mt=8) and [Android app](https://play.google.com/store/apps/details?id=com.wetransfer.app.live&referrer=utm_source%3Dwetransfer%26utm_medium%3Ddeveloper-portal) ) alike.

For your API key and additional info please visit our [developer portal](https://developers.wetransfer.com).

[![Build Status](https://travis-ci.com/WeTransfer/wetransfer_ruby_sdk.svg?token=fYsuJT8hjJt2hyWqaLsM&branch=master)](https://travis-ci.com/WeTransfer/wetransfer_ruby_sdk) [![Gem Version](https://badge.fury.io/rb/wetransfer.svg)](https://badge.fury.io/rb/wetransfer)

## Table of Contents

1. [Installation](#installation)
1. [Getting started](#getting-started)
1. [Transfers](#transfers)
1. [Boards](#boards)
1. [Development](#development)
1. [Contributing](#contributing)
1. [License](#license)
1. [Code of Conduct](#code-of-conduct)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'wetransfer', version: '0.10.0.beta1'

# If you need Board support, as found in WeTransfer's Collect app, use version 0.9.x)
gem 'wetransfer', version: '0.9.0.beta3'
```

And then execute:

    bundle install

Or install it yourself as:

    gem install wetransfer

## Getting started

You'll need to retrieve an API key from [our developer portal](https://developers.wetransfer.com).

Be sure to not commit this key to Github! If you do though, you can always revoke it and create a new key from within the portal.

For configuring and storing secrets - like this API key - there are a variety of solutions. The smoothest here is creating a `.env` file, and use a gem like [dotenv](https://github.com/bkeepers/dotenv).

Now that you've got a wonderful WeTransfer API key, create a .env file in your project folder:

    touch .env

You don't want the contents of this file to leave your system. Ever.

If the `.env` file is new, make sure to add it to your `.gitignore`, using the following command:

    echo .env >> .gitignore

Open the file in your text editor and add this line:

    WT_API_KEY=<your api key>

Make sure to replace `<your api key>` with your actual api key. Don't include the pointy brackets!

Great! Now you can go to your project file and use the client.

## Transfers

A transfer is a collection of files that can be created once, and downloaded until it expires. Once a transfer is ready for sharing, it is closed for modifications.

```ruby
# In your project file:
require 'we_transfer'

client = WeTransfer::Client.new(api_key: ENV.fetch('WT_API_KEY'))
```

Now that you've got the client set up you can use  `create_transfer_and_upload_files` to, well, create a transfer, and upload all files!

```ruby
transfer = client.create_transfer_and_upload_files(message: 'All the Things') do |transfer|
  # Add a file using File.open. If you do it like this, :name and :io params are optional
  transfer.add_file(io: File.open('Gemfile'))

  # Add a file with File.open, but give it a different name inside the transfer
  transfer.add_file(
    name: 'hello_world.rb',
    io: File.open('path/to/file/with/different_name.rb')
  )

  # Using :name, :size and :io params.
  # Specifying the size is not very useful in this case, but feel free to explicitly
  # communicate the size of the coming io.
  #
  # The :name param is compulsory if it cannot be derived from the IO.
  transfer.add_file(
    name: 'README.txt',
    size: 31,
    io: StringIO.new("You should read All the Things!")
  )
end

# To get a link to your transfer, call `url` on your transfer object:
transfer.url # => "https://we.tl/t-1232346"

# Or inspect the whole transfer:
transfer.to_h # =>
# {
#   :id => "0d5ce492c0cd935b5376c7858b0ff5ae20190307162739",
#   :state => "processing",
#   :url => "https://we.tl/t-CVINGH30C4",
#   :message => "test transfer",
#   :files => [
#     {
#       :name => "README.txt",
#       :size => 31,
#       :id => "0e04833491a31776770ac4dcf83d1f4a20190307162739",
#       :multipart => {
#         :chunks => 1,
#         :chunk_size => 31
#       }
#     }, {
#       :name => "hello_world.rb",
#       :size => 166,
#       :id => "22423dd4b44300641a4659203ba5d1bb20190307162739",
#       :multipart => {
#         :chunks => 1,
#         :chunk_size => 166
#       }
#     }
#   ]
# }
```

The upload will be performed at the end of the block. Depending on your file sizes and network connection speed, this might take some time.

What are you waiting for? Open that link in your browser! Chop chop.

If you want to have more control over which files uploads when, it is also possible.

```ruby
# Create a transfer that consists of 1 file.
transfer = client.create_transfer(message: "test transfer") do |transfer|
  # When creating a transfer, at least the name and the size of the file(s)
  # must be known.
  transfer.add_file(name: "small_file", size: 80)
end

# Upload the file. The Ruby SDK will upload the file in chunks.
transfer.upload_file(name: "small_file", io: StringIO.new("#" * 80))

# Mark the file as completely uploaded. All the chunks of the file will be joined
# together to recreate the file
transfer.complete_file(name: "small_file")

# Mark the transfer as completely done, so your customers can start downloading it
transfer.finalize

# Inspect your transfer. Use transfer.to_h or transfer.to_json, depending on your scenario
transfer.to_h
```

## Boards

**NOTE**: **Boards are disabled from version 0.10.x** of the Ruby SDK. The latest releases that include **board support is found in version 0.9.x**

A board is a collection of files and links, but it is open for modifications. Like your portfolio: While working, you can make adjustments to it. A board is a fantastic place for showcasing your work in progress.

Boards need a WeTransfer Client to be present, just like transfers.

```ruby
# In your project file:
require 'we_transfer'

client = WeTransfer::Client.new(api_key: ENV.fetch('WT_API_KEY'))
```

After you create your client, you can

### Create a board and upload items

```ruby
board = client.create_board(name: 'Meow', description: 'On Cats') do |items|
  items.add_file(name: 'big file.jpg', io: File.open('/path/to/huge_file.jpg')
  items.add_file_at(path: '/path/to/another/file.txt')
  items.add_web_url(url: 'http://wepresent.wetransfer.com', title: 'Time well spent')
end

puts board.url # => "https://we.tl/b-923478"
```

You've just created a board. It is visible on the internet, to share it with anyone.

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

Bug reports and pull requests are welcome on GitHub at <https://github.com/wetransfer/wetransfer_ruby_sdk.> This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct. More extensive contribution guidelines can be found [here](https://github.com/WeTransfer/wetransfer_ruby_sdk/blob/master/.github/CONTRIBUTING.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT) - the in-repo version of the license is [here](https://github.com/WeTransfer/wetransfer_ruby_sdk/blob/master/LICENSE.txt).

## Code of Conduct

Everyone interacting in the WeTransfer Ruby SDK project’s code bases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/WeTransfer/wetransfer_ruby_sdk/blob/master/.github/CODE_OF_CONDUCT.md).
