require './app'
require 'logger'

logger = Logger.new("server.log")

use Rack::CommonLogger, logger

run Cuba
