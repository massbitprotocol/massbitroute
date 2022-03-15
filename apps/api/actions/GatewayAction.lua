local cc, ndk, ngx = cc, ndk, ngx
local gbc = cc.import("#gbc")
local mytype = "gateway"
local Session = cc.import("#session")
local util = require "mbutil"
-- local util = cc.import("#mbrutil")

local json = cc.import("#json")
-- local cjson = require "cjson"
local Action = cc.class(mytype .. "Action", gbc.ActionBase)

local httpc = require("resty.http").new()
local inspect = require "inspect"

local _opensession
local set_var = ndk.set_var

local ERROR = {
    NOT_LOGIN = 100
}
local Model = cc.import("#" .. mytype)

local _print = util.print
local _get_geo = util.get_geo

local function _norm_json(_v, _field)
    if _v[_field] and type(_v[_field]) == "string" then
        _v[_field] = json.decode(_v[_field])
        setmetatable(_v[_field], json.empty_array_mt)
    end
end

local function _norm(_v)
    if type(_v) == "string" then
        _v = json.decode(_v)
    end
    _norm_json(_v, "geo")
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

function Action:geonodecountryAction()
    local _datacenters = {}
    local instance = self:getInstance()
    local _red = instance:getRedis()
    local _user_gw = _red:keys("*:" .. mytype)
    for _, _k in ipairs(_user_gw) do
        local _gw_arr = _red:arrayToHash(_red:hgetall(_k))
        for _, _gw_str in pairs(_gw_arr) do
            local _gw = json.decode(_gw_str)

            if _gw.geo and _gw.geo.continent_code then
                _datacenters[_gw.geo.continent_code] = _datacenters[_gw.geo.continent_code] or {}
                _datacenters[_gw.geo.continent_code][_gw.geo.country_code] =
                    _datacenters[_gw.geo.continent_code][_gw.geo.country_code] or 0
                _datacenters[_gw.geo.continent_code][_gw.geo.country_code] =
                    _datacenters[_gw.geo.continent_code][_gw.geo.country_code] + 1
            end
        end
    end

    local _data = {}
    for _k1, _v1 in pairs(_datacenters) do
        _data[_k1] = _data[_k1] or {}
        for _k2, _v2 in pairs(_v1) do
            table.insert(_data[_k1], {id = _k2, value = _v2})
        end
    end
    return {
        result = true,
        data = _data
    }
end

function Action:geonodecontinentAction()
    local _datacenters = {}
    local instance = self:getInstance()
    local _red = instance:getRedis()
    local _user_gw = _red:keys("*:" .. mytype)
    for _, _k in ipairs(_user_gw) do
        local _gw_arr = _red:arrayToHash(_red:hgetall(_k))
        for _, _gw_str in pairs(_gw_arr) do
            local _gw = json.decode(_gw_str)

            if _gw.geo and _gw.geo.continent_code then
                _datacenters[_gw.geo.continent_code] = _datacenters[_gw.geo.continent_code] or 0

                _datacenters[_gw.geo.continent_code] = _datacenters[_gw.geo.continent_code] + 1
            end
        end
    end
    return {
        result = true,
        data = _datacenters
    }
end

function Action:pingAction(args)
    args.action = nil
    local _token = args.token
    if not _token then
        return {result = false, err_msg = "Token missing"}
    end
    local instance = self:getInstance()
    local user_id = args.user_id
    if not user_id then
        return {result = false, err_msg = "User ID missing"}
    end
    --[[
    local token = set_var.set_decode_base32(_token)
    local id = set_var.set_decrypt_session(token)
    if not id or id ~= args.id then
        return {result = false, err_msg = "Token not correct"}
    end
    ]]
    local _data = {
        id = id,
        user_id = user_id
    }

    local model = Model:new(instance)
    model:update(_data)
    return {result = true}
end

--- Register gateway

function Action:registerAction(args)
    _print("register:" .. inspect(args))
    args.action = nil
    local _token = args.token
    if not _token then
        return {result = false, err_msg = "Token missing"}
    end
    local instance = self:getInstance()
    local _config = self:getInstanceConfig()
    -- _print("config:" .. inspect(_config))
    local id = args.id
    local user_id = args.user_id
    if not user_id then
        return {result = false, err_msg = "User ID missing"}
    end
    --[[
    local token = set_var.set_decode_base32(_token)
    local id = set_var.set_decrypt_session(token)

    if not id or id ~= args.id then
        return {result = false, err_msg = "Token not correct"}
    end
    ]]
    local ip = ngx.var.realip

    local _data = {
        approved = 0,
        id = id,
        token = _token,
        user_id = user_id,
        ip = ip,
        status = 0
    }

    --local _geo = _get_geo(ip, _config)
    if args.geo then
        _data.geo = args.geo
    end

    local model = Model:new(instance)
    model:update(_data)
    local jobs = instance:getJobs()
    local job = {
        action = "/jobs/" .. mytype .. ".generateconf",
        delay = 1,
        data = {
            id = id,
            user_id = user_id
        }
    }
    jobs:add(job)
    return {result = true}
end

