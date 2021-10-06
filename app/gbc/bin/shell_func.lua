--[[

Copyright (c) 2015 gameboxcloud.com

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

]]
if not ROOT_DIR then
    print("Not set ROOT_DIR for Lua, exit.")
    os.exit(1)
end

-- globals

LUA_BIN = ROOT_DIR .. "/bin/openresty/luajit/bin/luajit"
NGINX_DIR = ROOT_DIR .. "/bin/openresty/nginx"
REDIS_DIR = ROOT_DIR .. "/bin/redis"
TMP_DIR = ROOT_DIR .. "/tmp"
CONF_DIR = ROOT_DIR .. "/gbc/conf"
DB_DIR = ROOT_DIR .. "/db"

CONF_PATH = CONF_DIR .. "/config.lua"
NGINX_CONF_PATH = CONF_DIR .. "/nginx.conf"
NGINX_SERVER_CONF_PATH = CONF_DIR .. "/server.conf"
REDIS_CONF_PATH = CONF_DIR .. "/redis.conf"
SUPERVISORD_CONF_PATH = CONF_DIR .. "/supervisord.conf"

VAR_CONF_PATH = TMP_DIR .. "/config.lua"
VAR_APP_KEYS_PATH = TMP_DIR .. "/app_keys.lua"
VAR_NGINX_CONF_PATH = TMP_DIR .. "/nginx.conf"
VAR_REDIS_CONF_PATH = TMP_DIR .. "/redis.conf"
VAR_BEANS_LOG_PATH = TMP_DIR .. "/beanstalkd.log"
VAR_SUPERVISORD_CONF_PATH = TMP_DIR .. "/supervisord.conf"

local _getValue, _checkVarConfig, _checkAppKeys
local _updateCoreConfig, _updateNginxConfig
local _updateRedisConfig, _updateSupervisordConfig

local _SUPERVISOR_WORKER_PROG_TMPL =
    [[
[program:worker-_APP_NAME_]
command=_GBC_CORE_ROOT_/bin/openresty/luajit/bin/lua _GBC_CORE_ROOT_/gbc/bin/start_worker.lua _GBC_CORE_ROOT_ _APP_ROOT_ '_LUA_PATH_' '_LUA_CPATH_'
process_name=%%(process_num)02d
numprocs=_NUM_PROCESS_
redirect_stderr=true
stdout_logfile=_GBC_CORE_ROOT_/logs/worker-_APP_NAME_.log
;;_CUSTOM_SERVICE_
]]

function updateConfigs()
    _updateCoreConfig()

    local includes_path, includes_cpath = _updateNginxConfig()
    _updateRedisConfig()
    _updateSupervisordConfig(includes_path, includes_cpath)
end

-- init

package.path = ROOT_DIR .. "/gbc/src/?.lua;" .. ROOT_DIR .. "/gbc/lib/?.lua;" .. package.path
package.cpath = ROOT_DIR .. "/bin/openresty/lualib/?.so;" .. package.cpath

require("framework.init")

if tostring(DEBUG) ~= "0" then
    cc.DEBUG = cc.DEBUG_VERBOSE
    DEBUG = true
else
    cc.DEBUG = cc.DEBUG_WARN
    DEBUG = false
end

-- private
local json = cc.import("#json")
local luamd5 = cc.import("#luamd5")
local Factory = cc.import("#gbc").Factory

_getValue = function(t, key, def)
    local keys = string.split(key, ".")
    for _, key in ipairs(keys) do
        if t[key] then
            t = t[key]
        else
            if type(def) ~= "nil" then
                return def
            end
            return nil
        end
    end
    return t
end

local _checkConfig = function(cfg)
    if not io.exists(cfg) then
        print(string.format("[ERR] Not found file: %s", cfg))
        os.exit(1)
    end

    local config = dofile(cfg)
    if type(config) ~= "table" then
        print(string.format("[ERR] Invalid config file: %s", cfg))
        os.exit(1)
    end

    return config
