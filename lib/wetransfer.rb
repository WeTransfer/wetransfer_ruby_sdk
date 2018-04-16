require 'faraday'
require 'json'
require 'dotenv'
Dotenv.load
require 'pry'

require 'wetransfer/version'
require 'wetransfer/client'
require 'wetransfer/authorizer'
require 'wetransfer/transfer'
require 'wetransfer/transfers'
require 'wetransfer/upload'

module WeTransfer
end
