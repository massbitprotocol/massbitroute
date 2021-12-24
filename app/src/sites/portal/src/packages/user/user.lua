local ngx, cc = ngx, cc
local User = cc.class("User")
local crypto = require "crypto"

local model_type = "user"
local Model = cc.import("#model")
local util = cc.import("#mbrutil")

function User:ctor(instance)
    self._instance = instance
    self._redis = instance:getRedis()
    self._model = Model:new(instance)
end

function User:login(args)
    local _id = self._model:_get_key(model_type .. ":name", args.username)
    if not _id then
        return nil, "username not found"
    end
    local _now = ngx and ngx.time() or os.time()
    args.updated_at = _now

    local _user = self._model:_getall_key(model_type .. ":" .. _id)

    if _user.password_hash ~= crypto.passwordKey(args.password, _user.password_salt) then
        return nil, "wrong password"
    end
    return _user
end

function User:register(args)
    local _id = self._model:_get_key(model_type .. ":name", args.username)
    if _id then
        return nil, "username exists"
    end

    local password = args.password
    local _hash, _salt = crypto.passwordKey(password)

    local _now = ngx and ngx.time() or os.time()

    args.id = util.get_uuid(_now)

    args.created_at = _now
    args.password = nil
    args.password_hash = _hash
    args.password_salt = _salt
    self._model:save(model_type, args)
    self._model:_save_key(model_type .. ":name", {[args.username] = args.id})
    return args
end

return User
