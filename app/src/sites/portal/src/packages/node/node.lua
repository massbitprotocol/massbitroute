local ngx, cc = ngx, cc
local Node = cc.class("Node")
local json = cc.import("#json")

local model_type = "node"

local Model = cc.import("#model")
local util = cc.import("#mbrutil")
-- local uuid = require "jit-uuid"

function Node:ctor(instance)
    self._instance = instance
    self._redis = instance:getRedis()
    self._model = Model:new(instance)
end

function Node:create(args)
    local user_id = args.user_id
    local _now = ngx and ngx.time() or os.time()
    -- uuid.seed(_now)

    args.status = 0
    -- args.id = uuid()
    args.id = util.get_uuid(_now)
    args.created_at = _now
    self._model:_save_key(user_id .. ":" .. model_type, {[args.id] = json.encode(args)})

    return args
end

function Node:update(args)
    local user_id = args.user_id
    local id = args.id
    local _detail = self._model:_get_key(user_id .. ":" .. model_type, id)
    if _detail then
        _detail = json.decode(_detail)
        table.merge(_detail, args)
        local _now = ngx and ngx.time() or os.time()
        _detail.updated_at = _now
        self._model:_save_key(user_id .. ":" .. model_type, {[_detail.id] = json.encode(_detail)})
    end

    return _detail
end
function Node:delete(args)
    local user_id = args.user_id
    self._model:_del_key(user_id .. ":" .. model_type, args.id)
    return args
end

function Node:list(args)
    local user_id = args.user_id
    local _res = self._model:_getall_key(user_id .. ":" .. model_type)
    return _res
end
function Node:get(args)
    local user_id = args.user_id
    local _detail = self._model:_get_key(user_id .. ":" .. model_type, args.id)
    return _detail
end

return Node
