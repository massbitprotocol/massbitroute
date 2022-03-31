--- API jobs scheduler help run background job
--@module ApiAction Job

local cc = cc
local mytype = "api"
local gbc = cc.import("#gbc")
local json = cc.import("#json")
local table_map = table.map
local table_walk = table.walk
local table_concat = table.concat

local cjson = require("cjson")

local JobsAction = cc.class(mytype .. "JobsAction", gbc.ActionBase)

local mbrutil = require "mbutil" -- cc.import("#mbrutil")

local _read_dir = mbrutil.read_dir

local _write_file = mbrutil.write_file
local _get_tmpl = mbrutil.get_template
local _print = mbrutil.print

local mkdirp = require "mkdirp"
local inspect = require "inspect"

-- local shell = require "shell"
local shell = require "shell-games"

JobsAction.ACCEPTED_REQUEST_TYPE = "worker"

local Model = cc.import("#" .. mytype)
local env = require "env"
local _domain_name = env.DOMAIN or "massbitroute.com"
local _session_key = env.SESSION_KEY or ""
local _session_iv = env.SESSION_IV or ""
local _session_expires = env.SESSION_EXPIRES or "1d"
local _service_dir = "/massbit/massbitroute/app/src/sites/services"
local _portal_dir = _service_dir .. "/api"
local _deploy_dir = _portal_dir .. "/public/deploy/dapi"
local _deploy_confdir = _portal_dir .. "/public/deploy/dapiconf"
-- local gwman_dir = _service_dir .. "/gwman"

local PROVIDERS = {
    MASSBIT = 0,
    CUSTOM = 1,
    GETBLOCK = 2,
    QUICKNODE = 3,
    INFURA = 4
}

