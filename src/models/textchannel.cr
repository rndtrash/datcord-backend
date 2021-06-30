require "moongoon"

class TextChannel < Moongoon::Document
    property name : String
    property description : String
    property messages : Array(Message)
    property pinned_messages : Array(Message)?
end
