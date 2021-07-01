require "moongoon"
require "redis"

# FIXME: need limits for stuff

class User < Moongoon::Collection
  collection "users"

  index keys: {public_key: 1}, options: {unique: true}

  property public_key : String
  property name : String
  property profile_picture : String?
  property status : String? # TODO: make a status struct with a standart or custom emoticon and a text

  def self.find_by_token(redis : Redis::PooledClient, token : String) : User?
    uid = Datcord::Authentication.token_get_user(redis, token)
    return nil if uid.nil?

    find_by_id(redis, uid)
  end

  def self.find_by_public_key(redis : Redis::PooledClient, public_key : String) : User?
    User.find_one({public_key: public_key})
  end

  def self.find_by_id(redis : Redis::PooledClient, id : String) : User?
    User.find_one({_id: BSON::ObjectId.new(id)})
  end

  def to_tuple(is_owner : Bool = false)
    if is_owner
      # TODO: show more info to the profile owner, like all the guild associated with it
      {
        id:              self._id.to_s,
        public_key:      self.public_key,
        name:            self.name,
        profile_picture: self.profile_picture,
        status:          self.status,
      }
    else
      {
        id:              self._id.to_s,
        public_key:      self.public_key,
        name:            self.name,
        profile_picture: self.profile_picture,
        status:          self.status,
      }
    end
  end
end
