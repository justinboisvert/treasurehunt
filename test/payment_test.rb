#!/usr/bin/env ruby
#
# Payment test for sending money to user's paypal address.
#

require_relative '../user_control'

response = UserControl.redeem(1)

puts response 
