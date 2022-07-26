local ngx, cc = ngx, cc
local Model = cc.class("Model")
local util = require "mbutil" -- cc.import("#mbrutil")
local json = cc.import("#json")
local inspect = require "inspect"
local _print = util.print
-- local unpack = table.unpack

function Model:ctor(instance)
    self._instance = instance
    self._redis = instance:getRedis()
end
function Model:_getall_key(key)
    -- util.print("key:" .. key)
    local _redis = self._redis
    local _ret = _redis:arrayToHash(_redis:hgetall(key))
    if not _ret or _ret == _redis.null then
        return nil
    end
    return _ret
end

function Model:_get_key(key, opt)
    -- _print("get_key:" .. key)
    -- _print(opt, true)
    local _redis = self._redis
    local _ret = _redis:hget(key, opt)
    if not _ret or _ret == _redis.null then
        return nil
    end
    return _ret
end
function Model:_del_key(key, opt)
    -- _print("del_key:" .. key)
    -- _print(opt, true)

    local _redis = self._redis
    local _ret = _redis:hdel(key, opt)
    if not _ret or _ret == _redis.null then
        return nil
    end
    return _ret
end

function Model:_save_key(key, args)
    -- _print("save_key:" .. key)
    -- _print(args, true)
    -- util.print("key:" .. key)
    -- util.print("opt:" .. inspect(args))
    local _redis = self._redis
    -- _print(inspect(_redis))

    -- local _res, _err
    -- _redis:initPipeline()
    -- for k, v in pairs(args) do
    --     _redis:hmset(key, k, v)
    --     -- _print("res:" .. inspect(_res))
    --     -- _print("err:" .. inspect(_err))
    -- end
    -- _redis:commitPipeline()
    local _data = _redis:hashToArray(args)
    -- _print("data type:" .. type(_data))
    -- _print("data:" .. inspect(_data))

    -- _redis:initPipeline()

    -- local _res, _err = _redis:hmset(key, "test", "ok", "test1", "ok1")
    local _res, _err = _redis:hmset(key, table.unpack(_data))
    -- _print({res = _res, err = _err}, true)
    -- _redis:commitPipeline()
    -- _print("res:" .. inspect(_res))
    -- _print("err:" .. inspect(_err))
end

function Model:save(model_type, args)
    -- _print("save:" .. model_type)
    -- _print(args, true)
    local _now = ngx and ngx.time() or os.time()
    args.updated_at = _now
    self:_save_key(model_type .. ":" .. args.id, args)
end

return Model
