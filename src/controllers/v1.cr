require "redis"
require "../authentication"

class ApiV1 < Application
  base "/v1"

  # def index
  #   respond_with do
  #     text "gtfo"
  #   end
  # end

  get "/ping" do
    respond_with do
      json({status: "ok"})
    end
  end

  get "/auth" do
    if request.query_params.has_key?("token")
      token = request.query_params["token"]
      if token.size == 0
        respond_with do
          json({status: "error"})
        end
      end
      case Datcord::Authentication.token_status(@redis, token)
      when Datcord::AuthenticationStatus::PENDING
        ttl = Datcord::Authentication.approve_token(@redis, token)
        respond_with do
          if ttl <= 0
            json({status: "error"})
          else
            json({status: "ok", timeUntilUpdate: ttl})
          end
        end
      when Datcord::AuthenticationStatus::AUTHORIZED
        ttl = Datcord::Authentication.renew_token(@redis, token)
        respond_with do
          if ttl <= 0
            json({status: "error"})
          else
            json({status: "ok", timeUntilUpdate: ttl})
          end
        end
      end
    else
      if request.query_params.has_key?("public_key")
        token = Datcord::Authentication.new_token(@redis, request.query_params["public_key"])
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
  end

  get "/deauth" do
    respond_with { json({status: "error"}) } unless request.query_params.has_key?("token") && Datcord::Authentication.delete_token(@redis, request.query_params["token"])

    respond_with { json({status: "ok"}) }
  end
end
