#!/usr/bin/env ruby
#
# Map control test that simulates a game of TreasureHunt. Test creates prizes and receives statuses for how close the player is to the prize based on sent in coordinates.
# Assume an already built in game_location (id 2) has been created for testing purposes.
#

require_relative '../map_control.rb'

#
# Highridge park map test
# 33.7645291,-118.3818312
# Amount: 800
#

MapControl.create_prize(-118.3818312,33.7645291,800,2,"where the little kids play")

puts "Prizes from game test"

list = MapControl.prizes_from_game(2)

puts list[0]["amount"].to_i

puts "Game within given location test"

#
# 33.763160, -118.379214
#

game_id = MapControl.game_within_location(-118.379214,33.76316)

puts game_id

puts "Person close to prize test"

puts MapControl.play_response(-118.379214,33.76316) == "VERY_CLOSE"

puts "Person not in game location test"

# 37.474189, -122.157820

puts MapControl.play_response(-122.157820,37.474189) == "NO_CURRENT_GAME"

puts "Prize pickup resonse test"

puts MapControl.play_response(-118.3818312,33.7645291) == "RECEIVED 800"

puts "Post pickup nothing test"

puts MapControl.play_response(-118.3818312,33.7645291) == "NO_MORE_PRIZES"

puts MapControl.prize_hints(-118.4178390,33.772670)
