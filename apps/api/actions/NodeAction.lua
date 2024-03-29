local cc, ndk, ngx = cc, ndk, ngx
local gbc = cc.import("#gbc")
local mytype = "node"
local Session = cc.import("#session")
local env = require("env")
local json = cc.import("#json")
local util = require "mbutil" -- cc.import("#mbrutil")
-- local cjson = require "cjson"
local Action = cc.class(mytype .. "Action", gbc.ActionBase)

-- local httpc = require("resty.http").new()
local inspect = require "inspect"

local httpc = require("resty.http").new()

local set_var = ndk.set_var

local ngx_log = ngx.log
local _opensession
-- local _print = util.print
-- local mkdirp = require "mkdirp"
local ERROR = {
    NOT_LOGIN = 100
}
local Model = cc.import("#" .. mytype)

-- local _get_geo = util.get_geo
local _authorize_whitelist = util.authorize_whitelist
local _server_name = env.DOMAIN or "massbitroute.com"
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

function Action:geonodecountryAction()
    ngx.log(ngx.ERR, "geonodecity")
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
    -- ngx.log(ngx.ERR, "geonodecity")
    local _datacenters = {}
    local instance = self:getInstance()
    local _red = instance:getRedis()
    local _user_gw = _red:keys("*:" .. mytype)
    -- ngx.log(ngx.ERR, inspect(_user_gw))
    for _, _k in ipairs(_user_gw) do
        local _gw_arr = _red:arrayToHash(_red:hgetall(_k))
        -- ngx.log(ngx.ERR, inspect(_gw_arr))
        for _, _gw_str in pairs(_gw_arr) do
            local _gw = json.decode(_gw_str)
            if _gw.geo and _gw.geo.continent_code then
                _datacenters[_gw.geo.continent_code] = _datacenters[_gw.geo.continent_code] or 0
                _datacenters[_gw.geo.continent_code] = _datacenters[_gw.geo.continent_code] + 1
            -- table.insert(_datacenters[_gw.geo.continent_code][_gw.geo.country_code], _gw)
            end
        end
    end
    ngx.log(ngx.ERR, inspect(_datacenters))
    return {
        result = true,
        data = _datacenters
    }
end

--- Ping node

function Action:pingAction(args)
    -- ngx.log(ngx.ERR, "ping")
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
    -- ngx.log(ngx.ERR, "id:" .. id)
    if not id or id ~= args.id then
        return {result = false, err_msg = "Token not correct"}
    end
    local _data = {
        id = id,
        user_id = user_id
    }

    local model = Model:new(instance)
    model:update(_data)
    return {result = true}
end

--- Register node

function Action:registerAction(args)
    ngx_log(ngx.ERR, "[request]:" .. inspect(args))
    -- _print(inspect(args))
    args.action = nil
    local _token = args.token
    if not _token then
        return {result = false, err_msg = "Token missing"}
    end
    local instance = self:getInstance()
    -- local _config = self:getInstanceConfig()
    local id = args.id
    local user_id = args.user_id
    if not user_id then
        return {result = false, err_msg = "User ID missing"}
    end

    args.status = 1
    args.approved = 0
    args._is_delete = false
    ngx_log(ngx.ERR, "[args]:" .. inspect(args))
    local model = Model:new(instance)

    local _detail, _err_msg = model:update(args)
    ngx_log(ngx.ERR, "[item]:" .. inspect(_detail))
    local _result = {
        result = true
    }
    if _detail then
        -- if _job_id and tonumber(_job_id) > 0 then
        --     _result = {
        --         result = true
        --     }
        -- end
        local jobs = instance:getJobs()
        local job = {
            action = "/jobs/" .. mytype .. ".generateconf",
            delay = 0,
            data = args
        }
        local _job_id = jobs:add(job)
        ngx_log(ngx.ERR, "[job_id]:" .. inspect(_job_id))
    else
        _result = {
            result = false,
            err_msg = _err_msg
        }
    end
    ngx_log(ngx.ERR, "[response]:" .. inspect(_result))
    return _result
end

-- function Action:nodeverifyAction(args)
--     -- _print(inspect(args))
--     -- local _config = self:getInstanceConfig()
--     -- _print(args, true)
--     local _ip = args.ip
--     local _id = args.id
--     local _user_id = args.user_id

--     if not _ip then
--         return {
--             result = false,
--             err_msg = "IP not defined"
--         }
--     end

--     local _res =
--         httpc:request_uri(
--         "https://" .. _ip .. "/ping",
--         {
--             method = "GET",
--             headers = {
--                 ["Host"] = "node.mbr." .. _server_name
--             },
--             ssl_verify = false
--         }
--     )

--     -- _print(_res, true)
--     -- _print(_err, true)
--     local _ret = {result = false}
--     if _res and _res.status == 200 then
--         local instance = self:getInstance()
--         local model = Model:new(instance)
--         model:update({id = _id, user_id = _user_id, status = 1})

--         local jobs = instance:getJobs()
--         local job = {
--             action = "/jobs/" .. mytype .. ".generateconf",
--             delay = 0,
--             data = {
--                 id = _id,
--                 user_id = _user_id
--             }
--         }
--         jobs:add(job)
--         _ret = {result = true}
--     end

--     return _ret
--     --{result = _res and _res.status == 200}
-- end

