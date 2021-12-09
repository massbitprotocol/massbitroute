local gbc = cc.import("#gbc")
local mytype = "gateway"
local Session = cc.import("#session")

local json = cc.import("#json")
local cjson = require "cjson"
local Action = cc.class(mytype .. "Action", gbc.ActionBase)

local httpc = require("resty.http").new()
local inspect = require "inspect"

local _opensession

local ERROR = {
    NOT_LOGIN = 100
}
local Model = cc.import("#" .. mytype)

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
    _norm_json(_v, "geo")
    return _v
end

local function _get_geo(ip)
    local _api_url = "http://api.ipapi.com/api/" .. ip .. "?access_key=092142b61eed12af33e32fc128295356"
    ngx.log(ngx.ERR, inspect(_api_url))
    local _res, _err = httpc:request_uri(_api_url, {method = "GET"})
    local _resb = _res.body
    if _res.status == 200 and _resb and type(_resb) == "string" then
        _resb = json.decode(_resb)
    end
    return _resb, _err
end

function Action:pingAction(args)
    ngx.log(ngx.ERR, "ping")
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

    ngx.log(ngx.ERR, "user_id:" .. user_id)

    local token = ndk.set_var.set_decode_base32(_token)
    local id = ndk.set_var.set_decrypt_session(token)
    ngx.log(ngx.ERR, "id:" .. id)
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

--- Register gateway

function Action:registerAction(args)
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

    local token = ndk.set_var.set_decode_base32(_token)
    local id = ndk.set_var.set_decrypt_session(token)

    if not id or id ~= args.id then
        return {result = false, err_msg = "Token not correct"}
    end
    local ip = ngx.var.realip
    ngx.log(ngx.ERR, "ip:" .. ip)
    ngx.log(ngx.ERR, "id:" .. id)
    -- ip = "34.124.167.144"
    local _data = {
        id = id,
        token = _token,
        user_id = user_id,
        ip = ip,
        status = 1
    }
    local _geo = _get_geo(ip)

    if _geo then
        _data.geo = _geo
    end

    local model = Model:new(instance)
    model:update(_data)

    local jobs = instance:getJobs()
    local job = {
        action = "/jobs/" .. mytype .. ".generateconf",
        delay = 3,
        data = {
            id = id,
            user_id = user_id
        }
    }
    local ok, err = jobs:add(job)

    return {result = true}
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
    ngx.log(ngx.ERR, "updateAction")
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

    -- local _data = model:get(args)

    -- if type(_data) == "string" then
    --     _data = json.decode(_data)
    -- end
    -- ngx.log(ngx.ERR, inspect(_data))
    -- if _data.geo and _data.geo.continent_code and _data.geo.country_code then
    --     local _conf_file =
    --         "/massbit/massbitroute/app/src/sites/services/gwman/data/" ..
    --         mytype .. "/mbr-map/" .. _data.blockchain .. "/" .. _data.network
    --     -- for _, dc in ipairs({"HCM", "Ha-Noi"}) do
    --     local _file = table.concat({_conf_file, _data.geo.continent_code, _data.geo.country_code, _data.id}, "/")
    --     ngx.log(ngx.ERR, inspect(_file))
    --     -- _files[#_files + 1] = _file
    --     -- _write_template(
    --     --     {
    --     --         [_file] = ip
    --     --     }
    --     -- )

    --     local _cmd =
    --         ngx.var.site_root ..
    --         "/scripts/run _" ..
    --             mytype ..
    --                 "_unregister " ..
    --                     table.concat({_data.ip, _data.id, _data.blockchain, _data.network}, " ") .. " " .. _file
    --     ngx.log(ngx.ERR, _cmd)
    --     _run_shell(_cmd)
    -- end

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
        -- cc.throw("session is expired, or invalid session id")
        return nil
    end

    return session
end

return Action
