require "time"

module Datcord
  enum AuthenticationStatus
    NONE
    PENDING
    AUTHORIZED
  end

#  struct Token
#    property id, status, expireTime
#
#    def initialize(@id : String = "", @status : AuthenticationStatus = AuthenticationStatus::NONE, @expireTime : Time = Time.unix(0_u64))
#    end
#  end
end
