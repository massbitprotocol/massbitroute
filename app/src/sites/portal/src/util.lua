local charset = {}
do -- [0-9a-zA-Z]
    for c = 48, 57 do
        table.insert(charset, string.char(c))
    end
    --    for c = 65, 90  do table.insert(charset, string.char(c)) end
    for c = 97, 122 do
        table.insert(charset, string.char(c))
    end
end

local function randomString(length)
    if not length or length <= 0 then
        return ""
    end
    math.randomseed(os.clock() ^ 5)
    return randomString(length - 1) .. charset[math.random(1, #charset)]
end

function string:trim()
    return (self:gsub("^%s*(.-)%s*$", "%1"))
end

function string:charAt(i)
    return self:sub(i, i)
end

local function table_merge(t1, t2, overwrite)
    if not overwrite then
        overwrite = false
    end
    for k, v in pairs(t2) do
        if overwrite then
            t1[k] = v
        else
            if not t1[k] then
                t1[k] = v
            end
        end
    end
    return t1
end

function string:indexOf(s, i)
    return self:find(s, i, true)
end

function string:replace(x, y, isPlainString)
    local iteratorIndex = 1
    local substrings = {}

    repeat
        local from, to = self:find(x, iteratorIndex, isPlainString)

        if from then
            substrings[#substrings + 1] = self:sub(iteratorIndex, from - 1)
            substrings[#substrings + 1] = y
            iteratorIndex = to + 1
        else
            substrings[#substrings + 1] = self:sub(iteratorIndex, self:len())
        end
    until from == nil

    return table.concat(substrings) -- concatenate all substrings
end

function string:replaceQuery(x, y, isPlainString, isIgnoreCase)
    if isIgnoreCase then
        require "utf8"

        local lowerSelf, lowerX
        if string.isascii(x) then
            lowerSelf = string.lower(self)
            lowerX = string.lower(x)
        else
            lowerSelf = string.utf8lower(self)
            lowerX = string.utf8lower(x)
        end

        local iteratorIndex = 1
        local substrings = {}

        repeat
            local from, to = lowerSelf:find(lowerX, iteratorIndex, isPlainString)

            if from then
                substrings[#substrings + 1] = self:sub(iteratorIndex, from - 1)
                substrings[#substrings + 1] = y
                iteratorIndex = to + 1
            else
                substrings[#substrings + 1] = self:sub(iteratorIndex, self:len())
            end
        until from == nil

        return table.concat(substrings) -- concatenate all substrings
    else
        return self:replace(x, y, isPlainString)
    end
end

function string:findQuery(x, iteratorIndex, isPlainString, isIgnoreCase)
    if isIgnoreCase then
        require "utf8"

        local lowerSelf, lowerX
        if string.isascii(x) then
            lowerSelf = string.lower(self)
            lowerX = string.lower(x)
        else
            lowerSelf = string.utf8lower(self)
            lowerX = string.utf8lower(x)
        end

        local from, to = lowerSelf:find(lowerX, iteratorIndex, isPlainString)
        return from, to
    else
        local from, to = self:find(x, iteratorIndex, isPlainString)
        return from, to
    end
end

local function hex_to_char(x)
    return string.char(tonumber(x, 16))
end

local function unescape(url)
    return url:gsub("%%(%x%x)", hex_to_char)
end

local function isNotEmpty(s)
    return s ~= nil and s ~= "" and s ~= ngx.null
end

local function isEmpty(s)
    return s == nil or s == "" or s == ngx.null
end

local function toboolean(s)
    if isNotEmpty(s) then
        if s == "true" then
            return true
        else
            return false
        end
    else
        return false
    end
end

local function split(s, separator, isRegex)
    local isPlainText = not isRegex

    local index = 1
    local array = {}

    local firstIndex, lastIndex = s:find(separator, index, isPlainText)
    while firstIndex do
        if firstIndex ~= 1 then
            array[#array + 1] = s:sub(index, firstIndex - 1)
        end
        index = lastIndex + 1
        firstIndex, lastIndex = s:find(separator, index, isPlainText)
    end

    if index <= #s then
        array[#array + 1] = s:sub(index, #s)
    end

    return array
end

local function urlencode(str)
    if str then
        str = string.gsub(str, "\n", "\r\n")
        str =
            string.gsub(
            str,
            "([^%w ])",
            function(c)
                return string.format("%%%02X", string.byte(c))
            end
        )
        str = string.gsub(str, " ", "+")
    end
    return str
end

local function urldecode(str)
    if str then
        str = string.gsub(str, "+", " ")
        str =
            string.gsub(
            str,
            "%%(%x%x)",
            function(hex)
                return string.char(tonumber(hex, 16))
            end
        )
    end
    return str
end

local function parseForm(form)
    if not form then
        return {}
    end

    local parameters = {}

    local listOfKeysAndValues = split(form, "&")
    for i = 1, #listOfKeysAndValues do
        local keyAndValue = split(listOfKeysAndValues[i], "=")
        local key, value = keyAndValue[1], keyAndValue[2]
        if parameters[key] then
            if type(parameters[key]) == "string" then
                parameters[key] = {parameters[key]} -- copy old value
            end
            parameters[key][#parameters[key] + 1] = value
        else
            parameters[key] = value
        end
    end

    return parameters
end

local function requireSecureToken()
    local https = ngx.var.https
    if https and https == "on" then
        return true
    else
        return false
    end
end

local function lengthOfObject(obj)
    local i = 0
    if obj then
        for k, v in pairs(obj) do
            i = i + 1
        end
    end
    return i
end

local function starts_with(str, start)
    return str:sub(1, #start) == start
end

local function ends_with(str, ending)
    return ending == "" or str:sub(-(#ending)) == ending
end

local function hash_to_array(hash)
    local json = require "cjson"
    local arr = {}
    local i = 0
    for k, v in pairs(hash) do
        arr[i + 1] = k
        local _v
        if (type(v) == "table") then
            _v = json.encode(v)
        else
            _v = v
        end
        arr[i + 2] = _v
        i = i + 2
    end
    return arr
end

local function shallowcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == "table" then
        copy = {}
        for orig_key, orig_value in pairs(orig) do
            copy[orig_key] = orig_value
        end
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end


return {
    unescape = unescape,
    isNotEmpty = isNotEmpty,
    isEmpty = isEmpty,
    toboolean = toboolean,
    split = split,
    urlencode = urlencode,
    urldecode = urldecode,
    parseForm = parseForm,
    requireSecureToken = requireSecureToken,
    lengthOfObject = lengthOfObject,
    randomString = randomString,
    table_merge = table_merge,
    starts_with = starts_with,
    ends_with = ends_with,
    hash_to_array = hash_to_array,
    shallowcopy = shallowcopy
}
