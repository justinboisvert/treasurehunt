#!/usr/bin/env ruby
#
# User creation backend for TreasureHunt
# Stores users via PostgreSQL 
# (c) TH
require 'pg'
require 'paypal-sdk-rest'
require 'securerandom'
require_relative 'hash_control'
include PayPal::SDK::REST
module UserControl
  DBNAME = “”
  DBUSER = “”
  DBPASS = “”
  DBHOST = “”
  def self.start_db()
    @conn = PG::Connection.open(:dbname => DBNAME, :user => DBUSER, :password => DBPASS, :host => DBHOST)
    @conn.type_map_for_results = PG::BasicTypeMapForResults.new(@conn)
  end
   #
   # Create a user based on onboarding parameters and returns the id. 
   #
   def self.create_user(user_options = {})
      if !self.username_exists?(user_options[:username])
        username = user_options[:username]
        balance = user_options[:balance]
        email = user_options[:email]
        pay_id = user_options[:payment_info]
        password = HashControl.createHash(user_options[:password])
        @conn.exec("INSERT INTO users(username,email,balance,password,payment_info,longitude,latitude,is_admin) VALUES ('#{username}','#{email}','#{balance}', '#{password}','#{pay_id}',0.0,0.0,false)")
        return self.id_by_username(username)
      else
        return -1
      end
   end

   #
   # Valid user/password combo
   #
   def self.valid_userpass?(username,password)
     res = @conn.exec("SELECT * FROM users WHERE username='#{username}'")
     count = 0
     res.each do |row|
       count = count + 1
     end
     if count == 0
       return false
     else
       hashPassword = res[0]["password"]
       return HashControl.verifyPassword(password,hashPassword)
     end
   end
   #
   # Return hash of user info by id
   # with keys being the fields of that user
   # 
   def self.user_info(user_id)
     data = @conn.exec("SELECT * FROM users WHERE id = #{user_id}")
     user_info = {}
     fields = data.fields
     data.each do |row|
       (0..fields.size-1).each do |n|
         if fields[n] != "password"
           user_info[fields[n]] = row[fields[n]]
         end
       end 
     end
     return user_info
   end
   #
   # Modify user given key value pair.
   #
   def self.modify_user(user_id,parameter,value)
        if value.instance_of?(String)
          @conn.exec("UPDATE users SET #{parameter} = '#{value}' WHERE id = #{user_id}")
        else
          @conn.exec("UPDATE users SET #{parameter} = #{value} WHERE id = #{user_id}")
        end
   end
   #
   # See if username exists
   #
   def self.username_exists?(username)
     res = @conn.exec("SELECT * FROM users WHERE username='#{username}'")
     count = 0
     res.each do |row|
       count = count + 1
     end
    return count > 0
   end 
 
   #
   # Get ID by username 
   #
   def self.id_by_username(username)
     return @conn.exec("SELECT * FROM users WHERE username='#{username}'")[0]["id"].to_i
   end
   #
   # Delete user by id
   # 
   def self.delete_user(user_id)
     @conn.exec("DELETE FROM users WHERE id='#{user_id}'")
   end

   #
   # Increase user amount by supplied increment given id 
   # 
   def self.increase_amount(user_id,increment)
      amount = self.user_info(user_id)["balance"]+increment
      self.modify_user(user_id,'balance',amount)
   end
  
   #
   # Redeem method using Paypal Payouts
   # 
   def self.redeem(user_id)
     amount = self.user_info(user_id)["balance"]
     puts amount
     self.increase_amount(user_id,-amount)
     if amount > 0
       payout = Payout.new({
       :sender_batch_header => {
         :sender_batch_id => SecureRandom.hex(8),
         :email_subject => 'TreasureHunt Funds Redeemed',
       },
       :items => [
       {
        :recipient_type => 'EMAIL',
        :amount => {
          :value => amount.to_s,
          :currency => 'USD'
        },
        :note => "Dear #{self.user_info(user_id)["username"]},\n\n We have paid out your TreasureHunt account funds for a total of $#{amount}.",
        :receiver => self.user_info(user_id)["payment_info"],
        :sender_item_id => Time.now.to_i.to_s,
        }
      ]
      })
      begin
        resp = payout.create
        return true
      rescue ResourceNotFound => e
        return e.inspect
      end
     else
       return false
     end 
   end

  #
  # Get total amount of users
  #

  def self.user_count(options = {})
    if options[:platform] == 'ios'
      return @conn.exec("SELECT COUNT(id) FROM users WHERE platform='ios'")["count"][0]
    elsif options[:platform] == 'android'
      return @conn.exec("SELECT COUNT(id) FROM users WHERE platform='android'")["count"][0]
    else
      return @conn.exec("SELECT COUNT(id) FROM users")["count"][0]
    end
  end

  def self.admin?(user_id)
    return @conn.exec("SELECT * FROM users WHERE id=#{user_id}")[0]["is_admin"] == true
  end

end

