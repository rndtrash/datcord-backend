require "random/secure"

require "./constants.cr"

module Datcord::Utils
  extend self

  def random_string(n : Int = Datcord::TOKEN_LENGTH) : String
    Random::Secure.urlsafe_base64(n, padding: false)[0, n]
  end
end
