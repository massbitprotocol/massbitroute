local gbc = cc.import("#gbc")
local mytype = "api"
local Session = cc.import("#session")

local json = cc.import("#json")
local util = require "mbutil" -- cc.import("#mbrutil")
-- local cjson = require "cjson"
local Action = cc.class(mytype .. "Action", gbc.ActionBase)

local inspect = require "inspect"
local _opensession

local ERROR = {
    NOT_LOGIN = 100
}
local Model = cc.import("#" .. mytype)

-- local jsonschema = require "jsonschema"
-- local validator = jsonschema.generate_validator

local _print = util.print
local _user

local function _norm(_v)
    if type(_v) == "string" then
        _v = json.decode(_v)
    end

    if _v.entrypoints and type(_v.entrypoints) == "string" then
        _v.entrypoints = json.decode(_v.entrypoints)
        setmetatable(_v.entrypoints, json.empty_array_mt)
    end
    if _v.security and type(_v.security) == "string" then
        _v.security = json.decode(_v.security)
    end
    return _v
end

function Action:createAction(args)
    _print(inspect(args))
    args.action = nil
    args.id = nil
    -- local myvalidator =
    --     validator {
    --     type = "object",
    --     properties = {
    --         name = {type = "string"},
    --         blockchain = {type = "string"},
    --         network = {type = "string"}
    --     }
    -- }

    -- local _res = myvalidator(args)
    -- _print(inspect(_res))

    local instance = self:getInstance()
    local _session = _opensession(instance, args)

    if not _session then
        return {result = false, err_code = ERROR.NOT_LOGIN}
    end
    local user_id = _session:get("id")
    if user_id then
        args.user_id = user_id
    end

    args.entrypoints = json.empty_array

    args.security = {
        allow_methods = "",
        limit_rate_per_sec = 100,
        limit_rate_per_day = 30000
    }
    local model = Model:new(instance)
    local _detail, _err_msg = model:create(args)

    _print(inspect(_detail))
    local _result
    if _detail then
        _result = {
            result = true,
            data = _detail
        }
    else
        _result = {
            result = false,
            err_msg = _err_msg
        }
    end
    instance:getRedis():setKeepAlive()
    return _result
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

    local _result
    if _v then
        _v = _norm(_v)

        _result = {
            result = true,
            data = _v
        }
    else
        _result = {
            result = false,
            err_msg = _err_msg
        }
    end
    instance:getRedis():setKeepAlive()
    return _result
end

-- function Action:testmailAction(args)
--     local instance = self:getInstance()

--     local jobs = instance:getJobs()
--     local job = {
--         action = "/jobs/user.sendmail",
--         delay = 1,
--         data = {}
--     }
--     local _ok, _err = jobs:add(job)
-- end

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

    if tonumber(args.status) == 0 then
        local jobs = instance:getJobs()
        local job = {
            action = "/jobs/" .. mytype .. ".removeconf",
            delay = 1,
            data = {
                _is_delete = false,
                id = args.id,
                user_id = user_id
            }
        }
        local _ok, _err = jobs:add(job)
    else
        local jobs = instance:getJobs()
        local job = {
            action = "/jobs/" .. mytype .. ".generateconf",
            delay = 1,
            data = {
                id = args.id,
                user_id = user_id
            }
        }
        local _ok, _err = jobs:add(job)
    end

    local model = Model:new(instance)
    local _detail, _err_msg = model:update(args)
    local _result = {result = true}
    if not _detail then
        _result = {
            result = false,
            err_msg = _err_msg
        }
    end
    instance:getRedis():setKeepAlive()
    return _result
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

    local jobs = instance:getJobs()
    local job = {
        action = "/jobs/" .. mytype .. ".removeconf",
        delay = 1,
        data = {
            _is_delete = true,
            id = args.id,
            user_id = user_id
        }
    }
    local _ok, _err = jobs:add(job)

    ngx.log(ngx.ERR, inspect({_ok, _err}))
    instance:getRedis():setKeepAlive()
    return {
        result = true
    }
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

    setmetatable(_res, json.empty_array_mt)

    for _, _v in pairs(_detail) do
        if _v then
            _v = _norm(_v)
            _res[#_res + 1] = _v
        end
    end

    local _result = {
        result = true,
        data = _res
    }
    instance:getRedis():setKeepAlive()
    return _result
end

--private

_opensession = function(instance, args)
    local sid = args.sid
    sid = sid or ngx.var.cookie__slc_web_sid
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
