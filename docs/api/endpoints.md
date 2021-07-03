# API endpoints

## Notes

- When authorized, every request you make bumps your TimeUntilTokenExpire
- \*Every endpoint that requires authorization has public_key argument ([More](#get-auth))

## /v1

### GET /ping

Description: needs no introduction.

Access: everyone

Arguments: none

Response: `{"status":"ok"}` if the server works. Nothing if shit happened.

### GET /auth

#### **Phase: not authorized**

Description: log in by supplying public key. If the user does not provide a decrypted key in 15 seconds token becomes invalid.

Access: everyone

Arguments:

_Query:_
|key|description|
|---|-----------|
|public_key|Pulbic key of the user (RSA 1024 or 2048 bits in Base64 format with newlines) (TODO: not final!)|

Response:

If anything had gone wrong:

```json
{
	"status": "error"
}
```

If the public key was accepted:

```json
{
	"status": "ok",
	"token": "" // user's token as a String encrypted with given public key
}
```

#### **Phase: got encrypted token**

Description: proof the ownage of private key by decrypting a token encrypted with public key. Creates a user profile if the public key owner does not have one.

Access: those who got the token from the first phase

Arguments:

_Query:_
|key|description|
|---|-----------|
|token|Decrypted token from the response of previous phase|

Response:

If anything had gone wrong:

```json
{
	"status": "error"
}
```

If the token was accepted:

_Body:_

```json
{
	"status": "ok"
}
```

_Headers:_
|header|description|
|------|-----------|
|TimeUntilTokenExpire|Time until token expires (duh) in seconds; will appear after every request you make as long as you're logged in|

#### **Phase: authorized**

Description: does nothing.

### GET /deauth

Description: logs off the user.

Access: authorized

Arguments: none\*

Response:

If you're not logged in:

```json
{
	"status": "error"
}
```

If you've logged off successfully:

```json
{
	"status": "ok"
}
```

### GET /user

#### **Get user's own profile**

Description: get user's own profile.

Access: authorized

Arguments: none\*

Response:

If anything had gone wrong:

```json
{
	"status": "error"
}
```

If the user profile was retrieved successfully:

[User](resources/user.md) in JSON as owner

#### **Get profile by ID or public key**

Description: get profile of any user by ID or public key.

Access: authorized

Arguments:

_Query:_

At least one of these:
|key|description|
|---|-----------|
|public_key|Public key|
|id|ID|

If both are supplied, public_key is used.

Response:

If anything had gone wrong:

```json
{
	"status": "error"
}
```

If the user profile was retrieved successfully:

[User](resources/user.md) in JSON

### POST /user

Description: changes user's profile.

Access: authorized

Arguments:

_Query:_

Any field from [User](resources/user.md) except profile picture

TODO: describe how to upload the profile picture

Response:

If anything had gone wrong:

```json
{
	"status": "error"
}
```

If the operation was successful:

[User](resources/user.md) in JSON as owner

### DELETE /user

Description: deletes user's profile and logs them off.

Access: authorized

Arguments: none\*

Response:

If anything had gone wrong:

```json
{
	"status": "error"
}
```

If the profile was removed successfully:

```json
{
	"status": "ok"
}
```
