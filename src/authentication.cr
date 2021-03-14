require "uuid"
require "base64"

require "redis"
require "openssl_ext"

require "./models/authentication"
require "./utils.cr"
require "./constants"

module Datcord::Authentication
  extend self

  def token_exists(redis : Redis::PooledClient, token : String) : Bool
    token_db_key = "t.#{token}"
    redis.exists(token_db_key) == 1 && redis.ttl(token_db_key) > 0
  end

  def token_status(redis : Redis::PooledClient, token : String) : Datcord::AuthenticationStatus
    return Datcord::AuthenticationStatus::NONE unless token_exists(redis, token)

    token_db_key = "t.#{token}"
    case redis.hget(token_db_key, "status")
    when "0"
      Datcord::AuthenticationStatus::PENDING
    when "1"
      Datcord::AuthenticationStatus::AUTHORIZED
    else
      Datcord::AuthenticationStatus::NONE
    end
  end

  def new_token(redis : Redis::PooledClient, public_key : String) : (String | Nil)
    return nil unless (Datcord::RSA_MINIMAL_PKEY_SIZE..Datcord::RSA_MAXIMAL_PKEY_SIZE).includes?(public_key.size)

    token = Datcord::Utils.random_string
    token_db_key = "t.#{token}"

    redis.hset(token_db_key, "public_key", public_key)
    redis.hset(token_db_key, "status", "0")
    redis.expire(token_db_key, 15) # 15 seconds to approve token

    # TODO: encrypt token with public key
    pkey = nil
    begin
      pkey = OpenSSL::RSA.new("-----BEGIN PUBLIC KEY-----\n#{public_key}\n-----END PUBLIC KEY-----", nil, false)
    rescue exception
      return nil
    end
    Base64.strict_encode pkey.public_encrypt token
  end

  def approve_token(redis : Redis::PooledClient, token : String) : Int64
    token_db_key = "t.#{token}"

    if redis.ttl(token_db_key) > 0
      redis.hset(token_db_key, "status", "1")
      renew_token(redis, token)
    end

    redis.ttl(token_db_key)
  end

  def renew_token(redis : Redis::PooledClient, public_key : String) : Int64
    return -2_i64 unless token_exists(redis, public_key)

    token_db_key = "t.#{public_key}"
    redis.expire(token_db_key, Datcord::TOKEN_RENEWAL_PERIOD)
    redis.ttl(token_db_key)
  end

  def token_get_pkey(redis : Redis::PooledClient, token : String) : (String | Nil)
    return nil unless token_exists(redis, token)

    redis.hget(token, "public_key")
  end

  def delete_token(redis : Redis::PooledClient, token : String) : Bool
    return false unless token_exists(redis, token)

    redis.del(token)
    true
  end
end
