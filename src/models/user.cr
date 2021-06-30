require "moongoon"

class User < Moongoon::Collection
  collection "users"

  index keys: {_id: 1, public_key: 1}, options: {unique: true}

  property public_key : String
  property name : String
  property profile_picture : String?
  property status : String? # TODO: make a status struct with a standart or custom emoticon and a text
end
