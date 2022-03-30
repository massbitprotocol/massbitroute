local ngx, cc = ngx, cc
local Gateway = cc.class("Gateway")
local json = cc.import("#json")
local util = require "mbutil" -- cc.import("#mbrutil")

local model_type = "gateway"

local Model = cc.import("#model")
-- local uuid = require "jit-uuid"

function Gateway:ctor(instance)
    self._instance = instance
    self._redis = instance:getRedis()
    self._model = Model:new(instance)
end
function Gateway:create(args)
    args.action = nil
    local user_id = args.user_id
    --    args.id = objectid.generate_id(model_id)
    local _now = ngx and ngx.time() or os.time()
    -- uuid.seed(_now)

    args.status = 0
    -- args.id = uuid()
    args.id = args.id or util.get_uuid(_now)
    args.created_at = _now

    self._model:_save_key(user_id .. ":" .. model_type, {[args.id] = json.encode(args)})
    return args
end

function Gateway:update(args)
    args.action = nil
    local user_id = args.user_id
    local id = args.id
    local _detail = self._model:_get_key(user_id .. ":" .. model_type, id)

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
function Gateway:delete(args)
    args.action = nil
    local user_id = args.user_id
    self._model:_del_key(user_id .. ":" .. model_type, args.id)
    return args
end

function Gateway:list(args)
    args.action = nil
    local user_id = args.user_id
    local _res = self._model:_getall_key(user_id .. ":" .. model_type)
    return _res
end
function Gateway:get(args)
    args.action = nil
    local user_id = args.user_id
    local _detail = self._model:_get_key(user_id .. ":" .. model_type, args.id)
    return _detail
end

return Gateway
