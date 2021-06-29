require "redis"
require "../authentication"

class ApiV1 < Application
  base "/v1"

  get "/ping" do
    respond_with do
      json({status: "ok"})
    end
  end

  get "/auth" do
    if request.query_params.has_key?("token")
      Log.info { "token" }
      token = request.query_params["token"]
      if token.size == 0
        respond_with do
          json({status: "error"})
        end
      end
      case Datcord::Authentication.token_status(@@redis, token)
      when Datcord::AuthenticationStatus::PENDING
        Log.info { "pending" }
        ttl = Datcord::Authentication.approve_token(@@redis, token)
        respond_with do
          if ttl <= 0
            json({status: "error"})
          else
            json({status: "ok", timeUntilUpdate: ttl})
          end
        end
      when Datcord::AuthenticationStatus::AUTHORIZED
        Log.info { "authorised" }
        respond_with do
          json({status: "ok"})
        end
      end
      respond_with do
        json({status: "error"})
      end
    elsif request.query_params.has_key?("public_key")
      Log.info { "public_key" }
      token = Datcord::Authentication.new_token(@@redis, request.query_params["public_key"])
      Log.info { token }
      respond_with do
        if token.nil?
          json({status: "error"})
        else
          json({status: "ok", token: token})
        end
      end
    else
      respond_with do
        json({status: "error"})
      end
    end
  end

  get "/deauth" do
    respond_with { json({status: "ok"}) } if request.headers["AuthenticationStatus"] == Datcord::AuthenticationStatus::AUTHORIZED.to_i.to_s && Datcord::Authentication.delete_token(@@redis, request.query_params["token"])

    respond_with { json({status: "error"}) }
  end
end
