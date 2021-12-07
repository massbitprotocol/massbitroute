local ngx, cc = ngx, cc
local Model = cc.class("Model")
-- local json = cc.import("#json")

function Model:ctor(instance)
    self._instance = instance
    self._redis = instance:getRedis()
end
function Model:_getall_key(key)
    local _redis = self._redis
    local _ret = _redis:arrayToHash(_redis:hgetall(key))
    if not _ret or _ret == _redis.null then
        return nil
    end
    return _ret
end

function Model:_get_key(key, opt)
    local _redis = self._redis
    local _ret = _redis:hget(key, opt)
    if not _ret or _ret == _redis.null then
        return nil
    end
    return _ret
end
function Model:_del_key(key, opt)
    local _redis = self._redis
    local _ret = _redis:hdel(key, opt)
    if not _ret or _ret == _redis.null then
        return nil
    end
    return _ret
end

function Model:_save_key(key, args)
    local _redis = self._redis
    local _data = _redis:hashToArray(args)
    _redis:initPipeline()
    _redis:hmset(key, unpack(_data))
    _redis:commitPipeline()
end

function Model:save(model_type, args)
    local _now = ngx and ngx.time() or os.time()
    args.updated_at = _now
    self:_save_key(model_type .. ":" .. args.id, args)
end

return Model
