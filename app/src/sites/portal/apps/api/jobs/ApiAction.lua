local cc = cc
local gbc = cc.import("#gbc")
local json = cc.import("#json")
local cjson = require("cjson")
local lfs = require("lfs")
local io_open = io.open
local mytype = "api"
local JobsAction = cc.class(mytype .. "JobsAction", gbc.ActionBase)
local mkdirp = require "mkdirp"
local inspect = require "inspect"

JobsAction.ACCEPTED_REQUEST_TYPE = "worker"

local Model = cc.import("#" .. mytype)

local CodeGen = require "CodeGen"

local _deploy_dir = "/massbit/massbitroute/app/src/sites/portal/public/deploy/dapi"

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
    setmetatable(_files, cjson.array_mt)
    mkdirp(folder)
    for _file in lfs.dir(folder) do
        if _file ~= "." and _file ~= ".." then
            _files[#_files + 1] = _file
        end
    end
    return _files
end

local function _read_dir(folder)
    print("read_dir")
    local _files = _show_folder(folder)
    -- print(inspect(_files))
    local _content = {}
    for _, _file in ipairs(_files) do
        print(folder .. "/" .. _file)
        local _cont = _read_file(folder .. "/" .. _file)
        -- print(_cont)
        table.insert(_content, _cont)
    end
    return table.concat(_content, "\n")
end

-- local CodeGen = require "CodeGen"

-- local gwman_dir = "/massbit/massbitroute/app/src/sites/services/gwman"
-- local stat_dir = "/massbit/massbitroute/app/src/sites/services/stat"

local PROVIDERS = {
    MASSBIT = 0,
    CUSTOM = 1,
    GETBLOCK = 2,
    QUICKNODE = 3,
    INFURA = 4
}

local rules = {
    _upstream = [[server unix:/tmp/${server_name}.sock;]],
    _upstreams = [[
upstream upstream_${api_key} {
    ${entrypoints/_upstream()}
    keepalive 32;
}
]],
    _api_method = [[
        set $api_method '';
        access_by_lua_file /massbit/massbitroute/app/src/sites/services/gateway/src/jsonrpc-access.lua;
        vhost_traffic_status_filter_by_set_key $api_method ${server_name}::api_method;
]],
    _allow_methods1 = [[set $jsonrpc_whitelist '${security.allow_methods}';]],
    _limit_rate_per_sec2 = [[limit_req zone=${api_key};]],
    _limit_rate_per_sec1 = [[limit_req_zone $binary_remote_addr zone=${api_key}:10m rate=${security.limit_rate_per_sec}r/s;]],
    _server_main = [[
${security._is_limit_rate_per_sec?_limit_rate_per_sec1()}

server {
    listen 80;
    listen 443 ssl;
    ssl_certificate /etc/letsencrypt/live/${blockchain}-${network}.massbitroute.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/${blockchain}-${network}.massbitroute.com/privkey.pem;
    resolver 8.8.4.4 ipv6=off;
    client_body_buffer_size 512K;
    client_max_body_size 1G;
    server_name ${gateway_domain};
    access_log /massbit/massbitroute/app/src/sites/services/gateway/logs/nginx-${gateway_domain}-access.log main_json;
    error_log /massbit/massbitroute/app/src/sites/services/gateway/logs/nginx-${gateway_domain}-error.log debug;

    location /${api_key} {
        rewrite /(.*) / break;
        ${security._is_limit_rate_per_sec?_limit_rate_per_sec2()}
        ${_allow_methods1()}
        set $api_method '';
        access_by_lua_file /massbit/massbitroute/app/src/sites/services/gateway/src/filter-jsonrpc-access.lua;
        vhost_traffic_status_filter_by_set_key $api_method ${api_key}::api_method;


        proxy_cache_use_stale updating error timeout invalid_header http_500 http_502 http_503 http_504;
        proxy_next_upstream error timeout invalid_header http_500 http_502 http_503 http_504;
        proxy_connect_timeout 10s;
        proxy_cache_methods GET HEAD POST;
        proxy_cache_key $request_uri|$request_body;
        proxy_cache_min_uses 1;
        proxy_cache cache;
        proxy_cache_valid 200 3s;
        proxy_cache_background_update on;
        add_header X-Cached $upstream_cache_status;
        proxy_ssl_verify off;
        proxy_pass http://upstream_${api_key}/;

        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection $connection_upgrade;
#      proxy_set_header X-Real-IP $remote_addr;
#      proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
# proxy_set_header Host $http_host;
    }
}
]],
    _server_backend_INFURA = [[
server {
    listen unix:/tmp/${server_name}.sock;
    location / {
       ${_api_method()}
        proxy_redirect off;
        set_encode_base64 $digest :${infura_project_secret};
        proxy_set_header Authorization 'Basic $digest';
        proxy_ssl_verify off;
        proxy_ssl_server_name on;
        proxy_pass https://mainnet.infura.io/v3/${infura_project_id};
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection $connection_upgrade;
    }
}
]],
    _server_backend_QUICKNODE = [[
server {
    listen unix:/tmp/${server_name}.sock;
    location / {
       ${_api_method()}
        proxy_redirect off;
        proxy_ssl_server_name on;
        proxy_pass ${quicknode_api_uri};
        proxy_http_version 1.1;
        proxy_ssl_verify off;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection $connection_upgrade;
    }
}
]],
    _server_backend_CUSTOM = [[
server {
    listen unix:/tmp/${server_name}.sock;
    location / {
       ${_api_method()}
        proxy_redirect off;
        proxy_ssl_server_name on;
        proxy_pass ${custom_api_uri};
        proxy_http_version 1.1;
        proxy_ssl_verify off;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection $connection_upgrade;
    }
}
]],
    _server_backend_GETBLOCK = [[
server {
    listen unix:/tmp/${server_name}.sock;
    location / {
       ${_api_method()}
        proxy_redirect off;
        proxy_ssl_server_name on;
        proxy_set_header X-Api-Key ${getblock_api_key};
        proxy_set_header Host ${blockchain}.getblock.io;
        proxy_pass https://${blockchain}.getblock.io/${network}/;
        proxy_ssl_verify off;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection $connection_upgrade;
    }
}
]],
    _server_backend_MASSBIT = [[
server {
    listen unix:/tmp/${server_name}.sock;
    location / {
       ${_api_method()}
        proxy_redirect off;
        proxy_ssl_server_name on;
        proxy_pass http://${blockchain}-${network}.node.mbr.massbitroute.com;
        proxy_ssl_verify off;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection $connection_upgrade;
    }
}
]]
}

local function dirname(str)
    if str:match(".-/.-") then
        local name = string.gsub(str, "(.*/)(.*)", "%1")
        return name
    else
        return ""
    end
end

local function _norm(_v)
    print(inspect(_v))
    if type(_v) == "string" then
        _v = json.decode(_v)
    end

    if _v.entrypoints and type(_v.entrypoints) == "string" then
        _v.entrypoints = json.decode(_v.entrypoints)
        setmetatable(_v.entrypoints, cjson.empty_array_mt)
    end
    if _v.security and type(_v.security) == "string" then
        _v.security = json.decode(_v.security)
    end
    return _v
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
    for _, _file in ipairs(_files) do
        -- mkdirp(dirname(_file))
        _cmd = _cmd .. ";" .. _git .. "add -f " .. _file
    end
    if _rfiles then
        for _, _file in ipairs(_rfiles) do
            -- mkdirp(dirname(_file))
            _cmd = _cmd .. ";" .. _git .. "rm -f " .. _file
        end
    end

    _cmd = _cmd .. " ; " .. _git .. "commit -m update && " .. _git .. "push origin master"
    print(_cmd)
    local retcode, output = os.capture(_cmd)
    print(retcode)
    print(output)
end

local function _write_file(_filepath, content)
    print("write_file")
    if _filepath then
        mkdirp(dirname(_filepath))
        print(_filepath)
        print(content)
        local _file, _ = io_open(_filepath, "w+")
        if _file ~= nil then
            _file:write(content)
            _file:close()
        end
    end
end

local function _get_tmpl(_rules, _data)
    local _rules1 = table.copy(_rules)
    table.merge(_rules1, _data)
    return CodeGen(_rules1)
end

local function _remove_item(instance, args)
    local model = Model:new(instance)
    local _item = _norm(model:get(args))

    model:delete(args)
    -- _item = _item and type(_item) == "string" and json.decode(_item)
    print(inspect(_item))

    local _k1 = _item.blockchain .. "-" .. _item.network
    local _deploy_dir1 = _deploy_dir .. "/nodes/" .. _k1
    mkdirp(_deploy_dir1)
    local _deploy_file = _deploy_dir1 .. "/" .. _item.id .. ".conf"
    os.remove(_deploy_file)

    local _content_all = _read_dir(_deploy_dir1)
    local _content_all_file = _deploy_dir .. "/" .. _k1 .. ".conf"
    _write_file(_content_all_file, _content_all)
    _git_push(
        _deploy_dir,
        {
            _content_all_file
        },
        {
            _deploy_file
        }
    )
end

local function _generate_item(instance, args)
    local model = Model:new(instance)
    local _item = _norm(model:get(args))

    -- _item = _item and type(_item) == "string" and json.decode(_item)
    print(inspect(_item))
    local _content = {}

    if _item.entrypoints and #_item.entrypoints > 0 then
        local _entrypoints =
            table.map(
            _item.entrypoints,
            function(_ent)
                _ent.provider_id = PROVIDERS[_ent.type] .. "-" .. _ent.id
                _ent.api_key = _item.api_key
                _ent.server_name = _item.api_key .. "-" .. _ent.provider_id
                _ent.blockchain = _item.blockchain
                _ent.network = _item.network
                local _tmpl = _get_tmpl(rules, _ent)
                local _str_tmpl = _tmpl("_server_backend_" .. _ent.type)
                -- ngx.log(ngx.ERR, _str_tmpl)
                _content[#_content + 1] = _str_tmpl
                -- ngx.log(ngx.ERR, json.encode(_ent))
                return _ent
            end
        )

        local _tmpl = _get_tmpl(rules, {api_key = _item.api_key, entrypoints = _entrypoints})
        local _str_tmpl = _tmpl("_upstreams")
        -- ngx.log(ngx.ERR, inspect(_str_tmpl))

        if _item.security.limit_rate_per_sec and tonumber(_item.security.limit_rate_per_sec) > 0 then
            _item.security._is_limit_rate_per_sec = true
        end

        if _item.security.allow_methods and string.len(_item.security.allow_methods) > 0 then
            _item.security._is_allow_methods = true
        end

        _content[#_content + 1] = _str_tmpl
        local _tmpl1 = _get_tmpl(rules, _item)
        local _str_tmpl1 = _tmpl1("_server_main")
        _content[#_content + 1] = _str_tmpl1
    end
    print(table.concat(_content, "\n"))

    --- Generate config of dApi in deploy/dapi folder
    -- This folder also public for Gateway Community download for serving blockchain-network traffic

    local _k1 = _item.blockchain .. "-" .. _item.network
    local _deploy_dir1 = _deploy_dir .. "/nodes/" .. _k1
    mkdirp(_deploy_dir1)
    local _deploy_file = _deploy_dir1 .. "/" .. _item.id .. ".conf"
    _write_file(_deploy_file, table.concat(_content, "\n"))

    local _content_all = _read_dir(_deploy_dir1)
    local _content_all_file = _deploy_dir .. "/" .. _k1 .. ".conf"
    _write_file(_content_all_file, _content_all)
    _git_push(
        _deploy_dir,
        {
            _deploy_file,
            _content_all_file
        }
    )
end

--- Generate conf for gateway

function JobsAction:generateconfAction(job)
    print(inspect(job))

    local instance = self:getInstance()
    local job_data = job.data
    _generate_item(instance, job_data)
end

function JobsAction:removeconfAction(job)
    print(inspect(job))

    local instance = self:getInstance()
    local job_data = job.data
    _remove_item(instance, job_data)
end

return JobsAction
