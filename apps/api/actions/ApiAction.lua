local cc, ndk, ngx = cc, ndk, ngx

local gbc = cc.import("#gbc")
local mytype = "api"
local Session = cc.import("#session")

local json = cc.import("#json")
local util = require "mbutil" -- cc.import("#mbrutil")

-- local cjson = require "cjson"
local Action = cc.class(mytype .. "Action", gbc.ActionBase)

local inspect = require "inspect"
local _opensession
local _print = util.print
-- local mkdirp = require "mkdirp"
local ERROR = {
    NOT_LOGIN = 100
}
local Model = cc.import("#" .. mytype)

local v = require "validation"

local schema_create =
    v.is_table {
    sid = v.optional(v.is_string()),
    app_key = v.optional(v.is_string()),
    user_id = v.optional(v.is_string()),
    partner_id = v.optional(v.is_string()),
    partner_quota = v.optional(v.is_string()),
    name = v.is_string(),
    blockchain = v.in_list {"avax", "bsc", "dot", "eth", "ftm", "hmny", "matic", "near", "sol"},
    network = v.in_list {
        "mainnet",
        "devnet",
        "testnet"
    }
}

local function _norm_schema(args)
    for _, _v in ipairs({"name", "blockchain", "network"}) do
        _print(_v)
        args[_v] = args[_v]:trim()
    end
    return args
end
-- local jsonschema = require "jsonschema"
-- local validator = jsonschema.generate_validator
-- local validator_api =
--     validator(
--     {
--         type = "object",
--         properties = {
--             name = {type = "string"},
--             blockchain = {type = "string"},
--             network = {type = "string"}
--         }
--     }
-- )

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

local function _authorize_whitelist(self, args)
    local _config = self:getInstanceConfig()
    local _appconf = _config.app
    local whitelist_sid = _appconf.whitelist_sid
    _print("whitelist_sid:" .. inspect(whitelist_sid))
    local sid = ngx.var.cookie__slc_web_sid or args.sid
    local _info = whitelist_sid and whitelist_sid[sid]
    _print("sid:" .. sid)
    _print("_info:" .. inspect(_info))
    if sid and _info then
        local _partner_id = args.partner_id
        local _user_id = args.user_id

        local _info_partner_id = _info.partner_id
        if not _user_id or not _partner_id or not _info_partner_id or _partner_id ~= _info_partner_id then
            return {
                result = false,
                err_msg = "Arguments not valid"
            }
        end
        args.partner_id = nil
        return true
    end
    return false
end

function Action:createAction(args)
    _print(inspect(args))
    args.action = nil
    --args.id = nil
    local _config = self:getInstanceConfig()
    args.server_name = _config.app.server_name or "massbitroute.com"
    local _valid, _err = schema_create(args)
    _print("validator:" .. inspect(_valid))
    _print("err:" .. inspect(_err))

    if not _valid then
        return {
            result = false,
            err_msg = "Arguments not valid"
        }
    end

    args = _norm_schema(args)

    local instance = self:getInstance()

    local user_id
    local _res = _authorize_whitelist(self, args)
    _print("_authorize_whitelist:" .. inspect(_res))
    if _res then
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

    _print("user_id:" .. user_id)
    _print("args:" .. inspect(args))
    args.entrypoints = json.empty_array

    args.security = {
        allow_methods = "",
        limit_rate_per_sec = 100,
        limit_rate_per_day = 30000
    }
    local model = Model:new(instance)
    local _detail, _err_msg = model:create(args)

    _print("detail:" .. inspect(_detail))
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
    local user_id
    local _res = _authorize_whitelist(self, args)
    _print("_authorize_whitelist:" .. inspect(_res))
    if _res then
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

    _print("user_id:" .. user_id)
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

function Action:updateAction(args)
    _print(inspect(args))
    if not args.id then
        return {
            result = false,
            err_msg = "params 'id' missing"
        }
    end
    args.action = nil
    local instance = self:getInstance()
    local _res = _authorize_whitelist(self, args)
    _print("_authorize_whitelist:" .. inspect(_res))
    local user_id
    if _res then
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
    local _detail, _err_msg = model:update(args)
    _print(inspect(_detail))

    local _result = {result = true}
    if not _detail then
        _result = {
            result = false,
            err_msg = _err_msg
        }
    end
    local _ok, _err
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
        _ok, _err = jobs:add(job)
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
        _ok, _err = jobs:add(job)
    end

    _print({ok = _ok, err = _err}, true)
    instance:getRedis():setKeepAlive()
    return _result
end

function Action:updatemultiAction(args)
    _print(inspect(args))
    local _ids

    if not args.ids then
        return {
            result = false,
            err_msg = "params 'ids' missing"
        }
    else
        _ids = json.decode(args.ids)
    end
    if not _ids then
        return {
            result = false,
            err_msg = "params 'ids' invalid"
        }
    end

    args.action = nil
    args.id = nil
    args.ids = nil
    local instance = self:getInstance()
    local _res = _authorize_whitelist(self, args)
    _print("_authorize_whitelist:" .. inspect(_res))
    local user_id
    if _res then
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
    for _, _id in ipairs(_ids) do
        local _arg = table.merge({id = _id}, args)
        model:update(_arg)
    end

    -- local _result = {result = true}
    -- if not _detail then
    --     _result = {
    --         result = false,
    --         err_msg = _err_msg
    --     }
    -- end
    local _ok, _err
    if tonumber(args.status) == 0 then
        local jobs = instance:getJobs()
        local job = {
            action = "/jobs/" .. mytype .. ".removemulticonf",
            delay = 1,
            data = {
                _is_delete = false,
                ids = _ids,
                user_id = user_id
            }
        }
        _ok, _err = jobs:add(job)
    else
        local jobs = instance:getJobs()
        local job = {
            action = "/jobs/" .. mytype .. ".generatemulticonf",
            delay = 1,
            data = {
                ids = _ids,
                user_id = user_id
            }
        }
        _ok, _err = jobs:add(job)
    end

    _print({ok = _ok, err = _err}, true)
    instance:getRedis():setKeepAlive()
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
    local user_id
    local instance = self:getInstance()
    local _res = _authorize_whitelist(self, args)
    _print("_authorize_whitelist:" .. inspect(_res))
    if _res then
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
    local _res = _authorize_whitelist(self, args)
    _print("_authorize_whitelist:" .. inspect(_res))
    local user_id
    if _res then
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

    _print("user_id:" .. user_id)
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
    -- local sid = args.sid
    -- sid = sid or ngx.var.cookie__slc_web_sid
    if not sid then
        -- cc.throw('not set argsument: "sid"')
        return nil
    end

    _print("sid:" .. sid)
    local session = Session:new(instance:getRedis())
    if not session:start(sid) then
        -- cc.throw("session is expired, or invalid session id")
        return nil
    end

    return session
end

return Action
