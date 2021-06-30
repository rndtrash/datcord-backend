require "random/secure"

require "./constants.cr"

module Datcord::Utils
  extend self

  def random_string(n : Int = Datcord::TOKEN_LENGTH) : String
    Random::Secure.urlsafe_base64(n, padding: false)[0, n]
  end

  def random_number_string(n : Int = 4) : String
    result = ""
    i = 0
    loop do
      result += Random::Secure.rand(10).to_s
      i += 1
      break if i == n
    end
    result
  end
end
