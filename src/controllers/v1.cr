require "redis"
require "bson"
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
        if ttl < 1
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
    respond_with { json({status: "error"}) } if request.headers["AuthenticationStatus"] != Datcord::AuthenticationStatus::AUTHORIZED.to_i.to_s

    u = User.find_by_token(@@redis, request.query_params["token"])
    respond_with { json({status: "error"}) } if u.nil?

    is_dirty = false

    if request.query_params.has_key?("name")
      u.name = request.query_params["name"]
      is_dirty = true
    end

    if request.query_params.has_key?("profile_picture")
      # TODO: profile picture upload
      is_dirty = true
    end

    if request.query_params.has_key?("status")
      s = request.query_params["status"]
      if s.size == 0
        u.status = nil
      else
        u.status = s
      end
      is_dirty = true
    end

    if is_dirty
      u.update
      respond_with { json(u.to_tuple(true)) }
    else
      respond_with { json({status: "error"}) }
    end
  end

  get "/user" do
    respond_with { json({status: "error"}) } if request.headers["AuthenticationStatus"] != Datcord::AuthenticationStatus::AUTHORIZED.to_i.to_s

    u : User?
    is_owner = false
    if request.query_params.has_key?("public_key")
      u = User.find_by_public_key(@@redis, request.query_params["public_key"])
    elsif request.query_params.has_key?("id")
      u = User.find_by_id(@@redis, request.query_params["id"])
    else
      u = User.find_by_token(@@redis, request.query_params["token"])
      is_owner = true
    end

    respond_with { json({status: "error"}) } if u.nil?

    respond_with { json(u.to_tuple(is_owner)) }
  end

  delete "/user" do
    respond_with { json({status: "error"}) } if request.headers["AuthenticationStatus"] != Datcord::AuthenticationStatus::AUTHORIZED.to_i.to_s

    token = request.query_params["token"]
    u = User.find_by_token(@@redis, token)
    respond_with { json({status: "error"}) } if u.nil?

    Datcord::Authentication.delete_token(@@redis, token)
    u.remove
    respond_with { json({status: "ok"}) }
  end
end
