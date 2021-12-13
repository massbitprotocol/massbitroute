local gbc = cc.import("#gbc")
local mytype = "api"
local Session = cc.import("#session")

local json = cc.import("#json")
local cjson = require "cjson"
local Action = cc.class(mytype .. "Action", gbc.ActionBase)

local inspect = require "inspect"
local _opensession

local ERROR = {
    NOT_LOGIN = 100
}
local Model = cc.import("#" .. mytype)

local _user

local function _norm(_v)
    if type(_v) == "string" then
        _v = json.decode(_v)
    end

    if _v.entrypoints and type(_v.entrypoints) == "string" then
        _v.entrypoints = json.decode(_v.entrypoints)
        setmetatable(_v.entrypoints, cjson.empty_array_mt)
    end
    if _v.security and type(_v.security) == "string" then
        _v.security = json.decode(_v.security)
    end
    return _v
end

function Action:createAction(args)
    args.action = nil
    args.id = nil
    local instance = self:getInstance()
    local _session = _opensession(instance, args)

    if not _session then
        return {result = false, err_code = ERROR.NOT_LOGIN}
    end
    local user_id = _session:get("id")
    if user_id then
        args.user_id = user_id
    end

    args.entrypoints = cjson.empty_array

    args.security = {
        allow_methods = "",
        limit_rate_per_sec = 100,
        limit_rate_per_day = 30000
    }
    local model = Model:new(instance)
    local _detail, _err_msg = model:create(args)
    if _detail then
        return {
            result = true,
            data = _detail
        }
    else
        return {
            result = false,
            err_msg = _err_msg
        }
    end
end

function Action:getAction(args)
    if not args.id then
        return {
            result = false,
            err_msg = "params 'id' missing"
        }
    end
    args.action = nil
    local instance = self:getInstance()
    local _session = _opensession(instance, args)

    if not _session then
        return {result = false, err_code = ERROR.NOT_LOGIN}
    end
    local user_id = _session:get("id")
    if user_id then
        args.user_id = user_id
    end

    local model = Model:new(instance)

    local _v, _err_msg = model:get(args)

    if _v then
        _v = _norm(_v)

        return {
            result = true,
            data = _v
        }
    else
        return {
            result = false,
            err_msg = _err_msg
        }
    end
end
function Action:updateAction(args)
    if not args.id then
        return {
            result = false,
            err_msg = "params 'id' missing"
        }
    end
    args.action = nil
    local instance = self:getInstance()
    local _session = _opensession(instance, args)

    if not _session then
        return {result = false, err_code = ERROR.NOT_LOGIN}
    end
    local user_id = _session:get("id")
    if user_id then
        args.user_id = user_id
    end

    local model = Model:new(instance)
    local _detail, _err_msg = model:update(args)
    if not _detail then
        return {
            result = false,
            err_msg = _err_msg
        }
    end

    local jobs = instance:getJobs()
    local job = {
        action = "/jobs/" .. mytype .. ".generateconf",
        delay = 3,
        data = {
            id = _detail.id,
            user_id = user_id
        }
    }
    local ok, err = jobs:add(job)

    return {result = true}
end

function Action:deleteAction(args)
    if not args.id then
        return {
            result = false,
            err_msg = "params 'id' missing"
        }
    end
    args.action = nil
    local instance = self:getInstance()
    local _session = _opensession(instance, args)

    if not _session then
        return {result = false, err_code = ERROR.NOT_LOGIN}
    end
    local user_id = _session:get("id")
    if user_id then
        args.user_id = user_id
    end

    local model = Model:new(instance)
    local _detail, _err_msg = model:delete(args)
    if _detail then
        return {
            result = true
        }
    else
        return {
            result = false,
            err_msg = _err_msg
        }
    end
end

function Action:listAction(args)
    args.action = nil
    local instance = self:getInstance()
    local _session = _opensession(instance, args)

    if not _session then
        return {result = false, err_code = ERROR.NOT_LOGIN}
    end
    local user_id = _session:get("id")
    if user_id then
        args.user_id = user_id
    end

    local model = Model:new(instance)
    local _detail = model:list(args)
    local _res = {}

    setmetatable(_res, cjson.empty_array_mt)

    for _, _v in pairs(_detail) do
        -- ngx.log(ngx.ERR, inspect(type(_v)))
        if _v then
            _v = _norm(_v)
            -- if type(_v) == "string" then
            --     _v = json.decode(_v)
            -- end

            -- if _v.entrypoints and type(_v.entrypoints) == "string" then
            --     ngx.log(ngx.ERR, _v.entrypoints)
            --     _v.entrypoints = json.decode(_v.entrypoints)
            -- end
            -- if _v.security and type(_v.security) == "string" then
            --     ngx.log(ngx.ERR, _v.security)
            --     _v.security = json.decode(_v.security)
            -- end
            -- ngx.log(ngx.ERR, inspect(_v))
            _res[#_res + 1] = _v
        --json.decode(_v)
        end
    end

    return {
        result = true,
        data = _res
    }
end

--private

_opensession = function(instance, args)
    local sid = args.sid
    sid = sid or ngx.var.cookie__slc_web_sid
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
