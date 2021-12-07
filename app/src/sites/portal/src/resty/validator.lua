--  @file validator.lua
--  @brief 对反序列化（cjson.decode(json)）后的table进行检查，并根据
--         绑定的规则生成对应的table。
--  @author Chenglin Huang
--  @version 0.1
--  @date 2015-02-17
--


--[[

NUMBER - 数值类型
    绑定语法：
    <field> = {
        -- 数值类型（必填）
        type = validator.NUMBER,

        -- 默认值（可选，默认为 nil）
        default = 0,

        -- 是否必填项（可选，默认为 false）
        required = true,

        -- checker 执行前的处理函数，函数的返回值用作后续的处理（可选，默认无）
        -- 执行顺序：pre, checker, post
        pre = function(val) return dosth(val) end,

        -- 对填写的值进行校验，返回 res, err （可选，默认无）
        -- res: 校验的结果（true/false）
        -- err: 如果校验不通过（res = false）的错误提示信息，如果不填
        --      则使用 err_msg。
        checker = function(val, field) return docheck(val) end,

        -- checker 执行后的处理函数，函数的返回值作为最终 field 的值（可选，默认无）
        post = function(val) return dosth(val) end,
    }

STRING - 字符串类型
    绑定语法：
    <field> = {
        -- 数值类型（必填）
        type = validator.STRING,

        -- 默认值（可选，默认为 nil）
        default = "unknown",

        -- 是否必填项（可选，默认为 false）
        required = true,

        -- checker 执行前的处理函数，函数的返回值用作后续的处理（可选，默认无）
        -- 执行顺序：pre, minlength, maxlength, checker, post
        pre = function(val) return dosth(val) end,

        -- 最小长度（可选，默认 nil 无限制）
        minlength = 1,

        -- 最大长度（可选，默认 nil 无限制）
        maxlength = 5,

        -- 对填写的值进行校验，返回 res, err （可选，默认无）
        -- res: 校验的结果（true/false）
        -- err: 如果校验不通过（res = false）的错误提示信息，如果不填
        --      则使用 err_msg。
        checker = function(val, field) return docheck(val) end,

        -- checker 执行后的处理函数，函数的返回值作为最终 field 的值（可选，默认无）
        post = function(val) return dosth(val) end,
    }

OBJECT - 对象类型（对象成员的类型可以是任意类型（NUMBER, STRING, ...））
    绑定语法：
    <field> = {
        -- 数值类型（必填）
        type = validator.OBJECT,

        -- 默认值（可选，默认为 nil）
        default = { a = 1, b = 2 },

        -- 是否必填项（可选，默认为 false）
        required = true,

        -- 对象的结构（必填）
        struct = {

            -- 对象的成员，成员的类型可以为 NUMBER, STRING, OBJECT
            <member> = {
                type = STRING, -- 成员的类型，详见 STRING 类型的定义
                required = true,
                ...
            },
            ...
        }

        -- checker 执行前的处理函数，函数的返回值用作后续的处理（可选，默认无）
        -- 执行顺序：pre, checker, post
        pre = function(val) return dosth(val) end,

        -- 对填写的值进行校验，返回 res, err （可选，默认无）
        -- res: 校验的结果（true/false）
        -- err: 如果校验不通过（res = false）的错误提示信息，如果不填
        --      则使用 err_msg。
        checker = function(val, field) return docheck(val) end,

        -- checker 执行后的处理函数，函数的返回值作为最终 field 的值（可选，默认无）
        post = function(val) return dosth(val) end,
    }

ARRAY - 数组类型（数组元素的类型可以是任意类型（NUMBER, STRING, ...））
    绑定语法：
    <field> = {
        -- 数值类型（必填）
        type = validator.ARRAY,

        -- 默认值（可选，默认为 nil）
        default = {},

        -- 是否必填项（可选，默认为 false）
        required = true,

        -- 数组元素的结构（可以是任意类型）
        element = {
            type = NUMBER, -- 可以是任意类型，类型的绑定语法详见各类型的说明
            ...
        },

        -- checker 执行前的处理函数，函数的返回值用作后续的处理（可选，默认无）
        -- 执行顺序：pre, minlength, maxlength, checker, post
        pre = function(val) return dosth(val) end,

        -- 最小长度（可选，默认 nil 无限制）
        minlength = 1,

        -- 最大长度（可选，默认 nil 无限制）
        maxlength = 5,

        -- 对填写的值进行校验，返回 res, err （可选，默认无）
        -- res: 校验的结果（true/false）
        -- err: 如果校验不通过（res = false）的错误提示信息，如果不填
        --      则使用 err_msg。
        checker = function(val, field) return docheck(val) end,

        -- checker 执行后的处理函数，函数的返回值作为最终 field 的值（可选，默认无）
        post = function(val) return dosth(val) end,
    }

STRINGIFY_OBJECT - 字符串化的对象类型（对象成员的类型可以是任意类型（NUMBER, STRING, ...））
    如： module = "{\"type\":\"audio\",\"id\":1}"

    绑定语法：
    <field> = {
        -- 数值类型（必填）
        type = validator.STRINGIFY_OBJECT,

        -- NOTE: 其他定义与 OBJECT 相同
    }

STRINGIFY_ARRAY - 数组类型（数组元素的类型可以是任意类型（NUMBER, STRING, ...））
    如： lists = "[{\"type\":\"audio\",\"id\":1},{\"type\":\"album\",\"id\":2}]"

    绑定语法：
    <field> = {
        -- 数值类型（必填）
        type = validator.STRINGIFY_ARRAY,

        -- NOTE: 其他定义与 ARRAY 相同
    }
]]

