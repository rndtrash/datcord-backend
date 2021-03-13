require "uuid"
require "redis"

require "./models/authentication"
require "./constants"

module Datcord::Authentication
    extend self

    def token_exists(redis : Redis::PooledClient, public_key : String) : Bool
        token_string = "token.#{public_key}"
        redis.exists(token_string) == 1 && redis.ttl(token_string) > 0
    end

    def token_status(redis : Redis::PooledClient, public_key : String) : Datcord::AuthenticationStatus
        return Datcord::AuthenticationStatus::NONE unless token_exists(redis, public_key)
        token_string = "token.#{public_key}"
        case redis.hget(token_string, "status")
        when "0"
            Datcord::AuthenticationStatus::PENDING
        when "1"
            Datcord::AuthenticationStatus::AUTHORIZED
        else
            Datcord::AuthenticationStatus::NONE
        end
    end

    # def get_token(redis : Redis::PooledClient, public_key : String) : (Token | Nil)
    #     return nil unless token_exists(redis, public_key)

    #     token = Token.new
    #     token_string = "token.#{token}"

    #     token.public_key = public_key
    #     case redis.hget(token_string, "status")
    #     when "0"
    #         token.status = Datcord::AuthenticationStatus::PENDING
    #     when "1"
    #         token.status = Datcord::AuthenticationStatus::AUTHORIZED
    #     else
    #         token.status = Datcord::AuthenticationStatus::NONE
    #     end

    #     tempExpireTime = redis.ttl(token_string)
    #     return nil if tempExpireTime <= 0
    #     token.expireTime = Time.unix(Time.utc.to_unix + tempExpireTime)

    #     return token
    # end

    def new_token(redis : Redis::PooledClient, public_key : String) : String
        token_string = "token.#{public_key}"

        secret = UUID.random.to_s
        redis.hset(token_string, "proofString", secret)
        redis.hset(token_string, "status", "0")
        redis.expire(token_string, 30) # 30 seconds to approve token

        # TODO: encrypt secret with public key
        secret
    end

    def approve_token(redis : Redis::PooledClient, public_key : String, secret : String) : Int64
        token_string = "token.#{public_key}"

        if secret == redis.hget(token_string, "proofString")
            redis.hset(token_string, "status", "1")
            renew_token(redis, public_key)
        else
            redis.del(token_string)
        end

        redis.ttl(token_string)
    end

    def renew_token(redis : Redis::PooledClient, public_key : String) : Int64
      return -2_i64 unless token_exists(redis, public_key)
      token_string = "token.#{public_key}"
      redis.expire(token_string, Datcord::TOKEN_RENEWAL_PERIOD)
      redis.ttl(token_string)
    end
end
