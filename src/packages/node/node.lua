local ngx, cc = ngx, cc
local Node = cc.class("Node")
local json = cc.import("#json")

local model_type = "node"

local Model = cc.import("#model")
local util = require "mbutil" -- cc.import("#mbrutil")
local inspect = require "inspect"
local _print = util.print
-- local uuid = require "jit-uuid"

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
    -- uuid.seed(_now)

    args.status = 0
    -- args.id = uuid()
    args.id = args.id or util.get_uuid(_now)
    args.created_at = _now
    self._model:_save_key(user_id .. ":" .. model_type, {[args.id] = json.encode(args)})

    return args
end

function Node:update(args)
    args.action = nil
    local user_id = args.user_id
    local id = args.id
    if not id or not user_id then
        return
    end
    local _detail = self._model:_get_key(user_id .. ":" .. model_type, id)
    if not _detail then
        return
    end

    if _detail then
        _detail = json.decode(_detail)
    else
        _detail = {}
    end
    table.merge(_detail, args)

    _detail.action = nil
    local _now = ngx and ngx.time() or os.time()
    _detail.updated_at = _now
    self._model:_save_key(user_id .. ":" .. model_type, {[_detail.id] = json.encode(_detail)})
    return _detail
end
function Node:delete(args)
    args.action = nil
    _print(inspect(args))
    local user_id = args.user_id
    if not user_id then
        return
    end
    self._model:_del_key(user_id .. ":" .. model_type, args.id)
    return args
end

function Node:list(args)
    args.action = nil
    local user_id = args.user_id
    if not user_id then
        return
    end
    local _res = self._model:_getall_key(user_id .. ":" .. model_type)
    return _res
end
function Node:get(args)
    _print(args, true)
    -- args.action = nil
    local user_id = args.user_id
    if not user_id then
        return
    end
    local _detail = self._model:_get_key(user_id .. ":" .. model_type, args.id)
    _print(_detail, true)
    return _detail
end

return Node
