require "redis"
require "../authentication"

class ApiV1 < Application
  base "/v1"

  def index
    respond_with do
      text "gtfo"
    end
  end

  get "/ping" do
    respond_with do
      json({status: "ok"})
    end
  end

  get "/auth" do
    if !request.query_params.has_key?("public_key")
      respond_with do
        json({status: "error"})
      end
    end
    public_key = request.query_params["public_key"]
    case Datcord::Authentication.token_status(@redis, public_key)
    when Datcord::AuthenticationStatus::PENDING
      if !request.query_params.has_key?("secret")
        respond_with do
          json({status: "error"})
        end
      end
      ttl = Datcord::Authentication.approve_token(@redis, public_key, request.query_params["secret"])
      respond_with do
        if ttl <= 0
          json({status: "error"})
        else
          json({status: "ok", timeUntilUpdate: ttl})
        end
      end
    when Datcord::AuthenticationStatus::AUTHORIZED
      ttl = Datcord::Authentication.renew_token(@redis, public_key)
      respond_with do
        if ttl <= 0
          json({status: "error"})
        else
          json({status: "ok", timeUntilUpdate: ttl})
        end
      end
    else
      secret = Datcord::Authentication.new_token(@redis, public_key)
      respond_with do
        if secret.nil?
          json({status: "error"})
        else
          json({status: "ok", secret: secret})
        end
      end
    end
  end
end
