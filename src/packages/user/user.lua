local ngx, cc = ngx, cc
local User = cc.class("User")
local crypto = require "crypto"

local model_type = "user"
local Model = cc.import("#model")
local util = require "mbutil" -- cc.import("#mbrutil")
local json = cc.import("#json")

local _print = util.print
local inspect = require "inspect"

function User:ctor(instance)
    self._instance = instance
    self._redis = instance:getRedis()
    self._model = Model:new(instance)
end

function User:login(args)
    _print(inspect(args))

    local _id = self._model:_get_key(model_type .. ":name", args.username)
    _print(inspect(_id))
    if not _id then
        return nil, "username not found"
    end
    local _now = ngx and ngx.time() or os.time()
    args.updated_at = _now

    local _user = self._model:_get_key(model_type, _id)
    if _user then
        _user = json.decode(_user)
    end

    _print(inspect(_user))
    if not _user.confirmed then
        return nil, "Account not confirmed"
    end

    if _user.password_hash ~= crypto.passwordKey(args.password, _user.password_salt) then
        return nil, "wrong password"
    end
    return _user
end

function User:get(_id, key)
    _print("userget:" .. _id)

    local _detail = self._model:_get_key(model_type, _id)
    if _detail then
        _detail = json.decode(_detail)
        if key then
            return _detail[key]
        end
    end

    -- if key then
    --     _detail = self._model:_get_key(model_type .. ":" .. _id, key)
    -- else
    --     _detail = self._model:_getall_key(model_type .. ":" .. _id)
    -- end
    return _detail
end

function User:update(args)
    -- local user_id = args.user_id
    local id = args.id
    local _detail = self._model:_get_key(model_type, id)
    if _detail then
        _detail = json.decode(_detail)
        table.merge(_detail, args)
        local _now = ngx and ngx.time() or os.time()
        _detail.updated_at = _now
        self._model:_save_key(model_type, {[_detail.id] = json.encode(_detail)})
    end

    return _detail

    -- self._model:save(model_type, args)
end

function User:register(args)
    -- self._model = Model:new(self._instance)
    _print("register:" .. inspect(args))
    local _id, _err = self._model:_get_key(model_type .. ":name", args.username)
    _print("id:" .. inspect(_id))
    _print("_err:" .. inspect(_err))
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
    _print("args:" .. inspect(args))
    -- self._redis:initPipeline()

    self._model:_save_key(model_type .. ":name", {[args.username] = args.id})
    _print("save2:" .. inspect({[args.username] = args.id}))
    self._model:_save_key(model_type, {[args.id] = json.encode(args)})
    -- self._model:save(model_type, args)

    _print("save1:" .. inspect(args))

    -- self._redis:commitPipeline()
    return args
end

function User:changepass(args)
    -- self._model = Model:new(self._instance)
    _print("changepass:" .. inspect(args))
    local _id, _err = self._model:_get_key(model_type .. ":name", args.username)
    _print("id:" .. inspect(_id))
    _print("_err:" .. inspect(_err))
    if _id then
        return nil, "username exists"
    end

    if not args.oldpasssword then
        return nil, "oldpassword required"
    end

    local _now = ngx and ngx.time() or os.time()
    args.updated_at = _now

    local _user = self._model:_getall_key(model_type .. ":" .. _id)

    if _user.password_hash ~= crypto.passwordKey(args.oldpassword, _user.password_salt) then
        return nil, "wrong password"
    end
    args.oldpassword = nil

    local password = args.password
    local _hash, _salt = crypto.passwordKey(password)

    args.id = util.get_uuid(_now)

    args.created_at = _now
    args.password = nil
    args.password_hash = _hash
    args.password_salt = _salt
    _print("args:" .. inspect(args))
    -- self._redis:initPipeline()

    self._model:_save_key(model_type .. ":name", {[args.username] = args.id})
    _print("save2:" .. inspect({[args.username] = args.id}))
    self._model:save(model_type, args)
    _print("save1:" .. inspect(args))

    -- self._redis:commitPipeline()
    return args
end

return User
