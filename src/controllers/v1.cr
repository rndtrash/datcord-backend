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
        if ttl <= 0
          respond_with { json({status: "error"}) }
        end

        public_key = Datcord::Authentication.token_get_pkey(@@redis, token)
        Log.info { "looking for user..." }
        u = User.find_one({public_key: public_key})
        if u.nil?
          Log.info { "no user found, making one..." }
          u = User.new(public_key: public_key, name: "Guest#{Datcord::Utils.random_number_string}").insert
        end
        Log.info { "#{u.id} #{User.count}" }
        Datcord::Authentication.token_set_user(@@redis, token, u._id.not_nil!.to_s)

        respond_with do
          json({status: "ok"})
        end
      when Datcord::AuthenticationStatus::AUTHORIZED
        Log.info { "authorized" }
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

  post "/user" do
    return if request.headers["AuthenticationStatus"] != Datcord::AuthenticationStatus::AUTHORIZED.to_i.to_s

    # TODO: make a user profile
  end

  get "/user" do
    return if request.headers["AuthenticationStatus"] != Datcord::AuthenticationStatus::AUTHORIZED.to_i.to_s

    if request.query_params.has_key?("public_key")
      #
    end

    if request.query_params.has_key?("id")
      #
    end

    # TODO: return user's profile by his token
  end
end