function Action:unregisterAction(args)
    args.action = nil
    local _token = args.token
    if not _token then
        return {result = false, err_msg = "Token missing"}
    end
    local instance = self:getInstance()

    local user_id = args.user_id
    if not user_id then
        return {result = false, err_msg = "User ID missing"}
    end

    local token = set_var.set_decode_base32(_token)
    local id = set_var.set_decrypt_session(token)

    if not id or id ~= args.id then
        return {result = false, err_msg = "Token not correct"}
    end

    local _data = {
        id = id,
        user_id = user_id,
        status = 0
    }

    local model = Model:new(instance)
    model:update(_data)

    local jobs = instance:getJobs()
    local job = {
        action = "/jobs/" .. mytype .. ".removeconf",
        delay = 1,
        data = {
            _is_delete = false,
            id = id,
            user_id = user_id
        }
    }
    jobs:add(job)
    return {result = true}
end

function Action:createAction(args)
    args.action = nil
    args.id = nil

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
    local _detail, _err_msg = model:create(args)
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

function Action:nodeverifyAction(args)
    _print(args, true)
    local ip = args.ip
    local _id = args.id
    local _user_id = args.user_id

    if not ip then
        return {
            result = false,
            err_msg = "IP not defined"
        }
    end

    local _res, _err =
        httpc:request_uri(
        "https://" .. ip .. "/ping",
        {
            method = "GET",
            headers = {
                ["Host"] = "gw.mbr.massbitroute.com"
            },
            ssl_verify = false
        }
    )

    _print(_res, true)
    _print(_err, true)

    local _ret = {result = false}
    if _res and _res.status == 200 then
        local instance = self:getInstance()
        local model = Model:new(instance)
        model:update({id = _id, user_id = _user_id, status = 1})

        local jobs = instance:getJobs()
        local job = {
            action = "/jobs/" .. mytype .. ".generateconf",
            delay = 1,
            data = {
                id = _id,
                user_id = _user_id
            }
        }
        jobs:add(job)
        _ret = {result = true}
    end

    return _ret
end

function Action:getAction(args)
    _print(args, true)
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
    _print("user_id:" .. user_id)
    local model = Model:new(instance)

    local _v, _err_msg = model:get(args)

    local _result = {
        result = false,
        err_msg = _err_msg
    }
    if _v then
        _v = _norm(_v)

        _result = {
            result = true,
            data = _v
        }
    end
    instance:getRedis():setKeepAlive()
    return _result
end

function Action:adminupdateAction(args)
    _print(args, true)
    args.action = nil
    local instance = self:getInstance()
    local model = Model:new(instance)
    local _ok, _err = model:update(args)
    _print(
        {
            ok = _ok,
            err = _err
        },
        true
    )
    if _ok then
        local jobs = instance:getJobs()
        local job
        if tonumber(args.status) == 0 then
            args._is_delete = false
            job = {
                action = "/jobs/" .. mytype .. ".removeconf",
                delay = 1,
                data = args
            }
        else
            job = {
                action = "/jobs/" .. mytype .. ".generateconf",
                delay = 1,
                data = args
            }
        end
        jobs:add(job)
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
    local _ok, _err = jobs:add(job)
    return {
        ok = _ok,
        err = _err
    }
end

-- function Action:rescanconfAction(args)
--     local instance = self:getInstance()
--     local jobs = instance:getJobs()
--     local job = {
--         action = "/jobs/" .. mytype .. ".rescanconf",
--         delay = 0,
--         data = {}
--     }
--     local _ok, _err = jobs:add(job)
--     return {
--         ok = _ok,
--         err = _err
--     }
-- end
function Action:updateAction(args)
    -- ngx.log(ngx.ERR, "updateAction" .. inspect(args))
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

    _print("user_id:" .. user_id)
    -- args._is_approved = args._is_approved and tonumber(args._is_approved) == 1

    local model = Model:new(instance)
    local _detail, _err_msg = model:update(args)

    local _result
    if _detail then
        local jobs = instance:getJobs()
        local job
        if tonumber(args.status) == 0 then
            args._is_delete = false
            job = {
                action = "/jobs/" .. mytype .. ".removeconf",
                delay = 1,
                data = args
            }
        else
            job = {
                action = "/jobs/" .. mytype .. ".generateconf",
                delay = 1,
                data = args
            }
        end
        jobs:add(job)
        _result = {
            result = true
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

function Action:deleteAction(args)
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
    _print({ok = _ok, err = _err}, true)
    -- ngx.log(ngx.ERR, inspect({_ok, _err}))

    instance:getRedis():setKeepAlive()

    return {
        result = true
    }
end

function Action:listAction(args)
    args.action = nil
    local instance = self:getInstance()
    local _res = _authorize_whitelist(self, args)
    local user_id
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
    local _detail = model:list(args)
    local _ret = {}

    setmetatable(_ret, json.empty_array_mt)

    for _, _v in pairs(_detail) do
        if _v then
            _v = _norm(_v)
            _ret[#_ret + 1] = _v
        end
    end

    instance:getRedis():setKeepAlive()
    return {
        result = true,
        data = _ret
    }
end

--private

_opensession = function(instance, args)
    local sid = ngx.var.cookie__slc_web_sid or args.sid
    if not sid then
        return nil
    end

    local session = Session:new(instance:getRedis())
    if not session:start(sid) then
        return nil
    end

    return session
end

return Action
