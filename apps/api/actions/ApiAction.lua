local cc, ndk, ngx = cc, ndk, ngx

local gbc = cc.import("#gbc")
local mytype = "api"
local Session = cc.import("#session")

local ngx_log = ngx.log

local json = cc.import("#json")
local util = require "mbutil"
local env = require("env")

local Action = cc.class(mytype .. "Action", gbc.ActionBase)

local inspect = require "inspect"
local _opensession
-- local _print = util.print

local ERROR = {
    NOT_LOGIN = 100
}
local Model = cc.import("#" .. mytype)

local _domain_name = env.DOMAIN or "massbitroute.com"
local _authorize_whitelist = util.authorize_whitelist

local function _run_job(instance, args, option)
    ngx_log(ngx.ERR, "[run_job]:" .. inspect(args))
    local jobs = instance:getJobs()
    if not option then
        option = {_is_delete = false}
    end
    if ngx.var.deploy_dir then
        option.deploy_dir = ngx.var.deploy_dir
    end

    table.merge(
        option,
        {
            id = args.id,
            user_id = args.user_id
        }
    )
    local job = {
        action = tonumber(args.status) == 0 and "/jobs/" .. mytype .. ".removeconf" or
            "/jobs/" .. mytype .. ".generateconf",
        delay = 0,
        data = option
    }
    ngx_log(ngx.ERR, "[job add]:" .. inspect(job))
    local _res = jobs:add(job)
    ngx_log(ngx.ERR, "[job response]:" .. inspect(_res))
    return _res
end

local function _norm_schema(args)
    for _, _v in ipairs({"name", "blockchain", "network"}) do
        -- _print(_v)
        if args[_v] then
            args[_v] = args[_v]:trim()
        end
    end
    return args
end

local function _norm(_v)
    ngx_log(ngx.ERR, "[norm]:" .. inspect(_v))
    _v = _norm_schema(_v)
    if type(_v) == "string" then
        _v = json.decode(_v)
    end

    if _v.entrypoints and type(_v.entrypoints) == "string" then
        ngx_log(ngx.ERR, "[norm_entry]:" .. inspect(_v.entrypoints))
        _v.entrypoints = json.decode(_v.entrypoints)
        ngx_log(ngx.ERR, "[norm_entry1]:" .. inspect(_v.entrypoints))
        setmetatable(_v.entrypoints, json.empty_array_mt)
    end
    if _v.security and type(_v.security) == "string" then
        _v.security = json.decode(_v.security)
    end
    ngx_log(ngx.ERR, "[norm1]:" .. inspect(_v))
    return _v
end

function Action:createAction(args)
    ngx_log(ngx.ERR, "[request]:" .. inspect(args))
    args.action = nil

    args.server_name = _domain_name
    args = _norm_schema(args)

    local instance = self:getInstance()

    local user_id
    local _config = self:getInstanceConfig()
    local _is_authorized = _authorize_whitelist(_config, args)

    if _is_authorized then
        user_id = args.user_id
    else
        local _session = _opensession(instance, args)

        if not _session then
            return {result = false, err_code = ERROR.NOT_LOGIN}
        end
        user_id = _session:get("id")
        if user_id then
            args.user_id = user_id
        end
    end

    args.entrypoints = json.empty_array

    args.security = {
        allow_methods = "",
        limit_rate_per_sec = 0,
        limit_rate_per_day = 0
    }
    local model = Model:new(instance)
    local _detail = model:create(args)

    local _result = {
        result = false
    }
    if _detail then
        local _job_id = _run_job(instance, args)
        if _job_id and tonumber(_job_id) > 0 then
            _result = {
                result = true,
                data = _detail
            }
        end
    end
    instance:getRedis():setKeepAlive()
    ngx_log(ngx.ERR, "[response]:" .. inspect(_result))
    return _result
end

function Action:getAction(args)
    ngx_log(ngx.ERR, "[request]:" .. inspect(args))
    if not args.id then
        return {
            result = false,
            err_msg = "params 'id' missing"
        }
    end
    args.action = nil
    local instance = self:getInstance()
    local user_id
    local _config = self:getInstanceConfig()
    local _is_authorized = _authorize_whitelist(_config, args)
    if _is_authorized then
        user_id = args.user_id
    else
        local _session = _opensession(instance, args)

        if not _session then
            return {result = false, err_code = ERROR.NOT_LOGIN}
        end
        user_id = _session:get("id")
        if user_id then
            args.user_id = user_id
        end
    end

    local model = Model:new(instance)

    local _v = model:get(args)

    local _result = {result = false}
    if _v then
        _v = _norm(_v)

        _result = {
            result = true,
            data = _v
        }
    end
    ngx_log(ngx.ERR, "[response]:" .. inspect(_result))
    instance:getRedis():setKeepAlive()
    return _result
end

function Action:adminupdateAction(args)
    args.action = nil
    local instance = self:getInstance()
    local model = Model:new(instance)
    local _ok, _err = model:update(args)

    if _ok then
        _run_job(instance, args)
    end
    return {
        ok = _ok,
        err = _err
    }
end

