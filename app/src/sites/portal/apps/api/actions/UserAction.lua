local cc, ngx = cc, ngx
local gbc = cc.import("#gbc")
local mytype = "user"
local Session = cc.import("#session")

local json = cc.import("#json")

local Action = cc.class(mytype .. "Action", gbc.ActionBase)

local _opensession

local set_var = ndk.set_var

local Model = cc.import("#" .. mytype)

-- local User = cc.import("#user")
local util = cc.import("#mbrutil")
local inspect = require "inspect"

local _print = util.print
local _user

local ERROR = {
    NOT_LOGIN = 100
}

local function _norm_json(_v, _field)
    if _v[_field] and type(_v[_field]) == "string" then
        _v[_field] = json.decode(_v[_field])
        setmetatable(_v[_field], cjson.empty_array_mt)
    end
end

local function _norm(_v)
    if type(_v) == "string" then
        _v = json.decode(_v)
    end
    -- _norm_json(_v, "geo")
    return _v
end

-- local inspect = require "inspect"

function Action:pingAction(args)
    args.action = nil
    local instance = self:getInstance()
    local _session = _opensession(instance, args)

    if not _session then
        return {result = false, err_code = ERROR.NOT_LOGIN}
    end

    instance:getRedis():setKeepAlive()
    return {
        result = true
    }
end

function Action:registerconfirmAction(args)
    local _token = args.token
    if not _token then
        return {result = false}
    end
    local instance = self:getInstance()
    local model = Model:new(instance)

    local _data
    if not args.baysao then
        local token = set_var.set_decode_base32(_token)
        _data = set_var.set_decrypt_session(token)
        if _data then
            _data = json.decode(_data)
            if not _data.id or not _data.confirmtype or _data.confirmtype ~= "register" then
                return ngx.redirect("https://dapi.massbit.io/pages/register_confirmed_fail.html")
            end
        else
            return ngx.redirect("https://dapi.massbit.io/pages/register_confirmed_fail.html")
        end

        _print(inspect(_data))
    else
        local _username = args.baysao
        local _id = model:get("name", _username)
        _data = {id = _id}
    end

    local _is_confirmed = model:get(_data.id, "confirmed")
    _print("is_confirmed:" .. inspect(_is_confirmed))
    if _is_confirmed then
        return ngx.redirect("https://dapi.massbit.io/pages/register_confirmed_fail.html")
    -- return {result = false, err = "Account confirmed"}
    end

    _data.confirmed = true
    model:update(_data)

    ngx.redirect("https://dapi.massbit.io/pages/register_confirmed_success.html")
    -- return {
    --     result = true
    -- }
    -- local instance = self:getInstance()
end

function Action:registerAction(args)
    args.action = nil
    -- ngx.log(ngx.ERR, json.encode(args))

    local instance = self:getInstance()

    _user = _user or Model:new(instance)

    args.confirmed = false
    local _detail, _err = _user:register(args)
    if not _detail then
        return {result = false, err = _err}
    end

    -- local _data = {id = _detail.id}
    -- local _txt = json.encode(_data)

    -- _print("txt:" .. inspect(_txt))
    local __data = set_var.set_encrypt_session(json.encode({id = _detail.id, confirmtype = "register"}))
    local _token = set_var.set_encode_base32(__data)

    _detail.token = _token
    -- _print("detail:" .. inspect(_detail))
    local jobs = instance:getJobs()
    local job = {
        action = "/jobs/" .. mytype .. ".register",
        delay = 1,
        data = _detail
    }

    local _ok, _err = jobs:add(job)

    instance:getRedis():setKeepAlive()
    return {result = true, data = {id = _detail.id}}
end

-- function Action:changepassAction(args)
--     args.action = nil
--     -- ngx.log(ngx.ERR, json.encode(args))

--     local instance = self:getInstance()

--     _user = _user or Model:new(instance)

--     args.confirmed = false
--     local _detail, _err = _user:register(args)
--     if not _detail then
--         return {result = false, err = _err}
--     end

--     -- local _data = {id = _detail.id}
--     -- local _txt = json.encode(_data)

--     -- _print("txt:" .. inspect(_txt))
--     local __data = set_var.set_encrypt_session(json.encode({id = _detail.id, confirmtype = "register"}))
--     local _token = set_var.set_encode_base32(__data)

