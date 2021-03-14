require "action-controller/logger"
require "secrets-env"
require "dotenv"

Dotenv.load

module Datcord
  NAME    = "Datcord (Crystal)"
  VERSION = {{ `shards version "#{__DIR__}"`.chomp.stringify.downcase }}

  Log         = ::Log.for(NAME)
  LOG_BACKEND = ActionController.default_backend

  ENVIRONMENT = ENV["ENV"]? || "development"

  DEFAULT_PORT          = (ENV["DC_SERVER_PORT"]? || 8579).to_i
  DEFAULT_HOST          = ENV["DC_SERVER_HOST"]? || "127.0.0.1"
  DEFAULT_PROCESS_COUNT = (ENV["DC_PROCESS_COUNT"]? || 1).to_i

  RSA_MINIMAL_PKEY_SIZE = 1024 / 8
  RSA_MAXIMAL_PKEY_SIZE = 2048 / 8
  TOKEN_RENEWAL_PERIOD  = ENV["DC_TOKEN_RENEWAL_PERIOD"]
  TOKEN_LENGTH          = 24

  REDIS_URI             = ENV["DC_REDIS_URI"]

  def self.running_in_production?
    ENVIRONMENT == "production"
  end
end
