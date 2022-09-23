local ngx, cc = ngx, cc
local Gateway = cc.class("Gateway")
local json = cc.import("#json")
local util = require "mbutil"

local model_type = "gateway"

local Model = cc.import("#model")

function Gateway:ctor(instance)
    self._instance = instance
    self._redis = instance:getRedis()
    self._model = Model:new(instance)
end
function Gateway:create(args)
    args.action = nil
    local user_id = args.user_id

    local _now = ngx and ngx.time() or os.time()

    args.status = 0

    args.id = args.id or util.get_uuid(_now)
    args.created_at = _now

    local _ret = self._model:_save_key(user_id .. ":" .. model_type, {[args.id] = json.encode(args)})
    return _ret and args or nil
end

function Gateway:update(args)
    args.action = nil
    local user_id = args.user_id
    local id = args.id
    local _detail = self._model:_get_key(user_id .. ":" .. model_type, id)

    -- if not _detail then
    --     return
    -- end

    if _detail then
        _detail = json.decode(_detail)
    else
        _detail = {}
    end
    table.merge(_detail, args)

    _detail.action = nil
    local _now = ngx and ngx.time() or os.time()
    _detail.updated_at = _now
    local _ret = self._model:_save_key(user_id .. ":" .. model_type, {[_detail.id] = json.encode(_detail)})

    return _ret and _detail or nil
end
function Gateway:delete(args)
    args.action = nil
    local user_id = args.user_id
    local _ret = self._model:_del_key(user_id .. ":" .. model_type, args.id)
    return _ret ~= nil
end

function Gateway:list(args)
    args.action = nil
    local user_id = args.user_id
    local _ret = self._model:_getall_key(user_id .. ":" .. model_type)
    return _ret
end
function Gateway:get(args)
    args.action = nil
    local user_id = args.user_id
    local _ret = self._model:_get_key(user_id .. ":" .. model_type, args.id)
    return _ret
end

return Gateway
