-- local cc = cc
-- local Cls = cc.class("Mbrutil")
local lfs = require("lfs")
local io_open = io.open
local json = require "cjson"
--cc.import("#json")
local Cls = {}
local mkdirp = require "mkdirp"
local inspect = require "inspect"
local CodeGen = require "CodeGen"
local uuid = require "jit-uuid"
local http
local function _print(msg, _format)
    local _msg
    if _format then
        _msg = inspect(msg)
    else
        _msg = msg
    end

    if ngx then
        ngx.log(ngx.ERR, _msg)
    elseif print then
        print(_msg)
    end
end

if ngx then
    http = require("resty.http")
    -- if ngx then
    Cls.get_geo = function(ip, config)
        local httpc = http.new()
        -- _print("get_geo:" .. ip .. "," .. inspect(config))
        local _appconf = config.app
        local _ip_api_token = _appconf.ipapi_token
        local _api_url = "http://api.ipapi.com/api/" .. ip .. "?access_key=" .. _ip_api_token
        -- ngx.log(ngx.ERR, inspect(_api_url))
        local _res, _err = httpc:request_uri(_api_url, {method = "GET"})
        local _resb = _res.body
        -- _print("status:" .. inspect(_res.status))
        -- _print("body:" .. inspect(_resb))
        if _res.status == 200 and _resb and type(_resb) == "string" then
            _resb = json.decode(_resb)
        end
        return _resb, _err
    end
end

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

local function _get_uuid(_now)
    if not _now then
        _now = ngx and ngx.time() or os.time()
    end

    uuid.seed(_now)
    return uuid()
end

local function _random_string(length)
    if not length or length <= 0 then
        return ""
    end
    math.randomseed(os.clock() ^ 5)
    return _random_string(length - 1) .. charset[math.random(1, #charset)]
end

local function _dirname(str)
    if str:match(".-/.-") then
        local name = string.gsub(str, "(.*/)(.*)", "%1")
        return name
    else
        return ""
    end
end

local function _write_file(_filepath, content)
    _print("write_file:" .. _filepath)
    -- _print(inspect(content))
    if _filepath and content then
        mkdirp(_dirname(_filepath))
        -- print(_filepath)
        -- print(content)
        local _file, _ = io_open(_filepath, "w+")
        if _file ~= nil then
            _file:write(content)
            _file:close()
        end
    end
end

local function _read_file(path)
    local file = io_open(path, "rb") -- r read mode and b binary mode
    if not file then
        return nil
    end
    local content = file:read "*a" -- *a or *all reads the whole file
    file:close()
    return content
end

local function _show_folder(folder)
    local _files = {}
    setmetatable(_files, json.array_mt)
    mkdirp(folder)
    for _file in lfs.dir(folder) do
        if _file ~= "." and _file ~= ".." then
            _files[#_files + 1] = _file
        end
    end
    return _files
end

local function _read_dir(folder)
    _print("read_dir:" .. folder)
    local _files = _show_folder(folder)
    -- print(inspect(_files))
    local _content = {}
    for _, _file in ipairs(_files) do
        _print("file:" .. _file)
        local _cont = _read_file(folder .. "/" .. _file)
        -- print(_cont)
        table.insert(_content, _cont)
    end
    return table.concat(_content, "\n")
end

local function _get_template(_rules, _data)
    -- _print("get_template:" .. inspect(_data))
    local _rules1 = table.copy(_rules)
    table.merge(_rules1, _data)
    return CodeGen(_rules1)
end

local function _git_push(_dir, _files, _rfiles)
    local _git = "git -C " .. _dir .. " "
    local _cmd =
        "export HOME=/tmp && " ..
        _git ..
            " pull origin master ;" ..
                _git ..
                    "config --global user.email baysao@gmail.com" ..
                        "&&" .. _git .. "config --global user.name baysao && " .. _git .. "remote -v"
    if _files and #_files > 0 then
        for _, _file in ipairs(_files) do
            mkdirp(_dirname(_file))
            _cmd = _cmd .. ";" .. _git .. "add -f " .. _file
        end
    end
    if _rfiles and #_rfiles > 0 then
        for _, _file in ipairs(_rfiles) do
            -- mkdirp(dirname(_file))
            _cmd = _cmd .. ";" .. _git .. "rm -f " .. _file
        end
    end
    -- _cmd = _cmd .. " ; " .. _git .. "commit -m update && " .. _git .. "push origin master"
    _cmd = _cmd .. " ; " .. _git .. "commit -m update"
    -- print(_cmd)
    -- local retcode, output =
    os.capture(_cmd)
    -- print(retcode)
    -- print(output)
end

local function _authorize_whitelist(_config, args)
    local _appconf = _config.app
    local whitelist_sid = _appconf.whitelist_sid
    local sid = ngx.var.cookie__slc_web_sid or args.sid
    local _info = whitelist_sid and whitelist_sid[sid]
    if sid and _info then
        local _partner_id = args.partner_id
        local _user_id = args.user_id

        local _info_partner_id = _info.partner_id
        if not _user_id or not _partner_id or not _info_partner_id or _partner_id ~= _info_partner_id then
            return false, "Arguments not valid"
        end
        args.partner_id = nil
        return true
    end
    return false
end

Cls.authorize_whitelist = _authorize_whitelist
Cls.read_dir = _read_dir
Cls.read_file = _read_file
Cls.write_file = _write_file
Cls.dirname = _dirname
Cls.mkdirp = mkdirp
Cls.inspect = inspect
Cls.codegen = CodeGen
Cls.get_template = _get_template
Cls.git_push = _git_push
Cls.show_folder = _show_folder
Cls.random_string = _random_string
Cls.get_uuid = _get_uuid
Cls.print = _print

return Cls