end

_checkVarConfig = function()
    if not io.exists(VAR_CONF_PATH) then
        print(string.format("[ERR] Not found file: %s", VAR_CONF_PATH))
        os.exit(1)
    end

    local config = dofile(VAR_CONF_PATH)
    if type(config) ~= "table" then
        print(string.format("[ERR] Invalid config file: %s", VAR_CONF_PATH))
        os.exit(1)
    end

    return config
end

_checkAppKeys = function()
    if not io.exists(VAR_APP_KEYS_PATH) then
        print(string.format("[ERR] Not found file: %s", VAR_APP_KEYS_PATH))
        os.exit(1)
    end

    local appkeys = dofile(VAR_APP_KEYS_PATH)
    if type(appkeys) ~= "table" then
        print(string.format("[ERR] Invalid app keys file: %s", VAR_APP_KEYS_PATH))
        os.exit(1)
    end

    return appkeys
end

_updateCoreConfig = function()
    --print(CONF_PATH)
    local contents = io.readfile(CONF_PATH)
    --print(contents)
    contents = string.gsub(contents, "_GBC_CORE_ROOT_", ROOT_DIR)
    io.writefile(VAR_CONF_PATH, contents)

    -- update all apps key and index
    -- local config = _checkVarConfig()
    -- local sites = _getValue(config, "sites")
    -- local contents = {"", "local keys = {}"}
    -- for site_name, opt in pairs(sites) do
    --    local apps = _getValue(opt, "apps")
    --    local names = {}
    --    for name, _ in pairs(apps) do
    --       names[#names + 1] = name
    --    end
    --    table.sort(names)
    --    for index, name in ipairs(names) do
    --       local path = apps[name]
    --       contents[#contents + 1] = string.format('keys["%s"] = {name = "%s", index = %d, key = "%s"}', path, site_name .. "_" .. name, index, luamd5.sumhexa(path))
    --    end
    -- end

    -- contents[#contents + 1] = "return keys"
    -- contents[#contents + 1] = ""

    -- io.writefile(VAR_APP_KEYS_PATH, table.concat(contents, "\n"))
end

-- function dirLookup(dir)
--     local p = io.popen('find "' .. dir .. '" -type f') --Open directory look for files, save data in p. By giving '-type f' as parameter, it returns all files.
--     for file in p:lines() do --Loop through all files
--         print(file)
--     end
-- end

local _updateAppConfig = function(site_name, site_path, idx)
    print(site_name)
    print(site_path)
    local site_opt = _checkConfig(site_path .. "/config.lua")
    local site_conf = site_path .. "/http.conf"
    local site_rtmp_conf = site_path .. "/rtmp.conf"
    local site_stream_conf = site_path .. "/stream.conf"
    print("stream_conf:" .. site_stream_conf)
    local has_http = true
    local has_rtmp = true
    local has_stream = true
    if not io.exists(site_conf) then
        has_http = false
    end
    if not io.exists(site_rtmp_conf) then
        has_rtmp = false
    end
    if not io.exists(site_stream_conf) then
        has_stream = false
    end

    local contents_sup
    -- if idx == 0 then
    --     contents_sup = io.readfile(SUPERVISORD_CONF_PATH)
    -- else
    contents_sup = io.readfile(VAR_SUPERVISORD_CONF_PATH)
    --end
    if site_opt.supervisor ~= nil then
        --print(site_opt.supervisor)
        contents_sup = string.gsub(contents_sup, ";_WORKERS_", site_opt.supervisor .. "\n;_WORKERS_")
        contents_sup = string.gsub(contents_sup, "_GBC_CORE_ROOT_", ROOT_DIR)
        contents_sup = string.gsub(contents_sup, "_SITE_ROOT_", site_path)
        print("site_path:" .. site_path)
        print(contents_sup)
    end

    if has_stream then
        local contents_app = io.readfile(site_stream_conf)
        contents_app = string.gsub(contents_app, "_STREAM_PORT_", _getValue(site_opt, "server.nginx.stream_port", 1935))
        contents_app =
            string.gsub(
            contents_app,
            "_STREAM_SERVER_NAME_",
            _getValue(site_opt, "server.nginx.stream_server_name", "localhost")
        )
        contents_app = string.gsub(contents_app, "_GBC_CORE_ROOT_", ROOT_DIR)
        contents_app = string.gsub(contents_app, "_SITE_ROOT_", site_path)
        io.writefile(TMP_DIR .. "/site_stream_" .. site_name .. ".conf", contents_app)
    else
        io.writefile(TMP_DIR .. "/site_stream_" .. site_name .. ".conf", "")
    end

    if has_rtmp then
        local contents_app = io.readfile(site_rtmp_conf)
        contents_app = string.gsub(contents_app, "_RTMP_PORT_", _getValue(site_opt, "server.nginx.rtmp_port", 1935))
        contents_app =
            string.gsub(
            contents_app,
            "_RTMP_SERVER_NAME_",
            _getValue(site_opt, "server.nginx.rtmp_server_name", "localhost")
        )
        contents_app = string.gsub(contents_app, "_GBC_CORE_ROOT_", ROOT_DIR)
        contents_app = string.gsub(contents_app, "_SITE_ROOT_", site_path)
        io.writefile(TMP_DIR .. "/site_rtmp_" .. site_name .. ".conf", contents_app)
    else
        io.writefile(TMP_DIR .. "/site_rtmp_" .. site_name .. ".conf", "")
    end
    if has_http then
        local contents_app = io.readfile(site_conf)

        --contents_app = string.gsub(contents_app, "listen[ \t]+[0-9]+", string.format("listen %d", _getValue(site_opt, "server.nginx.port", 80)))
        --contents_app = string.gsub(contents_app, "listen[ \t]+[0-9]+[ \t]+ssl", string.format("listen %d ssl", _getValue(site_opt, "server.nginx.port_ssl", 443)))
        --contents_app = string.gsub(contents_app, "server_name[ \t]+localhost;", string.format("server_name %s;", _getValue(site_opt, "server.nginx.server_name", "localhost")))
        local _port = _getValue(site_opt, "server.nginx.port", 80)
        local _port_ssl = _getValue(site_opt, "server.nginx.port_ssl", 443)
        -- local cmd = ROOT_DIR .. "/cmd1.sh  _conf_replace " .. site_path .. " " .. _port .. " " .. _port_ssl
        -- print("cmd:" .. cmd)
        -- os.execute(cmd)
        if string.sub(_port, 1, 5) == "unix:" then
            contents_app = string.gsub(contents_app, "_HTTP_PORT_", _port)
        else
            contents_app = string.gsub(contents_app, "_HTTP_PORT_", BIND_ADDRESS .. ":" .. _port)
        end
        contents_app = string.gsub(contents_app, "_HTTP_PORTSSL_", BIND_ADDRESS .. ":" .. _port_ssl .. " ssl")

        contents_app =
            string.gsub(contents_app, "_SERVER_NAME_", _getValue(site_opt, "server.nginx.server_name", "localhost"))
        contents_app = string.gsub(contents_app, "_GBC_CORE_ROOT_", ROOT_DIR)
        contents_app = string.gsub(contents_app, "_SITE_ROOT_", site_path)

        local templates = _getValue(site_opt, "templates")

        if templates ~= nil then
            print("templates:" .. json.encode(templates))
            if templates ~= nil then
                for templ_name, templ_path in pairs(templates) do
                    templ_name = string.gsub(templ_name, "_SITE_ROOT_", site_path)
                    templ_name = string.gsub(templ_name, "_GBC_CORE_ROOT_", ROOT_DIR)

                    templ_path = string.gsub(templ_path, "_SITE_ROOT_", site_path)
                    templ_path = string.gsub(templ_path, "_GBC_CORE_ROOT_", ROOT_DIR)
                    print(templ_name)
                    print(templ_path)
                    if io.exists(templ_path) then
                        local cmd =
                            ROOT_DIR ..
                            "/bin/bin/lemplate --compile " .. templ_path .. "/*.tt2 >" .. templ_name .. ".lua"
                        print("cmd:" .. cmd)
                        os.execute(cmd)
                    end
                end
            end
        end

        local apps = _getValue(site_opt, "apps")
        local includes = {}

        local names = {}

        local contents_keys = {"local keys = {}", "\n"}
        local contents_keys_old = ""
        if io.exists(VAR_APP_KEYS_PATH) then
            contents_keys_old = io.readfile(VAR_APP_KEYS_PATH)
            if string.find(contents_keys_old, "local keys") == nil then
                contents_keys = {"local keys = {}", "\n"}
            else
                contents_keys_old = string.gsub(contents_keys_old, "%s+return keys%s+", "")
                contents_keys = {contents_keys_old}
            end
        end
        local index = 1

        for name, _path in pairs(apps) do
            local path = site_path .. "/" .. _path
            local entryPath = string.format("%s/conf/app_entry.conf", path)
            local varEntryPath = string.format("%s/app_%s_entry.conf", TMP_DIR, site_name .. "_" .. name)
            print("entryPath:" .. entryPath)
            if io.exists(entryPath) then
                names[#names + 1] = name
                local entry = io.readfile(entryPath)
                entry = string.gsub(entry, "_GBC_CORE_ROOT_", ROOT_DIR)
                entry = string.gsub(entry, "_SITE_ROOT_", site_path)
                entry = string.gsub(entry, "_APP_ROOT_", path)
                io.writefile(varEntryPath, entry)
                includes[#includes + 1] = string.format("        include %s;", varEntryPath)

                local hexpath = luamd5.sumhexa(path)
                if string.find(contents_keys_old, hexpath) == nil then
                    contents_keys[#contents_keys + 1] =
                        string.format(
                        'keys["%s"] = {name = "%s", index = %d, key = "%s"}',
                        path,
                        site_name .. "_" .. name,
                        index,
                        hexpath
                    )
                end
                index = index + 1
            end
        end
        includes = "\n" .. table.concat(includes, "\n")
        contents_app = string.gsub(contents_app, "\n[ \t]*#[ \t]*_INCLUDE_APPS_ENTRY_", includes)

        contents_keys[#contents_keys + 1] = "return keys"
        contents_keys[#contents_keys + 1] = ""

        io.writefile(VAR_APP_KEYS_PATH, table.concat(contents_keys, "\n"))
        io.writefile(TMP_DIR .. "/site_http_" .. site_name .. ".conf", contents_app)
        local config = _checkVarConfig()
        local appkeys = _checkAppKeys()
        local appConfigs = Factory.makeAppConfigs(appkeys, config, package.path)
        --local contents_sup = io.readfile(SUPERVISORD_CONF_PATH)
        local workers = {}
        for name, _path in pairs(apps) do
            local path = site_path .. "/" .. _path
            local prog = string.gsub(_SUPERVISOR_WORKER_PROG_TMPL, "_GBC_CORE_ROOT_", ROOT_DIR)
            print("path:" .. path)
            -- get numOfJobWorkers
            local appConfig = appConfigs[path]
            --print(appConfig.app.supervisor)
            prog = string.gsub(prog, "_NUM_PROCESS_", appConfig.app.numOfJobWorkers)
            if appConfig.app.supervisor then
                prog = string.gsub(prog, ";;_CUSTOM_SERVICE_", appConfig.app.supervisor)
            end

            --print(appConfig.app.templates)
            local templates = appConfig.app.templates

            if templates ~= nil then
                for templ_name, templ_path in pairs(templates) do
                    templ_name = string.gsub(templ_name, "_APP_ROOT_", path)
                    templ_name = string.gsub(templ_name, "_SITE_ROOT_", site_path)
                    templ_name = string.gsub(templ_name, "_APP_NAME_", site_name .. "-" .. name)
                    templ_name = string.gsub(templ_name, "_GBC_CORE_ROOT_", ROOT_DIR)

                    templ_path = string.gsub(templ_path, "_APP_ROOT_", path)
                    templ_path = string.gsub(templ_path, "_SITE_ROOT_", site_path)
                    templ_path = string.gsub(templ_path, "_APP_NAME_", site_name .. "-" .. name)
                    templ_path = string.gsub(templ_path, "_GBC_CORE_ROOT_", ROOT_DIR)
                    print(templ_name)
                    print(templ_path)
                    if io.exists(templ_path) then
                        local cmd =
                            ROOT_DIR ..
                            "/bin/bin/lemplate --compile " .. templ_path .. "/*.tt2 >" .. templ_name .. ".lua"
                        print(cmd)
                        os.execute(cmd)
                    --                        cmd = ROOT_DIR .. "/bin/openresty/bin/jemplate --compile " .. templ_path .. "/*.html >" .. templ_path .. "/" .. templ_name .. ".js"
                    --                        print(cmd)
                    --                        os.execute(cmd)
                    end
                end
            end

            prog = string.gsub(prog, "_SITE_ROOT_", site_path)
            prog = string.gsub(prog, "_APP_ROOT_", path)
            prog = string.gsub(prog, "_APP_NAME_", site_name .. "-" .. name)
            prog = string.gsub(prog, "_GBC_CORE_ROOT_", ROOT_DIR)
            workers[#workers + 1] = prog
        end

        workers[#workers + 1] = ";_WORKERS_"
        --print(contents_sup)
        --print(table.concat(workers, "\n"))
        contents_sup = string.gsub(contents_sup, ";_WORKERS_", table.concat(workers, "\n"))
    else
        io.writefile(TMP_DIR .. "/site_http_" .. site_name .. ".conf", "")
    end
    io.writefile(VAR_SUPERVISORD_CONF_PATH, contents_sup)
    --end
end
_updateNginxConfig = function()
    local config = _checkVarConfig()

    local contents = io.readfile(NGINX_CONF_PATH)
    contents = string.gsub(contents, "_GBC_CORE_ROOT_", ROOT_DIR)
    --contents = string.gsub(contents, "listen[ \t]+[0-9]+", string.format("listen %d", _getValue(config, "server.nginx.port", 8088)))
    local _numOfWorker = _getValue(config, "server.nginx.numOfWorkers")
    if not _numOfWorker then
        _numOfWorker = "auto"
    end
    contents = string.gsub(contents, "worker_processes[ \t]+%a+", string.format("worker_processes %s", _numOfWorker))

    if DEBUG then
        contents = string.gsub(contents, "cc.DEBUG = [%a_%.]+", "cc.DEBUG = cc.DEBUG_VERBOSE")
        contents = string.gsub(contents, "error_log (.+%-error%.log)[ \t%a]*;", "error_log %1 debug;")
        contents = string.gsub(contents, "lua_code_cache[ \t]+%a+;", "lua_code_cache off;")
    else
        contents = string.gsub(contents, "cc.DEBUG = [%a_%.]+", "cc.DEBUG = cc.DEBUG_ERROR")
        contents = string.gsub(contents, "error_log (.+%-error%.log)[ \t%a]*;", "error_log %1;")
        contents = string.gsub(contents, "lua_code_cache[ \t]+%a+;", "lua_code_cache on;")
    end

    -- copy app_entry.conf to tmp/
    local SITES_DIR = _getValue(config, "SITES_DIR")
    print(SITES_DIR)
    local _sites_config = _checkConfig(SITES_DIR .. "/config.lua")
    local _modules = _getValue(_sites_config, "modules")
    if _modules == nil then
        _modules = ""
    end
    print(_modules)
    local contents_sup = io.readfile(SUPERVISORD_CONF_PATH)

    local _supervisor = _getValue(_sites_config, "supervisor")

    contents_sup = string.gsub(contents_sup, ";_WORKERS_", _supervisor .. "\n;_WORKERS_")
    contents_sup = string.gsub(contents_sup, "_GBC_CORE_ROOT_", ROOT_DIR)
    io.writefile(VAR_SUPERVISORD_CONF_PATH, contents_sup)

    local _pkg_path = _getValue(_sites_config, "lua_package_path")
    if not _pkg_path then
        _pkg_path = ""
    end
    local _pkg_cpath = _getValue(_sites_config, "lua_package_cpath")
    if not _pkg_cpath then
        _pkg_cpath = ""
    end
    local _sites = _getValue(_sites_config, "sites")
    local includes_path = {_pkg_path}
    local includes_cpath = {_pkg_cpath}
    local includes_site = {}
    local includes_rtmp = {}

    local includes_modules = {}
    local includes_stream = {}
    local includes_luainit = {}
    local includes_luawinit = {}
    local includes_maininit = {}
    local includes_httpinit = {}
    local idx = 0
    for _site_name, __site_path in pairs(_sites) do
        local _site_path
        local _continue = false
        if type(__site_path) == "table" and not __site_path.disabled then
            _continue = true
            if __site_path.modules then
                includes_modules[#includes_modules + 1] = __site_path.modules
            end

            if __site_path.path then
                _site_path = SITES_DIR .. "/" .. __site_path.path
            end
            if __site_path.luainit then
                includes_luainit[#includes_luainit + 1] = __site_path.luainit
            end
            if __site_path.luawinit then
                includes_luawinit[#includes_luawinit + 1] = __site_path.luawinit
            end
            if __site_path.maininit then
                includes_maininit[#includes_maininit + 1] = __site_path.maininit
            end
	      if __site_path.httpinit then
                includes_httpinit[#includes_httpinit + 1] = __site_path.httpinit
            end
        elseif type(__site_path) == "string" then
            _continue = true
            _site_path = SITES_DIR .. "/" .. __site_path
        end
        if _continue then
            print(_site_name)
            print(_site_path)

            local varSitePath = string.format("%s/site_http_%s.conf", TMP_DIR, _site_name)
            local varSiteRtmpPath = string.format("%s/site_rtmp_%s.conf", TMP_DIR, _site_name)
            local varSiteStreamPath = string.format("%s/site_stream_%s.conf", TMP_DIR, _site_name)
            includes_path[#includes_path + 1] =
                string.format("%s/?.lua;%s/lib/?.lua;%s/src/?.lua", _site_path, _site_path, _site_path)
            includes_cpath[#includes_cpath + 1] =
                string.format("%s/?.so;%s/lib/?.so;%s/src/?.so", _site_path, _site_path, _site_path)
            includes_site[#includes_site + 1] = string.format("        include %s;", varSitePath)
            includes_rtmp[#includes_rtmp + 1] = string.format("        include %s;", varSiteRtmpPath)
            includes_stream[#includes_stream + 1] = string.format("        include %s;", varSiteStreamPath)

            --local site_opt = _checkConfig(_site_path .. "/config.lua")
            _updateAppConfig(_site_name, _site_path, idx)
            idx = idx + 1
            local site_opt = _checkConfig(_site_path .. "/config.lua")

            -- if io.exists(_site_path .. "/apps/config.ld") then
            --     print("/app/bin/openresty/luajit/bin/ldoc " .. _site_path .. "/apps")
            --     os.execute("/app/bin/openresty/luajit/bin/ldoc " .. _site_path .. "/apps")
            -- end

            local apps = _getValue(site_opt, "apps")
        -- for _app_name, _app_path in pairs(apps) do
        --     local _app_full_path = _site_path .. "/" .. _app_path
        --     print(_app_full_path)

        --     includes_path[#includes_path + 1] =
        --         string.format("%s/?.lua;%s/lib/?.lua;%s/src/?.lua", _app_full_path, _app_full_path, _app_full_path)
        --     includes_cpath[#includes_cpath + 1] =
        --         string.format("%s/?.so;%s/lib/?.so;%s/src/?.so", _app_full_path, _app_full_path, _app_full_path)
        -- end
        end
    end

    includes_path = table.concat(includes_path, ";")
    includes_cpath = table.concat(includes_cpath, ";")
    includes_site = "\n" .. table.concat(includes_site, "\n")
    includes_rtmp = "\n" .. table.concat(includes_rtmp, "\n")
    includes_stream = "\n" .. table.concat(includes_stream, "\n")
    contents = string.gsub(contents, "lua_package_path '", "lua_package_path '" .. includes_path)
    contents = string.gsub(contents, "lua_package_cpath '", "lua_package_cpath '" .. includes_cpath)
    contents = string.gsub(contents, "\n[ \t]*#[ \t]*_INCLUDE_SITES_ENTRY_", includes_site)
    contents = string.gsub(contents, "\n[ \t]*#[ \t]*_INCLUDE_RTMPS_ENTRY_", includes_rtmp)
    contents = string.gsub(contents, "\n[ \t]*#[ \t]*_INCLUDE_STREAMS_ENTRY_", includes_stream)
    if #includes_modules > 0 then
        _modules = _modules .. "\n" .. table.concat(includes_modules, "\n")
    end

    _modules = string.gsub(_modules, "_GBC_CORE_ROOT_", ROOT_DIR)
    print(_modules)
    contents = string.gsub(contents, "[ \t]*#[ \t]*_MODULES_", _modules)

    includes_luainit[#includes_luainit + 1] = "\n--_INCLUDE_SITES_LUAINIT_"
    contents =
        string.gsub(contents, "\n[ \t]*--[ \t]*--_INCLUDE_SITES_LUAINIT_", "\n" .. table.concat(includes_luainit, "\n"))

    includes_luawinit[#includes_luawinit + 1] = "\n--_INCLUDE_SITES_LUAWINIT_"
    contents =
        string.gsub(
        contents,
        "\n[ \t]*--[ \t]*--_INCLUDE_SITES_LUAWINIT_",
        "\n" .. table.concat(includes_luawinit, "\n")
    )

      includes_httpinit[#includes_httpinit + 1] = "\n#_INCLUDE_SITES_HTTPINIT_"
    contents =
        string.gsub(
        contents,
        "\n[ \t]*--[ \t]*#_INCLUDE_SITES_HTTPINIT_",
        "\n" .. table.concat(includes_httpinit, "\n")
    )
    includes_maininit[#includes_maininit + 1] = "\n#_INCLUDE_SITES_MAININIT_"
    contents =
        string.gsub(
        contents,
        "\n[ \t]*--[ \t]*#_INCLUDE_SITES_MAININIT_",
        "\n" .. table.concat(includes_maininit, "\n")
    )

    contents = string.gsub(contents, "_GBC_CORE_ROOT_", ROOT_DIR)
    io.writefile(VAR_NGINX_CONF_PATH, contents)
    return includes_path, includes_cpath
end

_updateRedisConfig = function()
    local config = _checkVarConfig()

    local contents = io.readfile(REDIS_CONF_PATH)
    contents = string.gsub(contents, "_GBC_CORE_ROOT_", ROOT_DIR)

    local socket = _getValue(config, "server.redis.socket")
    if socket then
        if string.sub(socket, 1, 5) == "unix:" then
            socket = string.sub(socket, 6)
        end
        contents = string.gsub(contents, "[# \t]*unixsocket[ \t]+[^\n]+", string.format("unixsocket %s", socket))
        contents = string.gsub(contents, "[# \t]*bind[ \t]+[%d\\.]+", "# bind 127.0.0.1")
        contents = string.gsub(contents, "[# \t]*port[ \t]+%d+", "port 0")
    else
        contents = string.gsub(contents, "[# \t]*unixsocket[ \t]+", "# unixsocket")
    end

    local host = _getValue(config, "server.redis.host", "127.0.0.1")
    local port = _getValue(config, "server.redis.port", 6379)
    contents = string.gsub(contents, "[# \t]*bind[ \t]+[%d\\.]+", "bind " .. host)
    contents = string.gsub(contents, "[# \t]*port[ \t]+%d+", "port " .. port)

    io.writefile(VAR_REDIS_CONF_PATH, contents)
end

_updateSupervisordConfig = function(includes_path, includes_cpath)
    local config = _checkVarConfig()
    local appkeys = _checkAppKeys()
    local appConfigs = Factory.makeAppConfigs(appkeys, config, package.path)
    local beanport = _getValue(config, "server.beanstalkd.port")
    local beanhost = _getValue(config, "server.beanstalkd.host")
    --    local enabled_mongodb = _getValue(config, "server.mongodb.enabled")

    --local contents = io.readfile(SUPERVISORD_CONF_PATH)
    local contents = io.readfile(VAR_SUPERVISORD_CONF_PATH)
    contents = string.gsub(contents, "_GBC_CORE_ROOT_", ROOT_DIR)
    contents = string.gsub(contents, "_LUA_PATH_", includes_path)
    contents = string.gsub(contents, "_LUA_CPATH_", includes_cpath)
    contents = string.gsub(contents, "_BEANSTALKD_PORT_", beanport)
    contents = string.gsub(contents, "_BEANSTALKD_HOST_", beanhost)

    -- local workers = {}
    -- local sites = _getValue(config, "sites")
    -- for site_name, opt in pairs(sites) do
    --    local apps = _getValue(opt, "apps")
    --    for name, path in pairs(apps) do
    --       local prog = string.gsub(_SUPERVISOR_WORKER_PROG_TMPL, "_GBC_CORE_ROOT_", ROOT_DIR)
    --       prog = string.gsub(prog, "_APP_ROOT_PATH_", path)
    --       prog = string.gsub(prog, "_APP_NAME_", site_name .. "-" .. name)

    --       -- get numOfJobWorkers
    --       local appConfig = appConfigs[path]
    --       prog = string.gsub(prog, "_NUM_PROCESS_", appConfig.app.numOfJobWorkers)

    --       workers[#workers + 1] = prog
    --    end
    -- end

    --contents = string.gsub(contents, ";_WORKERS_", table.concat(workers, "\n"))

    io.writefile(VAR_SUPERVISORD_CONF_PATH, contents)
end
local function no_usetmp()
    if enabled_mongodb == 1 then
        require "socket"

        local mongodb_port = 27016
        local _sock
        repeat
            _sock = true
            mongodb_port = mongodb_port + 1
            local sock = socket.tcp()
            _sock = sock:connect("127.0.0.1", mongodb_port)
            sock:close()
        until (not _sock)
        print(mongodb_port)
        contents = string.gsub(contents, "_MONGODB_PORT_", mongodb_port)
    end

    local es_http_port = 9201
    local es_trans_port = 9301

    local _sock
    repeat
        _sock = true
        es_http_port = es_http_port + 1
        print(es_http_port)
        local sock = socket.tcp()
        _sock = sock:connect("127.0.0.1", es_http_port)
        sock:close()
    until (not _sock)
    print(es_http_port)

    contents = string.gsub(contents, "_ES_HTTP_PORT_", es_http_port)

    local _sock
    repeat
        _sock = true
        es_trans_port = es_trans_port + 1
        print(es_trans_port)
        local sock = socket.tcp()
        _sock = sock:connect("127.0.0.1", es_trans_port)
        sock:close()
    until (not _sock)
    print(es_trans_port)

    contents = string.gsub(contents, "_ES_TRANS_PORT_", es_trans_port)

    io.writefile(VAR_SUPERVISORD_CONF_PATH, contents)
end
