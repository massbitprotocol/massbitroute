local Api = cc.class("Api")
local json = cc.import("#json")

local model_type = "api"
local util = require "mbutil" -- cc.import("#mbrutil")

local Model = cc.import("#model")
-- local uuid = require "jit-uuid"

function Api:ctor(instance)
    self._instance = instance
    self._redis = instance:getRedis()
    self._model = Model:new(instance)
end
function Api:create(args)
    args.action = nil
    local user_id = args.user_id
    -- args.id = objectid.generate_id(model_id)
    local _now = ngx and ngx.time() or os.time()
    -- uuid.seed(_now)
    -- args.id = uuid()
    args.id = args.id or util.get_uuid(_now)
    args.api_key = args.app_key or args.id
    -- args.api_key = uuid()
    args.status = 1
    args.app_id = args.app_id or util.random_string(12)
    if args.blockchain and args.network then
        args.gateway_domain = args.app_id .. "." .. args.blockchain .. "-" .. args.network .. "." .. args.server_name
        args.gateway_url = args.gateway_domain .. "/" .. args.api_key .. "/"
        args.gateway_http = "https://" .. args.gateway_url
        args.gateway_wss = "wss://" .. args.gateway_url
    end

    args.created_at = _now

    self._model:_save_key(user_id .. ":" .. model_type, {[args.id] = json.encode(args)})
    return args
end

function Api:update(args)
    args.action = nil
    local user_id = args.user_id
    local _detail = self._model:_get_key(user_id .. ":" .. model_type, args.id)

    if _detail then
        _detail = json.decode(_detail)
        table.merge(_detail, args)
    end

    _detail.action = nil
    local _now = ngx and ngx.time() or os.time()
    _detail.updated_at = _now
    self._model:_save_key(user_id .. ":" .. model_type, {[_detail.id] = json.encode(_detail)})

    return _detail
end
function Api:delete(args)
    args.action = nil
    local user_id = args.user_id
    self._model:_del_key(user_id .. ":" .. model_type, args.id)
    return args
end

function Api:list(args)
    args.action = nil
    local user_id = args.user_id
    local _res = self._model:_getall_key(user_id .. ":" .. model_type)
    return _res
end
function Api:get(args)
    args.action = nil
    local user_id = args.user_id
    local _detail = self._model:_get_key(user_id .. ":" .. model_type, args.id)
    return _detail
end

return Api
