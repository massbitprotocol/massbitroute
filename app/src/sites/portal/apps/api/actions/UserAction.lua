local gbc = cc.import("#gbc")
local type = "User"
local Session = cc.import("#session")

local json = cc.import("#json")

local Action = cc.class(type .. "Action", gbc.ActionBase)

local _opensession

local User = cc.import("#user")

local _user

local inspect = require "inspect"

function Action:pingAction(args)
    args.action = nil
    local instance = self:getInstance()
    local _session = _opensession(instance, args)

    -- local config = self:getInstanceConfig()

    -- local appConfig = config.app
    -- ngx.log(ngx.ERR, inspect(appConfig))

    if not _session then
        return {result = false}
    end
    -- ngx.log(ngx.ERR, "sid:" .. _sid)

    -- local session = Session:new(instance:getRedis())
    -- local _is_ok = session:start(_sid)
    return {
        result = true
    }
end

function Action:registerAction(args)
    args.action = nil
    ngx.log(ngx.ERR, json.encode(args))

    local instance = self:getInstance()

    _user = _user or User:new(instance)

    local _detail, _err = _user:register(args)
    if not _detail then
        return {result = false, err = _err}
    end

    return {result = true, data = {id = _detail.id}}
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
    ngx.log(ngx.ERR, json.encode(appConfig))

    _user = _user or User:new(instance)
    local _detail, _err = _user:login(args)
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

    -- return result
    return {result = true, data = {sid = _sid}}
end

function Action:logoutAction(args)
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
    return {ok = "ok"}
end

--private

_opensession = function(instance, args)
    local sid = args.sid
    if not sid then
        sid = ngx.var.cookie__slc_web_sid
    end

    if not sid then
        cc.throw('not set argsument: "sid"')
        return nil
    end

    local session = Session:new(instance:getRedis())
    if not session:start(sid) then
        cc.throw("session is expired, or invalid session id")
        return nil
    end

    return session
end

return Action
