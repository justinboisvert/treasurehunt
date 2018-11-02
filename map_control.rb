#!/usr/bin/env ruby
#
# Mapping system for creating and deleting game regions where a user can grab prizes

require 'pg'
require 'geocoder'

module MapControl
  DBNAME = “”
  DBUSER = “”
  DBPASS = “”
  DBHOST = “”
  def self.start_db()
    @conn = PG::Connection.open(:dbname => DBNAME, :user => DBUSER, :password => DBPASS, :host => DBHOST)
    @conn.type_map_for_results = PG::BasicTypeMapForResults.new(@conn)
  end

  # Given a set of coordinates determine whether or not
  # they are in the vincinity of a prize (<= 10in) and if not
  # give vague nomenclature of the prize distance/status of game.
  # 
  # NO_CURRENT_GAME
  # 
  # SOMETHING
  #
  # MELLOW
  # 
  # WARM
  #
  # SPICY
  # 
  # VERY CLOSE
  #
  # RECEIVED
   def self.status(longitude,latitude)
    game_id = self.game_within_location(longitude,latitude)
    no_game = {:proximity => "No Game", :color => "#2c3e50", :radius => 0, :is_claimable => false}
    if game_id != nil
      statusMap = {
        "Cool" => ["#3498db",self.game_info(game_id)["radius"],false],
        "Lukewarm" => ["#1abc9c",3*1609.34,false],
        "Warm" => ["#e67e22",2*1609.34,false],
        "Hot" => ["#d35400",1*1609.34,false],
        "Red Hot" => ["#c0392b",0.5*1609.34,false],
        "Claim" => ["#f1c40f",0.0094697*1609.34,true]
      }
      prize_data = self.closest_prize(game_id,longitude,latitude)
      if prize_data[0] != nil
        proximity = self.map_status(prize_data[1])
        return {:proximity => proximity, :color => statusMap[proximity][0], :radius => statusMap[proximity][1], :is_claimable => statusMap[proximity][2]}
      else
        return no_game
      end
    else
      return no_game
    end
  end
  
  #
  # Claim a prize within coordinate if prize is claimable. 
  # 
  def self.claim(user_id,longitude,latitude)
    game_id = self.game_within_location(longitude,latitude)
    if game_id != nil
      prize_data = self.closest_prize(game_id, longitude, latitude)
      if prize_data[0] != nil
        status = self.map_status(prize_data[1])
        if status == "Claim"
          self.claim_prize(prize_data[0]["id"],user_id)
          return prize_data[0]["amount"]
        else
          return false
        end
      else
        return false
      end
    else
      return false
    end
  end
  
  #
  # Closest prize within game id given coordinates
  #
  def self.closest_prize(game_id,longitude,latitude)
    # Get the prize in the game that is the closest to coordinate to work with radar
    prizes = claimable_prizes_from_game(game_id)
    closest_prize = nil
    closest_distance = nil
    prizes.each do |row|
      distance = Geocoder::Calculations::distance_between([latitude,longitude],[row["latitude"],row["longitude"]], :units => :mi)
      if !closest_distance || distance < closest_distance
        closest_prize = row
        closest_distance = distance
      end 
    end
    return [closest_prize, closest_distance]
  end

  # Distance (in miles) status nomenclature to be returned back for radar.
  def self.map_status(distance)
    # Grab current game in location (if there is any)
    if 0.0094697 >= distance
      return "Claim"
    elsif 0.5 >= distance and distance > 0.0094697
      return "Red Hot"
    elsif 1 >= distance and distance > 0.5 
      return "Hot"
    elsif 2 >= distance and distance > 1
      return "Warm"
    elsif 3 >= distance and distance > 2
      return "Lukewarm"
    else
      return "Cool" 
    end
  end #f1c40f
 
  #
  # Delete prize from map
  #
  def self.claim_prize(prize_id,user_id)
    @conn.exec("UPDATE prizes SET claimaint_id=#{user_id} WHERE id=#{prize_id}")
    @conn.exec("UPDATE prizes SET is_claimed=true WHERE id=#{prize_id}")
  end
 
  #
  # Delete game
  #
  def self.delete_game(game_id)
    @conn.exec("DELETE FROM game_locations WHERE id=#{game_id}")
  end 

  #
  # Get local prizes in current game zone if there is any
  #
  def self.prizes_from_game(game_id)
    return @conn.exec("SELECT * FROM prizes WHERE game_location='#{game_id}'") 
  end

  #
  # Get claimable prizes in game zone
  #
  def self.claimable_prizes_from_game(game_id)
    return @conn.exec("SELECT * FROM prizes WHERE game_location='#{game_id}' AND is_claimed=false")
  end
  #
  # Create game and return its id
  #
  def self.create_game(longitude,latitude,radius,title,description)
    @conn.exec("INSERT INTO game_locations(latitude,longitude,radius,title,description,is_active) VALUES (#{latitude},#{longitude},#{radius},'#{title}','#{description}',true)")
    res = @conn.exec("SELECT * FROM game_locations WHERE latitude=#{latitude} AND longitude=#{longitude}")
    return res[0]["id"]
  end
  #
  # Create prize and return its id  
  #
  def self.create_prize(longitude,latitude,amount,game_id,hint,title)
    @conn.exec("INSERT INTO prizes(game_location,latitude,longitude,amount,hint,claimaint_id,is_claimed,title) VALUES (#{game_id},#{latitude},#{longitude},#{amount},'#{hint}',null,false,'#{title}')")
    res = @conn.exec("SELECT * FROM prizes WHERE latitude=#{latitude} AND longitude=#{longitude}")
    return res[0]["id"]
  end

  #
  # Delete prize
  #
  def self.delete_prize(game_id)
    @conn.exec("DELETE FROM prizes WHERE id=#{game_id}")
  end 

  #
  # Get list of hints for game in area
  #

  def self.prize_hints(game_id)
    if game_id != nil
      prizes = prizes_from_game(game_id)
      hints = []
      prizes.each do |row|
        hints.push({"id" => row["id"], "hint" => row["hint"], "is_claimed" => row["is_claimed"], "amount" => row["amount"], "title" => row["title"]})
      end
      return hints
    else
      return []
    end
  end

  #
  # Return a game ID that's in the provided location
  #
  def self.game_within_location(longitude,latitude)
    res = @conn.exec("SELECT * FROM game_locations WHERE ST_DWithin(ST_POINT(longitude, latitude),ST_POINT(#{longitude},#{latitude}),radius,false)")
    id = nil
    res.each do |row|
      id = row["id"]
    end
    return id
  end

  #
  # Check if there is a game with ID supplied
  #
  def self.game_exists?(game_id)
    res = @conn.exec("SELECT COUNT(id) FROM game_locations WHERE id=#{game_id}")
    return res[0]["count"] != 0
  end
  
  #
  # Return game hash information
  #
  def self.game_info(game_id)
    if self.game_exists?(game_id)
      res = @conn.exec("SELECT * FROM game_locations WHERE id=#{game_id}")
      fields = res.fields
      game_dict = {}
      game_dict["center"] = {}
      res.each do |row|
        fields.each do |field|
          if field == "latitude" or field == "longitude"
            game_dict["center"][field] = row[field]
          else
            game_dict[field] = row[field]
          end
        end
      end
      return game_dict
    else
      retun nil
    end
  end

  def self.all_games()
    res = @conn.exec("SELECT * FROM game_locations")
    games = []
    res.each do |row|
      games.push(game_info(row["id"]))
    end
    return games
  end

  def self.modify_game(game_id,modifier,value)
    if value.instance_of?(String)
      @conn.exec("UPDATE game_locations SET #{modifier}='#{value}' WHERE id=#{game_id}")
    else
      @conn.exec("UPDATE game_locations SET #{modifier}=#{value} WHERE id=#{game_id}")
    end   
  end
 
  def self.modify_prize(game_id,modifier,value)
    if value.instance_of?(String)
      @conn.exec("UPDATE prizes SET #{modifier}='#{value}' WHERE id=#{game_id}")
    else
      @conn.exec("UPDATE prizes SET #{modifier}=#{value} WHERE id=#{game_id}")
    end   
  end

end