function Action:calljobAction(args)
    args.action = nil
    local job_method = args.job
    args.job = nil

    local instance = self:getInstance()
    local jobs = instance:getJobs()
    local job = {
        action = "/jobs/" .. job_method,
        delay = 0,
        data = args
    }
    if ngx.var.deploy_dir then
        job.deploy_dir = ngx.var.deploy_dir
    end
    local _ok, _err = jobs:add(job)
    return {
        ok = _ok,
        err = _err
    }
end

function Action:updateAction(args)
    ngx_log(ngx.ERR, "[request]:" .. inspect(args))
    if not args.id then
        return {
            result = false,
            err_msg = "params 'id' missing"
        }
    end
    args.action = nil
    args = _norm(args)
    local instance = self:getInstance()
    local _config = self:getInstanceConfig()
    local _is_authorized = _authorize_whitelist(_config, args)

    local user_id
    if _is_authorized then
        user_id = args.user_id
    else
        local _session = _opensession(instance, args)

        if not _session then
            return {result = false, err_code = ERROR.NOT_LOGIN}
        end
        user_id = _session:get("id")
        if user_id then
            args.user_id = user_id
        end
    end

    local model = Model:new(instance)
    local _detail = model:update(args)

    local _result = {
        result = false
    }

    if _detail then
        _run_job(instance, args)
        _result = {
            result = true,
            data = _detail
        }
    end

    instance:getRedis():setKeepAlive()
    ngx_log(ngx.ERR, "[request]:" .. inspect(_result))
    return _result
end

-- function Action:updatemultiAction(args)
--     -- _print(inspect(args))
--     local _ids

--     if not args.ids then
--         return {
--             result = false,
--             err_msg = "params 'ids' missing"
--         }
--     else
--         _ids = json.decode(args.ids)
--     end
--     if not _ids then
--         return {
--             result = false,
--             err_msg = "params 'ids' invalid"
--         }
--     end

--     args.action = nil
--     args.id = nil
--     args.ids = nil
--     local instance = self:getInstance()
--     local _config = self:getInstanceConfig()
--     local _is_authorized = _authorize_whitelist(_config, args)
--     -- _print("_authorize_whitelist:" .. inspect(_res))
--     local user_id
--     if _is_authorized then
--         user_id = args.user_id
--     else
--         local _session = _opensession(instance, args)

--         if not _session then
--             return {result = false, err_code = ERROR.NOT_LOGIN}
--         end
--         user_id = _session:get("id")
--         if user_id then
--             args.user_id = user_id
--         end
--     end

--     local model = Model:new(instance)
--     for _, _id in ipairs(_ids) do
--         local _arg = {id = _id}
--         table.merge(_arg, args)
--         model:update(_arg)
--     end

--     local jobs = instance:getJobs()
--     local job = {
--         action = tonumber(args.status) == 0 and "/jobs/" .. mytype .. ".removemulticonf" or
--             "/jobs/" .. mytype .. ".generatemulticonf",
--         delay = 0,
--         data = {
--             ids = _ids,
--             user_id = user_id
--         }
--     }
--     local _ok, _err = jobs:add(job)

--     -- _print({ok = _ok, err = _err}, true)
--     instance:getRedis():setKeepAlive()
--     return {result = true}
-- end

function Action:deleteAction(args)
    ngx_log(ngx.ERR, "[request]:" .. inspect(args))
    if not args.id then
        return {
            result = false,
            err_msg = "params 'id' missing"
        }
    end
    args.action = nil
    local user_id
    local instance = self:getInstance()
    local _config = self:getInstanceConfig()
    local _is_authorized = _authorize_whitelist(_config, args)

    if _is_authorized then
        user_id = args.user_id
    else
        local _session = _opensession(instance, args)

        if not _session then
            return {result = false, err_code = ERROR.NOT_LOGIN}
        end
        user_id = _session:get("id")
        if user_id then
            args.user_id = user_id
        end
    end
    args.status = 0
    _run_job(instance, args, {_is_delete = true})

    instance:getRedis():setKeepAlive()
    local _result = {
        result = true
    }
    ngx_log(ngx.ERR, "[response]:" .. inspect(_result))
    return _result
end

function Action:listAction(args)
    args.action = nil
    local instance = self:getInstance()
    local _config = self:getInstanceConfig()
    local _is_authorized = _authorize_whitelist(_config, args)

    local user_id
    if _is_authorized then
        user_id = args.user_id
    else
        local _session = _opensession(instance, args)

        if not _session then
            return {result = false, err_code = ERROR.NOT_LOGIN}
        end
        user_id = _session:get("id")
        if user_id then
            args.user_id = user_id
        end
    end

    local model = Model:new(instance)
    local _detail = model:list(args)
    local _ret = {}

    setmetatable(_ret, json.empty_array_mt)

    for _, _v in pairs(_detail) do
        if _v then
            _v = _norm(_v)
            _ret[#_ret + 1] = _v
        end
    end

    local _result = {
        result = true,
        data = _ret
    }
    instance:getRedis():setKeepAlive()
    return _result
end

--private

_opensession = function(instance, args)
    local sid = ngx.var.cookie__slc_web_sid or args.sid
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
