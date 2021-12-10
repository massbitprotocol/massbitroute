local cc = cc
local gbc = cc.import("#gbc")
local json = cc.import("#json")
local io_open = io.open
local mytype = "node"
local JobsAction = cc.class(mytype .. "JobsAction", gbc.ActionBase)

local inspect = require "inspect"

JobsAction.ACCEPTED_REQUEST_TYPE = "worker"

local CodeGen = require "CodeGen"

-- local _deploy_gw_dir = "/massbit/massbitroute/app/src/sites/portal/public/deploy/gateway"
local _deploy_dir = "/massbit/massbitroute/app/src/sites/portal/public/deploy/node"

local Model = cc.import("#" .. mytype)

-- local CodeGen = require "CodeGen"
local mkdirp = require "mkdirp"
local gwman_dir = "/massbit/massbitroute/app/src/sites/services/gwman"
local stat_dir = "/massbit/massbitroute/app/src/sites/services/stat"

local rules = {
    _node_zone = [[${id}.node.mbr 600 A ${ip}]],
    _node_zones = [[${nodes/_node_zone(); separator='\n'}]],
    _node_stat_target = [[          - ${id}.node.mbr.massbitroute.com]],
    _node_stat = [[
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
      - targets:
${nodes/_node_stat_target(); separator='\n'}
]],
    _gw_node_upstream = [[
server unix:/tmp/${id}.sock;
]],
    _gw_node_upstreams = [[
upstream eth-mainnet.node.mbr.massbitroute.com {
${nodes/_gw_node_upstream()}
keepalive 32;
}
]],
    _gw_node = [[
server {
    listen unix:/tmp/${id}.sock;
    location / {
               set $api_method '';
               access_by_lua_file /massbit/massbitroute/app/src/sites/services/gateway/src/jsonrpc-access.lua;
               vhost_traffic_status_filter_by_set_key $api_method ${id}::api_method;
        proxy_redirect off;
        proxy_ssl_server_name on;
        proxy_set_header X-Api-Key ${token};
        proxy_set_header Host ${id}.node.mbr.massbitroute.com;
        proxy_pass https://${ip};
        proxy_http_version 1.1;
        proxy_ssl_verify off;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection $connection_upgrade;
    }
}
]],
    _gw_nodes = [[
${nodes/_gw_node()}
]],
    _local = [[
map $http_x_api_key $api_realm {
    default '';
    ${token} mbr_node_admin;
}

server {
    listen 80;
    listen 443 ssl;
    ssl_certificate  /massbit/massbitroute/app/src/sites/services/node/ssl/node.mbr.massbitroute.com/fullchain.pem;
    ssl_certificate_key  /massbit/massbitroute/app/src/sites/services/node/ssl/node.mbr.massbitroute.com/privkey.pem;
    resolver 8.8.4.4 ipv6=off;
    client_body_buffer_size 512K;
    client_max_body_size 1G;
    server_name ${id}.node.mbr.massbitroute.com node.mbr.massbitroute.com;
    access_log /massbit/massbitroute/app/src/sites/services/node/logs/${id}-access.log main_json;
    error_log /massbit/massbitroute/app/src/sites/services/node/logs/${id}-error.log debug;
    # API keys verification
    location = /authorize_apikey {
        internal;
        if ($api_realm = '') {
            return 403; # Forbidden
        }
        if ($http_x_api_key = '') {
            return 401; # Unauthorized
        }
        return 204; # OK
    }
    location /ping {
        return 200 pong;
    }
    location / {
        proxy_pass http://127.0.0.1:8545;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection $connection_upgrade;
        if ($request_method = OPTIONS) {
            add_header Access-Control-Allow-Headers 'X-API-Key, Authorization';
        }
        satisfy any;
        auth_request /authorize_apikey;
    }
    location /__internal_status_vhost/ {
        # auth_basic 'MBR admin';
        # auth_basic_user_file /massbit/massbitroute/app/src/sites/services/node/etc/htpasswd;
        vhost_traffic_status_bypass_limit on;
        vhost_traffic_status_bypass_stats on;
        vhost_traffic_status_display;
        vhost_traffic_status_display_format html;
    }
}
]],
    _upstream_server = [[server unix:/tmp/${id}.sock;]],
    _upstream = [[
upstream eth-mainnet.node.mbr.massbitroute.com {
${}
keepalive 32;
}
]],
    _api_method = [[
        set $api_method '';
        access_by_lua_file /massbit/massbitroute/app/src/sites/services/node/src/jsonrpc-access.lua;
        vhost_traffic_status_filter_by_set_key $api_method ${id}::api_method;
]],
    _node = [[
server {
    listen unix:/tmp/${id}.sock;
    location / {
       ${_api_method()}
        proxy_redirect off;
        proxy_ssl_server_name on;
        proxy_set_header X-Api-Key ${token};
        proxy_set_header Host ${id}.node.mbr.massbitroute.com;
        proxy_pass https://${ip};
        proxy_http_version 1.1;
        proxy_ssl_verify off;
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

local function _get_tmpl(_rules, _data)
    local _rules1 = table.copy(_rules)
    table.merge(_rules1, _data)
    return CodeGen(_rules1)
end

local function _git_push(_dir, _files)
    mkdirp(_dir)
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
        _cmd = _cmd .. ";" .. _git .. "add " .. _file
    end
    _cmd = _cmd .. " ; " .. _git .. "commit -m update && " .. _git .. "push origin master"
    print(_cmd)
    local retcode, output = os.capture(_cmd)
    print(retcode)
    print(output)

    -- local handle = io.popen(_cmd)
    -- local result = handle:read("*a")
    -- handle:close()
    -- print(result)
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

-- local function _get_tmpl(_rules, _data)
--     local _rules1 = table.copy(_rules)
--     table.merge(_rules1, _data)
--     return CodeGen(_rules1)
-- end
--- Generate conf for node

-- local function _refresh_config(instance)
--     local _prometheus = {
--         [[
-- scrape_configs:
--   - job_name: stat_vhost
--     honor_labels: true
--     metrics_path: /__internal_status_vhost/format/prometheus
--     scrape_interval: 10s
--     scrape_timeout: 5s
--     # relabel_configs:
--     #   - source_labels: [__address__]
--     #     target_label: instance
--     #     regex: "([^:]+)(:[0-9]+)?"
--     #     replacement: "${1}"
--     static_configs:
--       - targets:]]
--     }

--     local _datacenters = {}

--     local _red = instance:getRedis()
--     local _user_gw = _red:keys("*:" .. mytype)
--     print(inspect(_user_gw))
--     for _, _k in ipairs(_user_gw) do
--         local _gw_arr = _red:arrayToHash(_red:hgetall(_k))
--         print(inspect(_gw_arr))
--         for _, _gw_str in pairs(_gw_arr) do
--             local _gw = json.decode(_gw_str)
--             print(inspect(_gw))
--             -- local _dc_id = table.concat({"mbr", "map", _gw.blockchain, _gw.network}, "-")
--             local _dc_id = table.concat({_gw.blockchain, _gw.network}, "-")
--             _datacenters[_dc_id] = _datacenters[_dc_id] or {}
--             if _gw.geo and _gw.geo.continent_code and _gw.geo.country_code then
--                 _datacenters[_dc_id][_gw.geo.continent_code] = _datacenters[_dc_id][_gw.geo.continent_code] or {}
--                 _datacenters[_dc_id][_gw.geo.continent_code][_gw.geo.country_code] =
--                     _datacenters[_dc_id][_gw.geo.continent_code][_gw.geo.country_code] or {}
--                 table.insert(_datacenters[_dc_id][_gw.geo.continent_code][_gw.geo.country_code], _gw)
--             end
--         end
--     end
--     print(inspect(_datacenters))

-- for _k1, _v1 in pairs(_datacenters) do
--     for _k2, _v2 in pairs(_v1) do
--         for _k3, _v3 in pairs(_v2) do
--             for _, _v4 in ipairs(_v3) do
--                 print(inspect(_v4))
--                 local _tmpl = _get_tmpl(rules, _v4)
--                 local _str_tmpl = _tmpl("_node")
--                 print(_str_tmpl)
--                 local _dpath = deploy_dir .. "/" .. _v4.geo.continent_code .. "/" .. _v4.geo.country_code
--                 mkdirp(_dpath)
--                 _write_file(_dpath .. "/" .. _v4.id .. ".conf", _str_tmpl)
--             end
--         end
--     end
-- end
--     local _dcs = {}
--     local _mapstr = {}
--     local _resstr = {}
--     local _zonesstr = {}

--     table.insert(_resstr, _k1 .. " =>{ ")
--     table.insert(_resstr, "map => " .. _k1)
--     table.insert(_resstr, "dcmap => { ")

--     table.insert(_mapstr, _k1 .. " =>{ ")
--     table.insert(_mapstr, "geoip2_db => GeoIP2-City.mmdb")
--     table.insert(_mapstr, "map => {")
--     for _k2, _v2 in pairs(_v1) do
--         table.insert(_mapstr, _k2 .. " => { ")
--         for _k3, _v3 in pairs(_v2) do
--             local _dcname = _k1 .. "-" .. _k2 .. "-" .. _k3
--             table.insert(_dcs, _dcname)
--             table.insert(_mapstr, _k3 .. " => [ " .. _dcname .. " ]")
--             table.insert(_resstr, _k1 .. "-" .. _k2 .. "-" .. _k3 .. " => [ ")
--             for _, _v4 in ipairs(_v3) do
--                 table.insert(_prometheus, "          - " .. _v4.id .. ".gw.mbr.massbitroute.com")
--                 table.insert(_zonesstr, _v4.id .. ".gw.mbr 600 A " .. _v4.ip)
--                 table.insert(_resstr, _v4.ip .. ",")
--             end

--             table.insert(_resstr, "]")
--         end
--         table.insert(_mapstr, "},")
--     end

--     table.insert(_mapstr, "},")
--     table.insert(_mapstr, "datacenters => [")
--     for _, _dc in ipairs(_dcs) do
--         table.insert(_mapstr, _dc .. ",")
--     end
--     table.insert(_mapstr, "]")

--     table.insert(_mapstr, "}")

--     table.insert(_resstr, "}")
--     table.insert(_resstr, "}")
--     print(table.concat(_mapstr, "\n"))
--     _write_file(gwman_dir .. "/conf.d/geolocation.d/maps.d/" .. _k1, table.concat(_mapstr, "\n"))
--     print(table.concat(_resstr, "\n"))
--     _write_file(gwman_dir .. "/conf.d/geolocation.d/resources.d/" .. _k1, table.concat(_resstr, "\n"))
--     print(table.concat(_zonesstr, "\n"))

--     _write_file(gwman_dir .. "/data/zones/" .. _k1 .. ".zone", table.concat(_zonesstr, "\n"))
--     _git_push(
--         gwman_dir,
--         {
--             gwman_dir .. "/conf.d/geolocation.d/maps.d/" .. _k1,
--             gwman_dir .. "/conf.d/geolocation.d/resources.d/" .. _k1,
--             gwman_dir .. "/data/zones/" .. _k1 .. ".zone"
--         }
--     )
-- end
-- _write_file(stat_dir .. "/etc/prometheus/stat.yml", table.concat(_prometheus, "\n"))
-- _git_push(
--     stat_dir,
--     {
--         stat_dir .. "/etc/prometheus/stat.yml"
--     }
-- )
--end

local function _generate_item(instance, args)
    local model = Model:new(instance)
    local _item = model:get(args)
    _item = _item and type(_item) == "string" and json.decode(_item)
    print(inspect(_item))

    local _tmpl = _get_tmpl(rules, _item)
    local _str_tmpl = _tmpl("_local")
    print(_str_tmpl)
    mkdirp(_deploy_dir)
    _write_file(_deploy_dir .. "/" .. _item.id .. ".conf", _str_tmpl)
end

local function _update_nodes_conf(instance)
    local _red = instance:getRedis()
    local _user_gw = _red:keys("*:" .. mytype)
    print(inspect(_user_gw))

    local _nodes = {}
    local _config = {}
    for _, _k in ipairs(_user_gw) do
        local _gw_arr = _red:arrayToHash(_red:hgetall(_k))
        print(inspect(_gw_arr))
        for _, _gw_str in pairs(_gw_arr) do
            local _gw = json.decode(_gw_str)
            print(inspect(_gw))
            local _name = _gw.blockchain .. "-" .. _gw.network
            _nodes[_name] = _nodes[_name] or {}
            _config[_name] = _config[_name] or {}
            if _gw.id and _gw.ip then
                table.insert(_nodes[_name], {id = _gw.id, ip = _gw.ip})
            end
            local _tmpl = _get_tmpl(rules, _gw)
            local _str_tmpl = _tmpl("_gw_node")
            table.insert(_config[_name], _str_tmpl)
        end
    end
    for _k1, _v1 in pairs(_nodes) do
        local _tmpl = _get_tmpl(rules, {nodes = _v1})
        local _str_tmpl = _tmpl("_gw_node_upstreams")
        table.insert(_config[_k1], _str_tmpl)
        mkdirp(_deploy_dir)
        _write_file(_deploy_dir .. "/" .. _k1 .. ".conf", table.concat(_config[_k1], "\n"))
        local _str_stat = _tmpl("_node_stat")
        _write_file(stat_dir .. "/etc/prometheus/stat_node.yml", _str_stat)
        _git_push(
            stat_dir,
            {
                stat_dir .. "/etc/prometheus/stat_node.yml"
            }
        )

        local _str_zones = _tmpl("_node_zones")
        print(_str_zones)
        _write_file(gwman_dir .. "/data/zones/node_" .. _k1 .. ".zone", _str_zones)
        _git_push(
            gwman_dir,
            {
                gwman_dir .. "/data/zones/node_" .. _k1 .. ".zone"
            }
        )
    end
end

function JobsAction:generateconfAction(job)
    print(inspect(job))

    local instance = self:getInstance()

    local job_data = job.data
    _generate_item(instance, job_data)
    -- _refresh_config(instance, job_data)
    _update_nodes_conf(instance)
end
return JobsAction
