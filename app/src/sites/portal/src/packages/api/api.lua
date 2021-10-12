local User = cc.class("Api")
local json = cc.import("#json")
local crypto = require "crypto"
local objectid = require "objectid"

local model_type = "api"
local model_id = 2000
local Model = cc.import("#model")
local uuid = require "jit-uuid"

function User:ctor(instance)
    self._instance = instance
    self._redis = instance:getRedis()
    self._model = Model:new(instance)
end
function User:create(args)
    args.id = objectid.generate_id(model_id)
    local _now = ngx and ngx.time() or os.time()
    uuid.seed(_now)
    args.api_key = uuid()
    args.status = 1

    args.created_at = now
    self._model:_save_key(model_type, {[args.id] = json.encode(args)})
    -- self._model:_save_key(model_type .. ":" .. model_type, {[args.domain] = args.id})
    return args
end

function User:update(args)
    local _detail = self._model:_get_key(model_type, args.id)

    if _detail then
        _detail = json.decode(_detail)
        ngx.log(ngx.ERR, json.encode(_detail))
        if _detail.domain ~= args.domain then
            self._model:_del_key(model_type .. ":" .. model_type, _detail.domain)
            self._model:_save_key(model_type .. ":" .. model_type, {[args.domain] = args.id})
        end
        table.merge(_detail, args)
        self._model:_save_key(model_type, {[_detail.id] = json.encode(_detail)})
    end

    return _detail
end
function User:delete(args)
    self._model:_del_key(model_type, args.id)
    self._model:_del_key(model_type .. ":" .. model_type, args.domain)
    return args
end

function User:list(args)
    local _res = self._model:_getall_key(model_type)
    return _res
end

return User
