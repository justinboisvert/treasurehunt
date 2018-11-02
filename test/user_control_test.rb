#!/usr/bin/env ruby
#
# UserControl tests
# 

require_relative '../user_control'

if UserControl.username_exists?("justin")
  UserControl.delete_user(UserControl.id_by_username("justin"))
end

user_id = UserControl.create_user(:username => 'justin', :password => 'joblo', :amount => 0, :payment_info => "fefefegfbgg")

puts "User Creation and get info test"

info = UserControl.user_info(user_id)

puts info["username"] == "justin"

puts "User modifying test"

UserControl.modify_user(user_id,"password","nbier12")

puts UserControl.user_info(user_id)["password"] == "nbier12"

puts "User amount increase test"

UserControl.increase_amount(user_id,5)

puts 5 == UserControl.user_info(user_id)["amount"].to_i