--     _detail.token = _token
--     -- _print("detail:" .. inspect(_detail))
--     local jobs = instance:getJobs()
--     local job = {
--         action = "/jobs/" .. mytype .. ".register",
--         delay = 1,
--         data = _detail
--     }

--     local _ok, _err = jobs:add(job)

--     return {result = true, data = {id = _detail.id}}
-- end

function Action:getAction(args)
    _print(inspect(args))
    -- if not args.id then
    --     return {
    --         result = false,
    --         err_msg = "params 'id' missing"
    --     }
    -- end
    args.action = nil
    local instance = self:getInstance()
    local _session = _opensession(instance, args)
    -- _print("session:" .. inspect(_session))
    if not _session then
        return {result = false, err_code = ERROR.NOT_LOGIN}
    end

    local user_id = _session:get("id")
    -- _print("user_id:" .. user_id)
    -- if user_id then
    --     args.user_id = user_id
    --     args.id = user_id
    -- end

    local model = Model:new(instance)

    -- _print("args:" .. inspect(args))
    local _v, _err_msg = model:get(user_id)
    _print("user:" .. inspect(_v))
    _print("err:" .. inspect(_err_msg))
    if _v then
        _v = _norm(_v)
        _v.password_hash = nil
        _v.password_salt = nil

        return {
            result = true,
            data = _v
        }
    end
    instance:getRedis():setKeepAlive()
    return {
        result = false,
        err_msg = _err_msg
    }
end

function Action:loginAction(args)
    args.action = nil
    local username = args.username
    if not username then
        cc.throw('not set argsument: "username"')
    end

    local instance = self:getInstance()
    local config = self:getInstanceConfig()

    local appConfig = config.app
    -- ngx.log(ngx.ERR, json.encode(appConfig))

    _user = _user or Model:new(instance)
    local _detail, _err = _user:login(args)
    _print(inspect(_detail))
    if not _detail then
        return {result = false, err = _err}
    end

    -- start session
    local session = Session:new(instance:getRedis())
    session:start()
    local _sid = session:getSid()
    session:set("sid", _sid)
    session:set("id", _detail.id)
    -- session:set("count", 0)
    session:save()
    local _new_ttl = ngx.cookie_time(ngx.time() + appConfig.sessionExpiredTime)
    ngx.header["Set-Cookie"] = {
        "_slc_web_sid=" ..
            _sid ..
                ";Domain=" ..
                    ngx.var.http_host .. ";Path=/;Expires=" .. _new_ttl .. ";Max-Age=" .. _new_ttl .. ";HttpOnly"
    }

    _detail.site_root = ngx.var.site_root
    _detail.ip = ngx.var.realip
    _detail.user_agent = ngx.var.http_user_agent
    _detail.time = os.date("!%Y-%m-%d %H:%M:%S")

    --os.time(os.date("!*t"))

    --ngx and ngx.time() or os.time()
    local jobs = instance:getJobs()
    local job = {
        action = "/jobs/" .. mytype .. ".login",
        delay = 1,
        data = _detail
    }

    local _ok, _err = jobs:add(job)
    instance:getRedis():setKeepAlive()
    -- return result
    return {result = true, data = {sid = _sid}}
end

function Action:logoutAction(args)
    local instance = self:getInstance()
    args.action = nil
    -- remove user from online list
    local session = _opensession(self:getInstance(), args)
    -- ngx.header["Set-Cookie"] = {
    --      "_slc_web_sid=deleted" .. ";Path=/;Expires=Thu, 01 Jan 1970 00:00:00 GMT" .. ";HttpOnly"
    --  }
    -- local online = Online:new(self:getInstance())
    -- online:remove(session:get("username"))
    -- delete session
    session:destroy()
    instance:getRedis():setKeepAlive()
    return {ok = "ok"}
end

--private

_opensession = function(instance, args)
    local sid = args.sid
    if not sid then
        sid = ngx.var.cookie__slc_web_sid
    end

    if not sid then
        -- cc.throw('not set argsument: "sid"')
        return nil
    end

    local session = Session:new(instance:getRedis())
    if not session:start(sid) then
        -- cc.throw("session is expired, or invalid session id")
        return nil
    end

    return session
end

return Action
