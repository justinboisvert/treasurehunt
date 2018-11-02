#!/usr/bin/env ruby
#
# Test cases for Session
#

require_relative '../session'

puts "Session created ID test"

Session.delete(34)

session = Session.create(34)

puts Session.exists?(session) == true

puts "Session get ID test"

puts Session.get_id(session) == 34
