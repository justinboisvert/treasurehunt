#!/usr/bin/env ruby
#
# Test out Treasurehunt backend's rest endpoints
#
# TODO call a create prize admin command so the test can see if the claim endpoint actually claims in a controlled state
# instead of saying "no prize" due to no prizes currently being created
require 'unirest'

puts "Create username test"
path = "localhost:8842"

response = Unirest.post("#{path}/users/signup", parameters:{:username => "helloboy", :password => "waaaadup", :email => "yeah"}.to_json)
puts "users/login test"

response = Unirest.post("#{path}/users/login", parameters:{:username => "helloboy", :password => "waaaadup"}.to_json)

puts response.body

session = response.body["session"]
id = response.body["user"]["id"]

puts session 

puts "users/:id get test"

response = Unirest.get("#{path}/users/#{id}", headers:{"session" => session})

puts response.body

puts "/users/:id put test"
response = Unirest.put("#{path}/users/#{id}", headers:{"session" => session}, parameters:{"payment_info" => "eel"}.to_json)

puts response.body

puts "/games test"
response = Unirest.get("#{path}/games", parameters:{:longitude => -118.376886, :latitude => 33.767340}, headers:{"session" => session})

puts response.body

puts "/games/:id/prizes test"
response = Unirest.get("#{path}/games/5/prizes", headers:{"session" => session})

puts response.body


#game_id = response.body["games"][0]["id"]

#puts "/games/:game_id test"

#response = Unirest.get("#{path}/games/#{game_id}", headers:{"session" => session})

#puts response.body

puts "/games/:id/status test"

response =  Unirest.get("#{path}/games/3/status", parameters:{:longitude => -118.376886, :latitude => 33.767340}, headers:{"session" => session})

puts response.body

puts "/games/:game_id/claim"

response =  Unirest.post("#{path}/games/3/claim", parameters:{:longitude => -118.376886, :latitude => 33.767340}, headers:{"session" => session})

puts response.body


response =  Unirest.post("#{path}/games/3/prizes", headers:{"session" => session})

puts response.body


