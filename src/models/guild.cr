require "moongoon"

class Guild < Moongoon::Collection
  collection "guilds"

  property name : String
  property users : Array(User)
  # roles
  property channels : Array(TextChannel) # channels : Array(VoiceChannel | TextChannel | Category)
  property owner : User
end
