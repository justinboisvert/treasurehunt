#
# TreasureHunt backend 
#  
# REST collection of endpoints for TH application
#

require 'cuba'
require 'json'
require_relative 'user_control'
require_relative 'map_control'
require_relative 'session'

UserControl.start_db()
MapControl.start_db()

def float?(number)
  return number.to_f != 0
end

def int?(number)
  return number.to_i != 0
end

#
# Safe value, removes information that could break SQL statement
# and will parse out strings that aren't floats as 0.
#
def sv(value,type)
   if type == "float"
     if float?(value)
       return value.to_f
     else
       return 0
     end
   end
   if type == "int"
     if int?(value)
       return value.to_i
     else
       return 0
     end 
   end
   if type == "str"
     value = value.gsub("'","&apos;")
     return value
   end 
end

#
# Reverse safe value
#
def _sv(value,type)
  if type == "str"
    return value.gsub("&apos;","'")
  else
    return value
  end
end

#
# Takes a list of strings and returns a subset of the strings that contain special characters.
#
def has_special?(*args)
  words = []
  args.each do |arg|
     ["#","?","!","'",'"',"@","~","$","%","&","*","(",")","+"].each do |char|
       if !words.include?(arg) and arg.include?(char)
         words.push(arg)
       end
     end
  end
  return words
end

