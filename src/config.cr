# Application dependencies
require "action-controller"
require "active-model"
require "./constants"

# Application code
require "./controllers/application"
require "./controllers/*"
require "./models/*"

# Server required after application controllers
require "action-controller/server"

# Configure logging (backend defined in constants.cr)
if Datcord.running_in_production?
  log_level = Log::Severity::Info
  ::Log.setup "*", :warn, Datcord::LOG_BACKEND
else
  log_level = Log::Severity::Debug
  ::Log.setup "*", :info, Datcord::LOG_BACKEND
end
Log.builder.bind "action-controller.*", log_level, Datcord::LOG_BACKEND
Log.builder.bind "#{Datcord::NAME}.*", log_level, Datcord::LOG_BACKEND

# Filter out sensitive params that shouldn't be logged
filter_params = ["token", "token_proof"]
keeps_headers = ["X-Request-ID"]

# Add handlers that should run before your application
ActionController::Server.before(
  ActionController::ErrorHandler.new(Datcord.running_in_production?, keeps_headers),
  ActionController::LogHandler.new(filter_params),
  HTTP::CompressHandler.new
)
