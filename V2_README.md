The process

In the v2 version of the Ruby SDK we have added a new feature, mutable transfers called boards.

Boards excists next to the transfers and will be mutable, so you can add new files or web_links to your board.


To use the ruby sdk you have to Initailize a new client with your API-Key:

```
client = WeTransfer::Client.new(api_key: 'your-special-api-key')
```

### Initailize a Board

Once you created that new client you can call methods to create a new board, empty or as a block:

```
board = client.create_board(name: 'File Collection', description: 'A collection of files')
```
or:
```
board = client.create_board(name: 'Dog Collection', description: 'A collection of dogs') do |item|
  item.add_file(name: 'dalmatian.jpg', io: File.open('path/to/dalmatian.jpg', 'r'))
  item.add_file(name: 'beagle.jpg', io: File.open('path/to/beagle.jpg', 'r'))
  item.add_file(name: 'great_dane.jpg', io: File.open('path/to/great_dane.jpg', 'r'))
  item.add_web_url(url: 'http://www.wetransfer.com', title: 'WeTransfer Website')
end
```

### Initialize a Transfer

For initializing a transfer the process is like this:

```ruby
transfer = @client.create_transfer(name: "Dog transfer", description: "Have a look at my dogs") do |upload|
  upload.add_file(name: 'chihuahua.jpg', io: File.open('path/to/chihuahua.jpg', 'r'))
  upload.add_file(name: 'chow_chow.jpg', io: File.open('path/to/chow_chow.jpg', 'r'))
end

transfer.shortened_url => "https://we.tl/SSBsb3ZlIHJ1Ynk="
```

Note: For initializing a transfer you have to pass all the files directly so the backend knows what you are uploading.



### uploading the files

For both the transfer and board, the files are not in you transfer or collection, yet.

The files need to be uploaded and finalized

