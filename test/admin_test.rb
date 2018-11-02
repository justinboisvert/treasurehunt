#!/usr/bin/env ruby
#
# Test administrative endpoints such as listing all games, modifying game and prize information. 
#
require 'unirest'
require 'json'

path = "localhost:8842"

res = Unirest.post("#{path}/users/login", parameters:{:username => "helloboy", :password => "waaaadup"}.to_json)

session = res.body["session"]

puts res.body

# 33.763948, -118.380095
res = Unirest.post("#{path}/admin/games/create", headers:{:session => session},parameters:{:longitude => -118.380095, :latitude => 33.763948, :title => 'Great game', :description => 'fantastic game', :radius => 2*1609.34}.to_json)

puts "Game"
puts res.body

res = Unirest.get("#{path}/admin/games", headers:{:session => session})

res = Unirest.post("#{path}/admin/prizes/create", headers:{:session => session}, parameters:{:longitude => -118.380290, :latitude => 33.763982,:amount => 30, :game_id => 3, :hint => "Crazy shit", :title => "Ye"}.to_json)

id = res.body["id"]

puts id

res = Unirest.put("#{path}/admin/prizes/#{id}", headers:{:session => session}, parameters:{:title => "floblo"}.to_json)

res = Unirest.get("#{path}/games/3/prizes/", headers:{:session => session})

prizes = res.body["prizes"]

prizes.each do |prize|
  if prize["id"] == id
    puts prize
  end
end

res = Unirest.post("#{path}/admin/prizes/#{id}/delete", headers:{:session => session})

puts res.body