local cjson = require("cjson")

local validator = {}

validator.NUMBER = 1
validator.STRING = 2
validator.OBJECT = 3
validator.ARRAY  = 4
validator.STRINGIFY_OBJECT = 5
validator.STRINGIFY_ARRAY  = 6

local handlers = {}

local function trim(s)
  return (s:gsub("^%s*(.-)%s*$", "%1"))
end

local function pre_check(field, bind, val)
    if not val then
        if bind.default then
            return true, bind.default -- 提供了默认值
        elseif bind.required then
            -- 错误，必填项
            local err = bind.err_msg or string.format("'%s' is required", field)
            return false, nil, err
        else
            return true, nil --  非必填
        end
    end

    return true, val
end


local function checker_err(field)
    return string.format("The '%s' contains invalid value", field)
end

local function minlength_err(field, minlength)
    return string.format("The '%s' mismatch the condition: length >= %d",
                        field, minlength)
end

local function maxlength_err(field, maxlength)
    return string.format("The '%s' mismatch the condition: length <= %d",
                        field, maxlength)
end


handlers[validator.NUMBER] = function(field, bind, val)
    local ok, val, err = pre_check(field, bind, val)
    if not ok then return false, nil, err end

    -- 非必填项
    if not val then return true, nil, nil end

    val = tonumber(val)
    if not val then return false, nil, field .. " isn't a valid number" end

    --if type(val) ~= "number" then
        --return false, nil, field .. " must be a number"
    --end

    if bind.pre then val = bind.pre(val) end

    if bind.checker then
        local ok, err = bind.checker(val, field)
        if not ok then
            return false, nil, err or bind.err_msg or checker_err(field)
        end
    end

    if bind.post then val = bind.post(val) end

    return true, val
end

handlers[validator.STRING] = function(field, bind, val)
    local ok, val, err = pre_check(field, bind, val)
    if not ok then return false, nil, err end

    -- 非必填项
    if not val then return true, nil, nil end

    --if type(val) ~= "string" then
        --return false, nil, field .. " must be a string"
    --end

    val = tostring(val)
    val = trim(val)

    if bind.pre then val = bind.pre(val) end

    if bind.minlength and #val < bind.minlength then
        return false, nil, bind.err_msg or minlength_err(field, bind.minlength)
    end

    if bind.maxlength and #val > bind.maxlength then
        return false, nil, bind.err_msg or maxlength_err(field, bind.maxlength)
    end

    if bind.checker then
        local ok, err = bind.checker(val, field)
        if not ok then
            return false, nil, err or bind.err_msg or checker_err(field)
        end
    end

    if bind.post then val = bind.post(val) end

    return true, val
end

handlers[validator.OBJECT] = function(field, bind, obj)
    local ok, obj, err = pre_check(field, bind, obj)
    if not ok then return false, nil, err end

    -- 非必填项
    if not obj then return true, nil, nil end

    if type(obj) ~= "table" then
        return false, nil, field .. " must be an object"
    end

    if bind.pre then obj = bind.pre(obj) end

    local res = {}
    for f,f_bind in pairs(bind.struct) do
        local handler = handlers[f_bind.type]
        local ok, val, err = handler(field .. "." .. f, f_bind, obj[f])
        if not ok then return false, nil, err end

        res[f] = val
    end

    local checker = bind.checker
    if checker then
        local ok, err = checker(res, field)
        if not ok then
            return false, nil, err or bind.err_msg or checker_err(field)
        end
    end

    if bind.post then res = bind.post(res) end

    return true, res
end

handlers[validator.ARRAY] = function(field, bind, array)
    local ok, array, err = pre_check(field, bind, array)
    if not ok then return false, nil, err end

    -- 非必填项
    if not array then return true, nil, nil end

    if type(array) ~= "table" then
        return false, nil, field .. " must be an array"
    end

    if bind.pre then array = bind.pre(array) end

    local len = #array

    if bind.minlength and len < bind.minlength then
        return false, nil, bind.err_msg or minlength_err(field, bind.minlength)
    end

    if bind.maxlength and len > bind.maxlength then
        return false, nil, bind.err_msg or maxlength_err(field, bind.maxlength)
    end

    local checker     = bind.checker
    local elem_type   = bind.element.type
    local elem_struct = bind.element

    local res = {}
    for index, elem in pairs(array) do

        local handler = handlers[elem_type]
        local f_elem = string.format("%s[%d]", field, index)
        local ok, val, err = handler(f_elem, elem_struct, elem)
        if not ok then return false, nil, err end

        if checker then
            local ok, err = checker(val, f_elem)
            if not ok then
                return false, nil, err or checker_err(f_elem)
            end
        end

        table.insert(res, val)
    end

    if bind.post then res = bind.post(res) end

    return true, res
end

handlers[validator.STRINGIFY_OBJECT] = function(field, bind, str)
    local ok, res = pcall(cjson.decode, str)
    if not ok then
        return false, nil, "invalid json object format"
    end

    return handlers[validator.OBJECT](field, bind, res)
end

handlers[validator.STRINGIFY_ARRAY] = function(field, bind, str)
    local ok, res = pcall(cjson.decode, str)
    if not ok then
        return false, nil, "invalid json array format"
    end

    return handlers[validator.ARRAY](field, bind, res)
end


function validator.bind(bindings, input)
    local res = {}
    for field, bind in pairs(bindings) do
        local handler = handlers[bind.type]
        local ok, val, err = handler(field, bind, input[field])
        if not ok then return false, nil, err end

        res[field] = val
    end

    return true, res
end

return validator