-- Templates for conf generate
--
local rules = {
    _backup1 = [[backup]],
    _backup = [[]],
    _priority = [[weight=${priority}]],
    _upstream = [[server unix:/tmp/${server_name}.sock max_fails=1 fail_timeout=3s ${_is_backup?_backup()!_priority()};]],
    _upstreams = [[
upstream upstream_${api_key} {
    ${entrypoints/_upstream()}
}
]],
    _api_method1 = "",
    _api_method = [[
#       access_by_lua_file /massbit/massbitroute/app/src/sites/services/gateway/src/jsonrpc-access.lua;
        vhost_traffic_status_filter_by_set_key $api_method ${server_name}::dapi::api_method;
]],
    _allow_methods1 = [[set $jsonrpc_whitelist '${security.allow_methods}';]],
    _limit_rate_per_sec2 = [[limit_req zone=${api_key};]],
    _limit_rate_per_sec1 = [[limit_req_zone $binary_remote_addr zone=${api_key}:10m rate=${security.limit_rate_per_sec}r/s;]],
    _server_main = [[
${security._is_limit_rate_per_sec?_limit_rate_per_sec1()}

server {
    listen 80;
    listen 443 ssl;
    ssl_certificate /etc/letsencrypt/live/${blockchain}-${network}.]] ..
        _domain_name ..
            [[/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/${blockchain}-${network}.]] ..
                _domain_name ..
                    [[/privkey.pem;
    resolver 8.8.4.4 ipv6=off;
    client_body_buffer_size 512K;
    client_max_body_size 1G;
    server_name ${gateway_domain};
    access_log /massbit/massbitroute/app/src/sites/services/gateway/logs/nginx-${gateway_domain}-access.log main_json;
    error_log /massbit/massbitroute/app/src/sites/services/gateway/logs/nginx-${gateway_domain}-error.log debug;

    set $api_method '';
    set $jsonrpc_whitelist '';

    encrypted_session_key ]] ..
                        _session_key ..
                            [[;
    encrypted_session_iv ]] ..
                                _session_iv ..
                                    [[;
    encrypted_session_expires ]] ..
                                        _session_expires ..
                                            [[;

    location /${api_key} {
        set $mbr_token ${api_key};
        rewrite /(.*) / break;
        ${security._is_limit_rate_per_sec?_limit_rate_per_sec2()}
        ${_allow_methods1()}

        access_by_lua_file /massbit/massbitroute/app/src/sites/services/gateway/src/filter-jsonrpc-access.lua;
        vhost_traffic_status_filter_by_set_key $api_method ${api_key}::dapi::api_method;
        vhost_traffic_status_filter_by_set_key $api_method __GATEWAY_ID__::gw::api_method;

        add_header X-Mbr-Gateway-Id __GATEWAY_ID__;
        proxy_cache_use_stale updating error timeout invalid_header http_500 http_502 http_503 http_504;
        proxy_next_upstream error timeout invalid_header http_500 http_502 http_503 http_504;

        proxy_connect_timeout 3;
        proxy_send_timeout 3;
        proxy_read_timeout 3;
        send_timeout 3;

        proxy_cache_methods GET HEAD POST;
        proxy_cache_key $request_uri|$request_body;
        proxy_cache_min_uses 1;
        proxy_cache cache;
        proxy_cache_valid 200 10s;
        proxy_cache_background_update on;
        proxy_cache_lock on;
        proxy_cache_revalidate on;
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
       ${_api_method1()}
        proxy_redirect off;
        set_encode_base64 $digest :${project_secret};
        proxy_set_header Authorization 'Basic $digest';
        proxy_ssl_verify off;
        proxy_ssl_server_name on;
        proxy_pass https://mainnet.infura.io/v3/${project_id};
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
       ${_api_method1()}
        proxy_redirect off;
        proxy_ssl_server_name on;
        proxy_pass ${api_uri};
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
       ${_api_method1()}
        proxy_redirect off;
        proxy_ssl_server_name on;
        proxy_pass ${api_uri};
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
       ${_api_method1()}
        proxy_redirect off;
        proxy_ssl_server_name on;
        proxy_set_header X-Api-Key '${ent_api_key}';
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
       ${_api_method1()}
        proxy_redirect off;
        proxy_ssl_server_name on;
        proxy_next_upstream error timeout invalid_header http_500 http_502 http_503 http_504;
        proxy_connect_timeout 3;
        proxy_send_timeout 3;
        proxy_read_timeout 3;

        proxy_pass http://${blockchain}-${network}.node.mbr.]] ..
        _domain_name ..
            [[;
        proxy_ssl_verify off;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection $connection_upgrade;
    }
}
]]
}

---   Normalize Entrypoint properpties of Dapi
--
local function _norm_entrypoint(_ent, _item)
    if not _ent.priority or tonumber(_ent.priority) == 0 then
        _ent.priority = 1
    end

    if _ent.backup and tonumber(_ent.backup) == 1 then
        _ent._is_backup = true
    end

    _ent.provider_id = PROVIDERS[_ent.type] .. "-" .. _ent.id
    if _ent.api_key then
        _ent.ent_api_key = _ent.api_key
    end

    _ent.api_key = _item.api_key
    _ent.server_name = _item.api_key .. "-" .. _ent.provider_id
    _ent.blockchain = _item.blockchain
    _ent.network = _item.network
    return _ent
end

--- Normalize dapi detail
--
local function _norm(_v)
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

--- Remove conf handler
--
local function _remove_item(instance, args)
    _print("remove_item:" .. inspect(args))
    local model = Model:new(instance)
    local _item = _norm(model:get(args))
    _print("_item:" .. inspect(_item))
    if args._is_delete then
        model:delete({id = args.id, user_id = args.user_id})
    end

    if not _item.id or not _item.blockchain or not _item.network then
        return false
    end
    local _item_path = table_concat({_deploy_dir, _item.blockchain, _item.network, _item.user_id}, "/")

    local _item_file = _item_path .. "/" .. _item.id
    _print("remove:" .. _item_file)
    os.remove(_item_file)

    local _blocknet = _item.blockchain .. "-" .. _item.network
    local _blocknet_dir = _deploy_confdir .. "/nodes/" .. _blocknet
    mkdirp(_blocknet_dir)
    local _deploy_file = _blocknet_dir .. "/" .. _item.id .. ".conf"
    _print("remove:" .. _deploy_file)
    os.remove(_deploy_file)

    local _content_all = _read_dir(_blocknet_dir)
    local _content_all_file = _deploy_confdir .. "/" .. _blocknet .. ".conf"
    -- os.remove(_content_all_file)
    _write_file(_content_all_file, _content_all)

    return true
end

--- Generate conf handler
--
local function _generate_item(instance, args)
    local model = Model:new(instance)

    -- query dapi from db
    local _item = _norm(model:get(args))

    if not _item.id or not _item.blockchain or not _item.network then
        return false
    end

    -- path for dump data
    local _item_path = table_concat({_deploy_dir, _item.blockchain, _item.network, _item.user_id}, "/")

    -- make sure dir created
    mkdirp(_item_path)

    -- dump data dapi into file for later reference
    _write_file(_item_path .. "/" .. _item.id, json.encode(_item))

    local _content = {}

    if _item.entrypoints then
        local _entrypoints_active = {}

        -- filter entrypoints with active status
        table_walk(
            _item.entrypoints,
            function(_v)
                if _v and _v.status and tonumber(_v.status) == 1 then
                    _entrypoints_active[#_entrypoints_active + 1] = _v
                end
            end
        )
        _item.entrypoints = _entrypoints_active

        if #_item.entrypoints > 0 then
            local _entrypoints_new =
                table_map(
                _item.entrypoints,
                function(_ent)
                    _ent = _norm_entrypoint(_ent, _item)
                    local _tmpl = _get_tmpl(rules, _ent)
                    local _str_tmpl = _tmpl("_server_backend_" .. _ent.type)
                    _content[#_content + 1] = _str_tmpl
                    return _ent
                end
            )

            local _tmpl =
                _get_tmpl(
                rules,
                {
                    api_key = _item.api_key,
                    entrypoints = _entrypoints_new
                }
            )

            -- generate upstream conf from entrypoints
            local _tmpl_upstream = _tmpl("_upstreams")

            if _item.security.limit_rate_per_sec and tonumber(_item.security.limit_rate_per_sec) > 0 then
                _item.security._is_limit_rate_per_sec = true
            end

            if _item.security.allow_methods and string.len(_item.security.allow_methods) > 0 then
                _item.security._is_allow_methods = true
            end

            _content[#_content + 1] = _tmpl_upstream

            -- generate servers conf link with upstreams
            local _tmpl_server = _get_tmpl(rules, _item)
            _content[#_content + 1] = _tmpl_server("_server_main")
        end
    end

    local _blocknet = _item.blockchain .. "-" .. _item.network

    -- Folder save each nginx conf of dapi
    local _blocknet_dir = _deploy_confdir .. "/nodes/" .. _blocknet
    mkdirp(_blocknet_dir)

    local _deploy_file = _blocknet_dir .. "/" .. _item.id .. ".conf"

    -- write conf for dapi in blocknet dir
    _write_file(_deploy_file, table_concat(_content, "\n"))
    local _cmd = {
        _portal_dir .. "/scripts/run",
        "_test_node",
        _item.id,
        _blocknet,
        _deploy_file
    }
    local _res = shell.run(_cmd)

    if _res.status ~= 0 then
        os.remove(_deploy_file)
        return false
    end

    local _cmd = {
        _portal_dir .. "/scripts/run",
        "_test_node",
        _item.id,
        _blocknet,
        _deploy_file
    }
    local _res = shell.run(_cmd)

    if _res.status ~= 0 then
        os.remove(_deploy_file)
        return false
    end
    -- read all file in blocknet dir
    local _content_all = _read_dir(_blocknet_dir)
    local _combine_file = _deploy_confdir .. "/" .. _blocknet .. ".conf"

    -- combine all content into one file of blockchain-network for gateway later download
    _write_file(_combine_file, _content_all)

    -- create new rule for domain with blockchain-network
    -- local _file_dapi = gwman_dir .. "/data/zones/dapi/" .. _blocknet .. ".zone"
    -- _write_file(_file_dapi, "*." .. _blocknet .. " 60/60 DYNA	geoip!mbr-map-" .. _blocknet .. "\n")
    return true
end

local function _generate_multi_item(instance, args)
    local _ids = args.ids
    args.ids = nil
    if _ids then
        for _, _id in ipairs(_ids) do
            _generate_item(instance, table.merge({id = _id}, args))
        end
    end
end

local function _remove_multi_item(instance, args)
    local _ids = args.ids
    args.ids = nil
    if _ids then
        for _, _id in ipairs(_ids) do
            _remove_item(instance, table.merge({id = _id}, args))
        end
    end
end

--- Job handler for generate conf
--
function JobsAction:generateconfAction(job)
    print(inspect(job))

    local instance = self:getInstance()
    local job_data = job.data

    job_data._domain_name = _domain_name
    _generate_item(instance, job_data)
end

--- Job handler for remove conf
--
function JobsAction:removeconfAction(job)
    print(inspect(job))

    local instance = self:getInstance()
    local job_data = job.data
    _remove_item(instance, job_data)
end

function JobsAction:removemulticonfAction(job)
    print(inspect(job))

    local instance = self:getInstance()
    local job_data = job.data
    _remove_multi_item(instance, job_data)
end

function JobsAction:generatemulticonfAction(job)
    print(inspect(job))

    local instance = self:getInstance()
    local job_data = job.data
    _generate_multi_item(instance, job_data)
end

return JobsAction
