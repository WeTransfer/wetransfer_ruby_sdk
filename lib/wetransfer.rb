require 'faraday'
require 'json'
require 'dotenv'
Dotenv.load

require 'wetransfer/version'
require 'wetransfer/client'
require 'wetransfer/authorizer'
require 'wetransfer/transfer'
require 'wetransfer/transfers'

module WeTransfer
end
