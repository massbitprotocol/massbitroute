---
--- Created By 0xWaleed
--- DateTime: 5/4/21 12:42 AM
---

local function explode(string, sep)
    sep     = sep or '%s'
    local t = {}
    for str in string.gmatch(string, "([^" .. sep .. "]+)") do
        table.insert(t, str)
    end
    return t
end

local ValidationRuleMT   = {}
ValidationRuleMT.__index = ValidationRuleMT
ValidationRule           = setmetatable({}, ValidationRuleMT)

function ValidationRuleMT:validate(value)
    local handler = _G['rule_' .. self._ruleName]
    if not handler then
        error(('Rule [%s] has no handler.'):format(self._ruleName))
    end
    return handler(value, self._args)
end

function ValidationRule.new(ruleLine)
    local o = {}
    setmetatable(o, ValidationRuleMT)

    local st       = explode(ruleLine, ':')

    local ruleName = st[1]
    local args     = {}

    if st[2] then
        args = explode(st[2], ',?%s')
    end

    o._ruleName = ruleName
    o._args     = args

    return o
end

local VarGuardMT   = {}
VarGuardMT.__index = VarGuardMT

function VarGuardMT:_getValueOfAttribute(attribute)
    local keys = explode(attribute, '.')

    local data = self._input
    if #keys < 2 and data[attribute] then
        return data[attribute]
    end

    local captured = data
    for _, key in ipairs(keys) do

        if type(captured) == 'table' and captured[key] then
            captured = captured[key]
        else
            return nil
        end

    end

    return captured
end

function VarGuardMT:_mapRules()
    local rules = self._rules
    local out   = {}
    for key, rule in pairs(rules) do
        out[key] = explode(rule, '|')
    end
    return out
end

function VarGuardMT:validate()
    if not self._input then
        return false, 'Input is nil'
    end
    local mappedRules = self:_mapRules()
    local errors      = {}
    for attribute, rules in pairs(mappedRules) do

        for _, rule in ipairs(rules) do

            local value = self:_getValueOfAttribute(attribute)

            if not ValidationRule.new(rule):validate(value) then
                local msg = ('Rule [%s] returned falsy for `%s`.'):format(rule, attribute)
                table.insert(errors, msg)
            end

        end
    end
    self._errors = errors
    if #errors > 0 then
        return false, errors[1]
    end
    return true, self._input
end

function VarGuardMT:passes()
    local isValid = self:validate()
    return isValid == true
end

function VarGuardMT:fails()
    return not self:passes()
end

function VarGuardMT:errors()
    self:validate()
    return self._errors
end

function VarGuardMT:first()
    return self:errors()[1]
end

function VarGuard(rules, input)
    if type(rules) ~= 'table' then
        error('Rules is not table, ' .. type(rules) .. ' given.')
    end
    local o = {}
    setmetatable(o, VarGuardMT)
    o._rules  = rules
    o._input  = input
    o._errors = {}
    return o
end

function varguard_verify(rules, input)
    local v = VarGuard(rules, input)
    return v:validate()
end

function rule_required(input)
    return input ~= nil and input ~= ''
end

function rule_type(input, types)
    for _, t in ipairs(types) do
        if type(input) == t then
            return true
        end
    end
    return false
end

function rule_callable(input)
    local typeOfInput = type(input)
    if typeOfInput == 'function' then
        return true
    end

    if typeOfInput ~= 'table' then
        return false
    end

    local mt = getmetatable(input)

    if not mt then
        return false
    end

    return mt.__call ~= nil and type(mt.__call) == 'function'
end

function rule_max(input, args)
    local max = args[1]
    if not max then
        return false
    end

    max = tonumber(max)

    if not max then
        return false
    end

    return input <= max
end

function rule_min(input, args)
    local min = args[1]
    if not min then
        return false
    end

    min = tonumber(min)

    if not min then
        return false
    end

    return input >= min
end