Cuba.define do 
  
  
  # /user/create
  
  # /user/delete
  
  # /user/modify
  
  # /map/create_prize

  # /map/delete_prize

  # /map/create_game

  # /map/delete_game

  # /map/play_response

   # POST /admin/prizes/create

  # POST /admin/prizes/:id/delete

  # GET /admin/games

  # POST /admin/games/:id/delete

  # POST /admin/games/create
  
  # PUT /admin/games/:id

  # PUT /admin/prizes/:id
 
  # GET /admin/user 

  on get do 
   on root do
     res.write("TH Backend V1")   
   end

  on "admin/games" do
     if env.key?("HTTP_SESSION") and Session.exists?(env["HTTP_SESSION"])
       user_id = Session.get_id(env["HTTP_SESSION"])
       if UserControl.admin?(user_id)
         res.write(JSON.pretty_generate({:error => false, :games => MapControl.all_games}))
       else
         res.status = 401
         res.write(JSON.pretty_generate({:error => true, :message => "Admin rights needed for this endpoint."}))
       end
     else
      res.status = 401
      res.write(JSON.pretty_generate({:error => true, :message => "No valid session key provided."}))
     end
   end
 
   on "users/:user_id" do |user_id|
     if env.key?("HTTP_SESSION") and Session.exists?(env["HTTP_SESSION"])
       user_id = Session.get_id(env["HTTP_SESSION"])
       info = UserControl.user_info(user_id)
       res.write(JSON.pretty_generate({:error => false}.merge(info)))
     else
       res.status = 401
       res.write(JSON.pretty_generate({:error => true, :message => "No valid session key provided."}))
     end
   end
   

   #
   # Return prizes from games
   #
   on "games/:game_id/prizes" do |game_id|
     if env.key?("HTTP_SESSION") and Session.exists?(env["HTTP_SESSION"])
       user_id = Session.get_id(env["HTTP_SESSION"])
       result = MapControl.prize_hints(game_id)
       res.write(JSON.pretty_generate({:error => false, :prizes => result}))
     else
       res.status = 401
       res.write(JSON.pretty_generate({:error => true, :message => "No valid session key provided."}))
      end
   end

   #
   # Returns state of how close you are to the current prize
   #

   on "games/:game_id/status" do |game_id|
       on param("latitude"), param("longitude") do |latitude,longitude|
          latitude = sv(latitude,"float")
          longitude = sv(longitude,"float")
          if env.key?("HTTP_SESSION") and Session.exists?(env["HTTP_SESSION"])
            user_id = Session.get_id(env["HTTP_SESSION"])
            result = MapControl.status(longitude,latitude)
           res.write(JSON.pretty_generate({:error => false}.merge(result)))
          else
            res.status = 401
           res.write(JSON.pretty_generate({:error => true, :message => "No valid session key provided."}))
           end
        end
   end

   #
   # Get information of current game in your location (title, description, etc)
   #
   
   on "games/:game_id" do |game_id|
    if env.key?("HTTP_SESSION") and Session.exists?(env["HTTP_SESSION"])
       user_id = Session.get_id(env["HTTP_SESSION"])
       game_info = MapControl.game_info(game_id)
       res.write(JSON.pretty_generate({:error => false}.merge(game_info)))    
     else
       res.status = 401
       res.write(JSON.pretty_generate({:error => true, :message => "No valid session key provided."}))
     end 
   end

   on "games" do
       on param("longitude"), param("latitude") do |longitude, latitude|
         if env.key?("HTTP_SESSION") and Session.exists?(env["HTTP_SESSION"])
           user_id = Session.get_id(env["HTTP_SESSION"])
           game_id = MapControl.game_within_location(sv(longitude,"float"),sv(latitude,"float"))
           if game_id != nil
             game_info = MapControl.game_info(game_id)
             res.write(JSON.pretty_generate({:error => false, :games => [game_info]}))
           else
             res.write(JSON.pretty_generate({:error => false, :games => []}))
           end    
         else
           res.status = 401
           res.write(JSON.pretty_generate({:error => true, :message => "No valid session key provided."}))
         end
     end
   end

  
   end
  
   
  on post do
   
    on "users/signup" do
      json_response = JSON.load(req.body.read)
      signup_request = json_response
      username = sv(signup_request["username"],"str")
      password = sv(signup_request["password"],"str")
      email = sv(signup_request["email"],"str")
        # to test later
        # sp = has_special?(username)
        # if sp.size > 0
        #   res.write(JSON.pretty_generate({:error => true, :message => "#{sp.join(", ")} does not allow special characters."}))
        # end
      if UserControl.username_exists?(username)
        res.status = 400
        res.write(JSON.pretty_generate({:error => true, :message => "Username already exists."}))
      else
        id = UserControl.create_user(:username => username, :password => password, :balance => 0, :email => email, :payment_info => "")
        session = Session.create(id)
        res.status = 201
        res.write(JSON.pretty_generate({:error => false, :session => session, :user => UserControl.user_info(id)}))
      end 
    end

   on "users/login" do
     json_response = JSON.load(req.body.read)
     login_request = json_response
     username = sv(login_request["username"],"str")
     password = sv(login_request["password"],"str")
     if UserControl.valid_userpass?(username,password)
       user_id = UserControl.id_by_username(username)
       session = Session.create(user_id)
       res.status = 201
       res.write(JSON.pretty_generate({:error => false, :session => session, :user => UserControl.user_info(user_id)}))
     else
       res.status = 400
       res.write(JSON.pretty_generate({:error => true, :message => "User/password combination does not exist."}))
     end
   end 

   on "users/logout" do
     if env.key?("HTTP_SESSION") and Session.exists?(env["HTTP_SESSION"])
       user_id = Session.get_id(env["HTTP_SESSION"])
       Session.delete(env["HTTP_SESSION"])
       res.status = 201
       res.write(JSON.pretty_generate({:error => false}))
     else
       res.status = 401
       res.write(JSON.pretty_generate({:error => true, :message => "No valid session key provided."}))
     end
   end

     on "games/:game_id/claim" do |game_id|
       on param("longitude"), param("latitude") do |longitude,latitude|
        latitude = sv(latitude,"float")
        longitude = sv(longitude,"float")
        if env.key?("HTTP_SESSION") and Session.exists?(env["HTTP_SESSION"])
          user_id = Session.get_id(env["HTTP_SESSION"])
          result = MapControl.claim(user_id,longitude,latitude)
          if result != false
            UserControl.increase_amount(user_id,result.to_i)
            info = UserControl.user_info(user_id)
            res.status = 201
            res.write(JSON.pretty_generate({:error => false, :amount => result}.merge(info)))
          else
            res.status = 400
            res.write(JSON.pretty_generate({:error => true, :message => "No prize to claim at that coordinate."}))
          end
        else
          res.status = 401
          res.write(JSON.pretty_generate({:error => true, :message => "No valid session key provided."}))
         end
        end
      end

      
     on "users/:user_id/redeem" do |user_id|
       if env.key?("HTTP_SESSION") and Session.exists?(env["HTTP_SESSION"])
         user_id = Session.get_id(env["HTTP_SESSION"])
         payment_info = UserControl.user_info(user_id)["payment_info"]
         if payment_info == nil or payment_info == ""
           res.status = 400
           res.write(JSON.pretty_generate({:error => true, :message => "Paypal address hasn't been set on account."}))
         end
         response = "Redeem not set yet"
         if response == true
           res.status = 201
           res.write(JSON.pretty_generate({:error => false}.merge(UserControl.user_info(user_id))))
         elsif response == false
           res.status = 400
           res.write(JSON.pretty_generate({:error => true, :message => "No funds to redeem."}))
         else
           res.status = 400
           res.write(JSON.pretty_generate({:error => true, :message => response}))
         end
       else
         res.status = 401
         res.write(JSON.pretty_generate({:error => true, :message => "No valid session key provided."}))
       end 
     end
     on "admin/prizes/create" do
      if env.key?("HTTP_SESSION") and Session.exists?(env["HTTP_SESSION"])
        user_id = Session.get_id(env["HTTP_SESSION"])
        if UserControl.admin?(user_id)
          json_response = JSON.load(req.body.read)
          longitude = sv(json_response["longitude"],"float")
          latitude = sv(json_response["latitude"],"float")
          amount = sv(json_response["amount"],"int")
          game_id = sv(json_response["game_id"],"int")
          hint = sv(json_response["hint"],"str")
          title = sv(json_response["title"],"str")  
          id = MapControl.create_prize(longitude,latitude,amount,game_id,hint,title)
          res.write(JSON.pretty_generate({:error => false, :id => id}))
        else
          res.status = 401
          res.write(JSON.pretty_generate({:error => true, :message => "Admin rights needed for this endpoint."}))
        end 
      else
         res.status = 401
         res.write(JSON.pretty_generate({:error => true, :message => "Not valid session key provided."}))
      end
    end

    on "admin/prizes/:id/delete" do |id|
      if env.key?("HTTP_SESSION") and Session.exists?(env["HTTP_SESSION"])
        user_id = Session.get_id(env["HTTP_SESSION"])
        if UserControl.admin?(user_id)
          json_response = JSON.load(req.body.read)
          id = MapControl.delete_prize(id)
          res.write({:error => false})
        else
          res.status = 401
          res.write(JSON.pretty_generate({:error => true, :message => "Admin rights needed for this endpoint."}))
        end 
      else
         res.status = 401
         res.write(JSON.pretty_generate({:error => true, :message => "Not valid session key provided."}))
      end
    end

    on "admin/games/create" do
      if env.key?("HTTP_SESSION") and Session.exists?(env["HTTP_SESSION"])
        user_id = Session.get_id(env["HTTP_SESSION"])
        if UserControl.admin?(user_id)
          json_response = JSON.load(req.body.read)
          longitude = sv(json_response["longitude"],"float")
          latitude = sv(json_response["latitude"],"float")
          radius = sv(json_response["radius"],"float")
          title = sv(json_response["title"],"str")
          description = sv(json_response["description"],"str") 
          id = MapControl.create_game(longitude,latitude,radius,title,description)
          res.write(JSON.pretty_generate({:error => false, :id => id}))
        else
          res.status = 401
          res.write(JSON.pretty_generate({:error => true, :message => "Admin rights needed for this endpoint."}))
        end 
      else
         res.status = 401
         res.write(JSON.pretty_generate({:error => true, :message => "Not valid session key provided."}))
      end
    end

    on "admin/games/:id/delete" do |id|
      if env.key?("HTTP_SESSION") and Session.exists?(env["HTTP_SESSION"])
        user_id = Session.get_id(env["HTTP_SESSION"])
        id = id.to_i
        if UserControl.admin?(user_id)
          MapControl.delete_game(id)
          res.write({:error => false})
        else
          res.status = 401
          res.write(JSON.pretty_generate({:error => true, :message => "Admin rights needed for this endpoint."}))
        end 
      else
         res.status = 401
         res.write(JSON.pretty_generate({:error => true, :message => "Not valid session key provided."}))
      end
    end
 

    end

   on put do
     on "users/:user_id" do |user_id|
      json_response = JSON.load(req.body.read)
      modifiers = json_response.keys
      bad_input = false
      modifiers.each do |modifier|
        if !["username","password","email","payment_info"].include?(modifier)
          bad_input = true
          res.status = 400
          res.write(JSON.pretty_generate({:error => true, :message => "Not a valid modifier option."}))
        end
      end
      if !bad_input
        if env.key?("HTTP_SESSION") and Session.exists?(env["HTTP_SESSION"])
          user_id = Session.get_id(env["HTTP_SESSION"])
          modifiers.each do |modifier|
            UserControl.modify_user(user_id,modifier,sv(json_response[modifier],"str"))
          end
          res.write(JSON.pretty_generate({:error => false}.merge(UserControl.user_info(user_id))))
        else
          res.status = 401
          res.write(JSON.pretty_generate({:error => true, :message => "No valid session key provided."}))
        end
      end
    end
 
  
   on "admin/games/:id" do |id|
      json_response = JSON.load(req.body.read)
      modifiers = json_response.keys.map { |k| [k,nil] }
      modifiers.each do |modifier|
        if modifiers[modifier].instance_of?(Integer)
          modifier[1] = "int"
        elsif modifiers[modifier].instance_of?(Float)
          modifier[1] = "float"
        else
          modifier[1] = "str"
        end 
      end
      if env.key?("HTTP_SESSION") and Session.exists?(env["HTTP_SESSION"])
        user_id = Session.get_id(env["HTTP_SESSION"])
        if UserControl.admin?(user_id)
          modifiers.each do |modifier|
            MapControl.modify_game(id,modifier[0],sv(json_response[modifier[0]],modifier[1]))
          end
          res.write(JSON.pretty_generate({:error => false}.merge(MapControl.game_info(id))))
        else
          res.status = 401
          res.write(JSON.pretty_generate({:error => true, :message => "Admin rights needed for this endpoint."}))
        end
      else
        res.status = 401
        res.write(JSON.pretty_generate({:error => true, :message => "No valid session key provided."}))
      end
    end

    on "admin/prizes/:id" do |id|
      json_response = JSON.load(req.body.read)
      modifiers = json_response.keys.map { |k| [k,nil] }
      modifiers.each do |modifier|
        if json_response[modifier[0]].instance_of?(Integer)
          modifier[1] = "int"
        elsif json_response[modifier[0]].instance_of?(Float)
          modifier[1] = "float"
        else
          modifier[1] = "str"
        end 
      end
      if env.key?("HTTP_SESSION") and Session.exists?(env["HTTP_SESSION"])
        user_id = Session.get_id(env["HTTP_SESSION"])
        if UserControl.admin?(user_id)
          modifiers.each do |modifier|
            MapControl.modify_prize(id,modifier[0],sv(json_response[modifier[0]],modifier[1]))
          end
          res.write(JSON.pretty_generate({:error => false}))
        else
          res.status = 401
          res.write(JSON.pretty_generate({:error => true, :message => "Admin rights needed for this endpoint."}))
        end
      else
        res.status = 401
        res.write(JSON.pretty_generate({:error => true, :message => "No valid session key provided."}))
      end
    end



   end   
  
end
