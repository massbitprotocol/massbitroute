local ngx, cc = ngx, cc
local Node = cc.class("Node")
local json = cc.import("#json")

local model_type = "node"

local Model = cc.import("#model")
local util = require "mbutil"

function Node:ctor(instance)
    self._instance = instance
    self._redis = instance:getRedis()
    self._model = Model:new(instance)
end

function Node:create(args)
    args.action = nil
    local user_id = args.user_id
    if not user_id then
        return
    end
    local _now = ngx and ngx.time() or os.time()

    args.status = 0

    args.id = args.id or util.get_uuid(_now)
    args.created_at = _now
    local _ret = self._model:_save_key(user_id .. ":" .. model_type, {[args.id] = json.encode(args)})

    return _ret and args or nil
end

function Node:update(args)
    args.action = nil
    local user_id = args.user_id
    local id = args.id
    if not id or not user_id then
        return
    end
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
function Node:delete(args)
    args.action = nil

    local user_id = args.user_id
    if not user_id then
        return
    end
    local _ret = self._model:_del_key(user_id .. ":" .. model_type, args.id)
    return _ret ~= nil
end

function Node:list(args)
    args.action = nil
    local user_id = args.user_id
    if not user_id then
        return
    end
    local _ret = self._model:_getall_key(user_id .. ":" .. model_type)
    return _ret
end
function Node:get(args)
    local user_id = args.user_id
    if not user_id then
        return
    end
    local _ret = self._model:_get_key(user_id .. ":" .. model_type, args.id)

    return _ret
end

return Node
