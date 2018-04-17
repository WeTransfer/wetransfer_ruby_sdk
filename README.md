# WetransferRubySdk

Ruby SDK for the WeTransfer Public API. Coming soon!

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


## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bundle exec rspec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/wetransfer/wetransfer. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the WetransferRubySdk project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/wetransfer/wetransfer/blob/master/CODE_OF_CONDUCT.md).


### Usage Examples

Configure a new client
```
@client = WeTransfer::Client.new(api_key: 'api key')
```


Now you are all setup to create transfers and send files over the web. The simplest approach is to use the Upload class. The response will be a WeTransfer link where you can download the files. Optional you can send a name and description as options.

`WeTransfer::Upload.new(client: @client, files: [], options: {name: 'transfer name', description: 'This can be a description of the content'} )`


```
WeTransfer::Upload.new(client: @client, files: ["/path/to/local/file_1.jpg", "/path/to/local/file_2.png", "/path/to/local/file_3.key"] )

```


If you want more freedom you can use these methods:

`create_transfer(name:, description:, items: [])`

`add_items(transfer:, items:)`

`get_upload_urls(transfer:)`

`multi_part_file(item:, file: )`

`single_part_file(item:, file: )`


#### create_transfer
The create_transfer method takes 3 arguments, a name, a description and an array with items.
the items should all have this layout and the local_identifier is limited to 36 characters.

```
@transfer = WeTransfer::Transfers.new(@client).create_transfer(name: 'A name', description: 'I want to share these files with you', items: [{"local_identifier": "Random 36 characters", "content_identifier": "file", "filename": "filename.gif", "filesize": 1024 }])
```

#### add_items
If you forgot to add some items to your transfer there's a possibility to always add some more.

```
@transfer = WeTransfer::Transfers.new(@client).add_items(transfer: @transfer, items: [{"local_identifier": "foo", "content_identifier": "file", "filename": "foo.gif", "filesize": 1024 },{"local_identifier": "bar", "content_identifier": "file", "filename": "bar.gif", "filesize": 8234543 }])
```


#### get_upload_urls
Single part items have their upload url provided in the hash, for multi part files this endpoint is provided where the upload urls will be stored as an array inside the items upload_url

```
@transfer = WeTransfer::Transfers.new(@client).get_upload_urls(transfer: @transfer)

```


#### multi_part_file
The multi part file method is to upload the item to the upload urls stored into the upload_url key. Send the item hash and the file to this method and the method will read the 6MB for every upload url and send it to the pre-signed aws url. After the upload is done the file will be completed

`item` should be the hash containing all hash information
`file_path` is the path to the local file

```
WeTransfer::Transfers.new(@client).multi_part_file(item: item file: file_path)

```

#### single_part_file
The single part file method is to upload singel part files, these are files less then 6MB. They don't need a multi part upload and can be send directly to the provided S3 url. After the upload is done the file will be completed

`item` should be the hash containing all hash information
`file_path` is the path to the local file


```
WeTransfer::Transfers.new(@client).multi_part_file(item: item file: file_path)
```