function Action:unregisterAction(args)
    -- _print(inspect(args))
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

    -- ip = "34.124.167.144"
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
        delay = 0,
        data = {
            _is_delete = true,
            id = id,
            user_id = user_id
        }
    }
    local _ok, _err = jobs:add(job)
    ngx.log(ngx.ERR, {ok = _ok, err = _err}, true)
    return {result = true}
end

function Action:createAction(args)
    ngx_log(ngx.ERR, "[request]:" .. inspect(args))
    -- _print(inspect(args))
    args.action = nil
    -- args.id = nil

    local instance = self:getInstance()
    local _config = self:getInstanceConfig()
    local _res = _authorize_whitelist(_config, args)
    -- _print("_authorize_whitelist:" .. inspect(_res))
    local ip = args.geo and args.geo.ip or ngx.var.realip
    if ip then
        args.ip = ip
    end

    if not args.data_url then
        args.data_url = "http://127.0.0.1:8545"
    end

    if not args.data_ws then
        args.data_ws = "http://127.0.0.1:8546"
    end

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

    -- _print("user_id:" .. user_id)
    local model = Model:new(instance)

    args.status = 0
    args.approved = 0

    local _detail, _err_msg = model:create(args)
    local _result = {
        result = true,
        data = _detail
    }
    if not _detail then
        _result = {
            result = false,
            err_msg = _err_msg
        }
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
    local _config = self:getInstanceConfig()
    local _res = _authorize_whitelist(_config, args)
    -- _print("_authorize_whitelist:" .. inspect(_res))
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

    -- _print("user_id:" .. user_id)
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
    ngx_log(ngx.ERR, "[response]:" .. inspect(_result))
    return _result
end

-- function Action:admingetAction(args)
--     local instance = self:getInstance()
--     local model = Model:new(instance)
--     local _ok, _err = model:get(args)

--     return {
--         ok = _ok,
--         err = _err
--     }
-- end
function Action:adminupdateAction(args)
    -- _print(inspect(args))
    args.action = nil
    local instance = self:getInstance()
    local model = Model:new(instance)
    local _ok, _err = model:update(args)
    local result = {
        ok = _ok,
        err = _err
    }
    -- _print("result:" .. inspect(result))
    if _ok then
        local jobs = instance:getJobs()
        local job
        if tonumber(args.status) == 0 then
            args._is_delete = false
            job = {
                action = "/jobs/" .. mytype .. ".removeconf",
                delay = 0,
                data = args
            }
        else
            job = {
                action = "/jobs/" .. mytype .. ".generateconf",
                delay = 0,
                data = args
            }
        end
        jobs:add(job)
    end

    return result
end

-- local _portal_dir = "/massbit/massbitroute/app/src/sites/services/api"
-- local _deploy_dir = _portal_dir .. "/public/deploy/dapi"
-- local _write_file = util.write_file
-- local function _export_data(model, args)
--     local _item = _norm(model:get(args))
--     table.merge(_item, args)
--     local _item_path =
--         table.concat(
--         {
--             _deploy_dir,
--             _item.blockchain,
--             _item.network,
--             _item.geo.continent_code,
--             _item.geo.country_code,
--             _item.user_id
--         },
--         "/"
--     )
--     mkdirp(_item_path)
--     local _deploy_file = _item_path .. "/" .. _item.id
--     _print(mytype .. ":deploy_file:" .. _deploy_file)
--     _print(_item, true)
--     _write_file(_deploy_file, json.encode(_item))
-- end

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

function Action:calljobAction(args)
    -- _print(inspect(args))
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
function Action:deleteAction(args)
    ngx_log(ngx.ERR, "[request]:" .. inspect(args))
    -- _print(inspect(args))
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
    local _res = _authorize_whitelist(_config, args)
    -- _print("_authorize_whitelist:" .. inspect(_res))
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
        delay = 0,
        data = {
            _is_delete = true,
            id = args.id,
            user_id = user_id
        }
    }
    local _ok, _err = jobs:add(job)
    ngx.log(ngx.ERR, {ok = _ok, err = _err}, true)
    instance:getRedis():setKeepAlive()
    local _result = {
        result = true
    }
    ngx_log(ngx.ERR, "[response]:" .. inspect(_result))
    return _result
end

function Action:updateAction(args)
    ngx_log(ngx.ERR, "[request]:" .. inspect(args))
    -- _print(inspect(args))
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
    local _res = _authorize_whitelist(_config, args)

    -- _print("_authorize_whitelist:" .. inspect(_res))
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
    -- _export_data(model, args)
    local _result = {
        result = true
    }
    if _detail then
        local jobs = instance:getJobs()

        local job
        if tonumber(args.status) == 0 then
            args._is_delete = false
            job = {
                action = "/jobs/" .. mytype .. ".removeconf",
                delay = 0,
                data = args
            }
        else
            job = {
                action = "/jobs/" .. mytype .. ".generateconf",
                delay = 0,
                data = args
            }
        end
        jobs:add(job)
    else
        _result = {
            result = false,
            err_msg = _err_msg
        }
    end
    -- _print("_result:" .. inspect(_result))
    ngx_log(ngx.ERR, "[response]:" .. inspect(_result))
    instance:getRedis():setKeepAlive()
    return _result
end

function Action:listAction(args)
    -- _print(inspect(args))
    args.action = nil
    local instance = self:getInstance()
    local user_id
    local _config = self:getInstanceConfig()
    local _res = _authorize_whitelist(_config, args)
    -- _print("_authorize_whitelist:" .. inspect(_res))
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
    -- local sid = args.sid
    --  sid = sid or ngx.var.cookie__slc_web_sid
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
