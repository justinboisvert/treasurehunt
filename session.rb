#!/usr/bin/env ruby
#
# Session manager for TreasureHunt
#
require 'redis'
require 'securerandom'
module Session
  REDISHOST = “”
  REDISPASS = “”
  EXPIRE_DAYS = 4
  @@rd_client = Redis.new(host: REDISHOST, password: REDISPASS)
  
  def self.create(id)
    sess = SecureRandom.hex(50)
    @@rd_client.set(sess,id)
    @@rd_client.expire(sess,EXPIRE_DAYS*24*60*60)
    return sess
  end

  def self.exists?(session)
    return @@rd_client.get(session) != nil
  end

  def self.get_id(session)
    return @@rd_client.get(session).to_i
  end

  def self.delete(session)
    @@rd_client.del(session)
  end
end
