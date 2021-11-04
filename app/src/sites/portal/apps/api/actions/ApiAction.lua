local gbc = cc.import("#gbc")
local mytype = "api"
local Session = cc.import("#session")

local json = cc.import("#json")
local cjson = require "cjson"
local Action = cc.class(mytype .. "Action", gbc.ActionBase)

local _opensession

local ERROR = {
    NOT_LOGIN = 100
}
local Model = cc.import("#" .. mytype)

local _user

function Action:createAction(args)
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
    local _detail = model:create(args)
    return {
        result = true
    }
end

function Action:updateAction(args)
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

function Action:deleteAction(args)
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
    local _detail = model:delete(args)
    return {
        result = true
    }
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

    for i, v in pairs(_detail) do
        if v then
            _res[#_res + 1] = json.decode(v)
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
        cc.throw("session is expired, or invalid session id")
        return nil
    end

    return session
end

return Action
