require "moongoon"

class Message < Moongoon::Collection
    collection "messages"

    index keys: { _id: 1, time: 1 }

    property author : User
    property message : String
    property time : Int64
    property last_edit_time : Int64?
    # embed
    # reactions
end
