require "uuid"
require "redis"
require "cryomongo"
require "../constants"
require "../authentication"

abstract class Application < ActionController::Base
  # Configure your log source name
  # NOTE:: this is chaining from App::Log
  Log = ::Datcord::Log.for("controller")

  @@redis = Redis::PooledClient.new(url: Datcord::REDIS_URI)
  @@mongo = Mongo::Client.new(Datcord::MONGO_URI)
  @@mongodb : Mongo::Database = @@mongo.default_database.not_nil!

  before_action :rate_limit
  before_action :set_request_id
  before_action :set_date_header
  before_action :is_authenticated

  def rate_limit
    key = "ip.#{request.remote_address}"
    incr = @@redis.incr(key)
    @@redis.expire(key, 30)
    return if incr <= Datcord::RATE_LIMIT_PER_30S
    response.headers["Rate-Limited"] = "1"
    respond_with do
      text ""
    end
  end

  # This makes it simple to match client requests with server side logs.
  # When building microservices this ID should be propagated to upstream services.
  def set_request_id
    request_id = UUID.random.to_s
    Log.context.set(
      client_ip: client_ip,
      request_id: request_id
    )
    response.headers["X-Request-ID"] = request_id

    # If this is an upstream service, the ID should be extracted from a request header.
    # request_id = request.headers["X-Request-ID"]? || UUID.random.to_s
    # Log.context.set client_ip: client_ip, request_id: request_id
    # response.headers["X-Request-ID"] = request_id
  end

  def set_date_header
    response.headers["Date"] = HTTP.format_time(Time.utc)
  end

  def is_authenticated
	request.headers["AuthenticationStatus"] = Datcord::AuthenticationStatus::NONE.to_i.to_s # well shit
	return unless request.query_params.has_key?("token")
	token = request.query_params["token"]
	return if token.size == 0
	ts = Datcord::Authentication.token_status(@@redis, token)
	return if ts == Datcord::AuthenticationStatus::NONE
	request.headers["AuthenticationStatus"] = ts.to_i.to_s
	return if ts != Datcord::AuthenticationStatus::AUTHORIZED
	response.headers["TimeUntilTokenExpire"] = Datcord::Authentication.renew_token(@@redis, token).to_s
  end
end
