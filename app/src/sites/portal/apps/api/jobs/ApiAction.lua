local cc = cc
local gbc = cc.import("#gbc")
local json = cc.import("#json")
local cjson = require("cjson")
local io_open = io.open
local mytype = "api"
local JobsAction = cc.class(mytype .. "JobsAction", gbc.ActionBase)

local inspect = require "inspect"

JobsAction.ACCEPTED_REQUEST_TYPE = "worker"

local Model = cc.import("#" .. mytype)

local CodeGen = require "CodeGen"

local _deploy_dir = "/massbit/massbitroute/app/src/sites/portal/public/deploy/dapi"

-- local CodeGen = require "CodeGen"
local mkdirp = require "mkdirp"
local gwman_dir = "/massbit/massbitroute/app/src/sites/services/gwman"
local stat_dir = "/massbit/massbitroute/app/src/sites/services/stat"

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

-- local function _read_file(path)
--     local file = io_open(path, "rb") -- r read mode and b binary mode
--     if not file then
--         return nil
--     end
--     local content = file:read "*a" -- *a or *all reads the whole file
--     file:close()
--     return content
-- end

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

local function _git_push(_dir, _files)
    local _git = "git -C " .. _dir .. " "
    local _cmd =
        "export HOME=/tmp && " ..
        _git ..
            " pull origin master ;" ..
                _git ..
                    "config --global user.email baysao@gmail.com" ..
                        "&&" .. _git .. "config --global user.name baysao && " .. _git .. "remote -v"
    for _, _file in ipairs(_files) do
        mkdirp(dirname(_file))
        _cmd = _cmd .. ";" .. _git .. "add -f " .. _file
    end
    _cmd = _cmd .. " ; " .. _git .. "commit -m update && " .. _git .. "push origin master"
    -- print(_cmd)
    local retcode, output = os.capture(_cmd)
    print(retcode)
    print(output)

    -- local handle = io.popen(_cmd)
    -- local result = handle:read("*a")
    -- handle:close()
    -- print(result)
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

        -- ngx.log(ngx.ERR, inspect(args))
        -- ngx.log(ngx.ERR, _str_tmpl)
        _content[#_content + 1] = _str_tmpl
        local _tmpl1 = _get_tmpl(rules, _item)
        local _str_tmpl1 = _tmpl1("_server_main")
        _content[#_content + 1] = _str_tmpl1
    -- ngx.log(ngx.ERR, _str_tmpl1)
    -- local _conf_file =
    --     "/massbit/massbitroute/app/src/sites/services/gateway/conf.d/" ..
    --     args.user_id .. "/" .. args.id .. "/server.conf"
    -- ngx.log(ngx.ERR, _conf_file)
    -- _write_template(
    --     {
    --         [_conf_file] = _content
    --     }
    -- )
    end
    print(table.concat(_content, "\n"))

    local _k1 = _item.blockchain .. "-" .. _item.network
    local _deploy_file = _deploy_dir .. "/" .. _k1 .. ".conf"
    _write_file(_deploy_file, table.concat(_content, "\n"))

    _git_push(
        _deploy_dir,
        {
            _deploy_file
        }
    )

    -- local _tmpl = _get_tmpl(rules, _item)
    -- local _str_tmpl = _tmpl("_local")
    -- print(_str_tmpl)
    -- mkdirp(_deploy_dir)
    -- _write_file(_deploy_dir .. "/" .. _item.id .. ".conf", _str_tmpl)
end

local function _update_gateway_conf(instance)
    local _prometheus = {
        [[
scrape_configs:
  - job_name: stat_vhost
    honor_labels: true
    metrics_path: /__internal_status_vhost/format/prometheus
    scrape_interval: 10s
    scrape_timeout: 5s
    # relabel_configs:
    #   - source_labels: [__address__]
    #     target_label: instance
    #     regex: "([^:]+)(:[0-9]+)?"
    #     replacement: "${1}"
    static_configs:
      - targets:]]
    }

    local _nodes = {}
    local _nodes_all = {}

    local _red = instance:getRedis()
    local _user_gw = _red:keys("*:" .. mytype)
    -- print(inspect(_user_gw))
    local _datacenters = {}
    for _, _k in ipairs(_user_gw) do
        local _gw_arr = _red:arrayToHash(_red:hgetall(_k))
        -- print(inspect(_gw_arr))
        for _, _gw_str in pairs(_gw_arr) do
            local _gw = json.decode(_gw_str)
            -- print(inspect(_gw))
            local _name = _gw.blockchain .. "-" .. _gw.network
            _nodes[_name] = _nodes[_name] or {}
            if _gw.id and _gw.ip then
                local _obj = {id = _gw.id, ip = _gw.ip}
                table.insert(_nodes[_name], _obj)
                table.insert(_nodes_all, _obj)
            end

            local _dc_id = table.concat({"mbr", "map", _gw.blockchain, _gw.network}, "-")
            _datacenters[_dc_id] = _datacenters[_dc_id] or {}
            if _gw.geo and _gw.geo.continent_code and _gw.geo.country_code then
                _datacenters[_dc_id][_gw.geo.continent_code] = _datacenters[_dc_id][_gw.geo.continent_code] or {}
                _datacenters[_dc_id][_gw.geo.continent_code][_gw.geo.country_code] =
                    _datacenters[_dc_id][_gw.geo.continent_code][_gw.geo.country_code] or {}
                table.insert(_datacenters[_dc_id][_gw.geo.continent_code][_gw.geo.country_code], _gw)
            end
        end
    end

    -- print(inspect(_datacenters))

    for _k1, _v1 in pairs(_datacenters) do
        local _dcs = {}
        local _mapstr = {}
        local _resstr = {}
        -- local _zonesstr = {}

        table.insert(_resstr, _k1 .. " =>{ ")
        table.insert(_resstr, "map => " .. _k1)
        table.insert(_resstr, "dcmap => { ")

        table.insert(_mapstr, _k1 .. " =>{ ")
        table.insert(_mapstr, "geoip2_db => GeoIP2-City.mmdb")
        table.insert(_mapstr, "map => {")
        for _k2, _v2 in pairs(_v1) do
            table.insert(_mapstr, _k2 .. " => { ")
            for _k3, _v3 in pairs(_v2) do
                local _dcname = _k1 .. "-" .. _k2 .. "-" .. _k3
                table.insert(_dcs, _dcname)
                table.insert(_mapstr, _k3 .. " => [ " .. _dcname .. " ]")
                table.insert(_resstr, _k1 .. "-" .. _k2 .. "-" .. _k3 .. " => [ ")
                for _, _v4 in ipairs(_v3) do
                    if _v4.id and _v4.ip then
                        table.insert(_prometheus, "          - " .. _v4.id .. ".gw.mbr.massbitroute.com")
                        -- table.insert(_zonesstr, _v4.id .. ".gw.mbr 600 A " .. _v4.ip)
                        table.insert(_resstr, _v4.ip .. ",")
                    end
                end

                table.insert(_resstr, "]")
            end
            table.insert(_mapstr, "},")
        end

        table.insert(_mapstr, "},")
        table.insert(_mapstr, "datacenters => [")
        for _, _dc in ipairs(_dcs) do
            table.insert(_mapstr, _dc .. ",")
        end
        table.insert(_mapstr, "]")

        table.insert(_mapstr, "}")

        table.insert(_resstr, "}")
        table.insert(_resstr, "}")
        -- print(table.concat(_mapstr, "\n"))
        _write_file(gwman_dir .. "/conf.d/geolocation.d/maps.d/" .. _k1, table.concat(_mapstr, "\n"))
        print(table.concat(_resstr, "\n"))
        _write_file(gwman_dir .. "/conf.d/geolocation.d/resources.d/" .. _k1, table.concat(_resstr, "\n"))
        -- print(table.concat(_zonesstr, "\n"))

        -- _write_file(gwman_dir .. "/data/zones/gateway_" .. _k1 .. ".zone", table.concat(_zonesstr, "\n"))
        _git_push(
            gwman_dir,
            {
                gwman_dir .. "/conf.d/geolocation.d/maps.d/" .. _k1,
                gwman_dir .. "/conf.d/geolocation.d/resources.d/" .. _k1
            }
        )
    end

    for _k1, _v1 in pairs(_nodes) do
        local _tmpl = _get_tmpl(rules, {nodes = _v1})
        local _str_stat = _tmpl("_gw_zones")
        _write_file(gwman_dir .. "/data/zones/gateway_" .. _k1 .. ".zone", _str_stat)
        _git_push(
            gwman_dir,
            {
                gwman_dir .. "/data/zones/gateway_" .. _k1 .. ".zone"
            }
        )
    end
    local _cmd = "/massbit/massbitroute/app/src/sites/portal/scripts/run _rebuild_zone"
    print(_cmd)
    local retcode, output = os.capture(_cmd)
    print(retcode)
    print(output)

    -- print(inspect(_nodes_all))
    local _tmpl = _get_tmpl(rules, {nodes = _nodes_all})

    local _str_stat = _tmpl("_gw_stat")
    _write_file(stat_dir .. "/etc/prometheus/stat_gw.yml", _str_stat)
    _git_push(
        stat_dir,
        {
            stat_dir .. "/etc/prometheus/stat_gw.yml"
        }
    )
end

--- Generate conf for gateway

function JobsAction:generateconfAction(job)
    print(inspect(job))

    local instance = self:getInstance()
    local job_data = job.data
    _generate_item(instance, job_data)
    -- _update_gateway_conf(instance)
end
return JobsAction
