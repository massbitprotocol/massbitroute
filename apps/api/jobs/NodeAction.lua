local cc = cc
local gbc = cc.import("#gbc")
local json = cc.import("#json")

local mytype = "node"
local JobsAction = cc.class(mytype .. "JobsAction", gbc.ActionBase)

local mbrutil = require "mbutil" -- cc.import("#mbrutil")

local read_dir = mbrutil.read_dir
local read_file = mbrutil.read_file
local show_folder = mbrutil.show_folder
local inspect = mbrutil.inspect

local _print = mbrutil.print

local _write_file = mbrutil.write_file
local _get_tmpl = mbrutil.get_template
-- local _git_push = mbrutil.git_push

JobsAction.ACCEPTED_REQUEST_TYPE = "worker"

local lfs = require "lfs"
local function is_dir(path)
    -- lfs.attributes will error on a filename ending in '/'
    return path:sub(-1) == "/" or lfs.attributes(path, "mode") == "directory"
end
local _service_dir = "/massbit/massbitroute/app/src/sites/services"
local _portal_dir = _service_dir .. "/api"
local _deploy_dir = _portal_dir .. "/public/deploy/node"

local _info_dir = _portal_dir .. "/public/deploy/info"

local _deploy_nodeconfdir = _portal_dir .. "/public/deploy/nodeconf"
local _deploy_gatewayconfdir = _portal_dir .. "/public/deploy/gatewayconf"

local Model = cc.import("#" .. mytype)

local mkdirp = require "mkdirp"
local _gwman_dir = _service_dir .. "/gwman"
local _stat_dir = _service_dir .. "/stat"

local rules = {
    _listid = [[${id} ${user_id} ${blockchain} ${network} ${ip} ${geo.continent_code} ${geo.country_code} ${token} ${status} ${approved}]],
    _listids = [[${nodes/_listid(); separator='\n'}]],
    _node_zone = [[${id}.node.mbr 60 A ${ip}]],
    _node_zones = [[${nodes/_node_zone(); separator='\n'}]],
    _node_stat_target = [[          - ${id}.node.mbr.massbitroute.com]],
    _node_stat_v1 = [[${nodes/_node_stat_target(); separator='\n'}]],
    _node_stat = [[
scrape_configs:
  - job_name: stat_vhost
    scheme: https
    tls_config:
      insecure_skip_verify: true
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
server unix:/tmp/${id}.sock max_fails=1 fail_timeout=3s;
]],
    _gw_node_approved = [[
${_is_approved?_gw_node()}
]],
    _gw_node_enabled = [[
${_is_enabled?_gw_node()}
]],
    _gw_node_upstream_approved = [[
${_is_approved?_gw_node_upstream()}
]],
    _gw_node_upstreams = [[
upstream ${node_type}.node.mbr.massbitroute.com {
${nodes/_gw_node_upstream_approved()}
}
]],
    _gw_node = [[
server {
    listen unix:/tmp/${id}.sock;
    location / {
        proxy_redirect off;
        proxy_ssl_server_name on;
        proxy_set_header X-Api-Key ${token};
        proxy_set_header Host ${id}.node.mbr.massbitroute.com;
        add_header X-Mbr-GNode-Id ${id};
        proxy_pass https://${ip};
        proxy_http_version 1.1;
        proxy_ssl_verify off;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection $connection_upgrade;
    }
}
]],
    _gw_nodes = [[
${nodes/_gw_node_approved()}
]],
    _gw_conf = [[
${_gw_nodes()}
${_gw_node_upstreams()}
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
    server_name ${id}.node.mbr.massbitroute.com;
  

    set $api_method '';
    set $jsonrpc_whitelist '';
   
    location /ping {
        return 200 pong;
    }
    location / {
  access_log /massbit/massbitroute/app/src/sites/services/node/logs/api-${id}-access.log main_json;
    error_log /massbit/massbitroute/app/src/sites/services/node/logs/api-${id}-error.log debug;

       if ($api_realm = '') {
            return 403; # Forbidden
        }

        add_header X-Mbr-Node-Id ${id};

        access_by_lua_file /massbit/massbitroute/app/src/sites/services/node/src/jsonrpc-access.lua;
        vhost_traffic_status_filter_by_set_key $api_method ${id}::node::api_method;

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
        add_header X-Cached-Node $upstream_cache_status;
        proxy_ssl_verify off;

        proxy_redirect off;
        proxy_ssl_server_name on;
        proxy_pass ${data_url};
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection $connection_upgrade;
        if ($request_method = OPTIONS) {
            add_header Access-Control-Allow-Headers 'X-API-Key, Authorization';
        }
    }
    location /__internal_status_vhost/ {
  access_log /massbit/massbitroute/app/src/sites/services/node/logs/stat-${id}-access.log main_json;
    error_log /massbit/massbitroute/app/src/sites/services/node/logs/stat-${id}-error.log debug;
        # auth_basic 'MBR admin';
        # auth_basic_user_file /massbit/massbitroute/app/src/sites/services/node/etc/htpasswd;
        vhost_traffic_status_bypass_limit on;
        vhost_traffic_status_bypass_stats on;
        vhost_traffic_status_display;
        vhost_traffic_status_display_format html;
    }
}
]],
    _upstream_server = [[server unix:/tmp/${id}.sock max_fails=1 fail_timeout=3s;]],
    _upstream = [[
upstream eth-mainnet.node.mbr.massbitroute.com {
${_upstream_server}
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

local function _norm(_v)
    if type(_v) == "string" then
        _v = json.decode(_v)
    end

    return _v
end

local function _remove_item(instance, args)
    _print("remove_item:" .. inspect(args))
    local model = Model:new(instance)
    local _item = _norm(model:get(args))
    -- _print(inspect(_item))
    if args._is_delete then
        model:delete({id = args.id, user_id = args.user_id})
    -- else
    --     model:update({id = args.id, user_id = args.user_id, status = 0})
    end
    if
        not _item or not _item.id or not _item.ip or not _item.blockchain or not _item.network or not _item.geo or
            not _item.geo.continent_code or
            not _item.geo.country_code
     then
        return nil, "invalid data"
    end
    local _item_path =
        table.concat(
        {
            _deploy_dir,
            _item.blockchain,
            _item.network,
            _item.geo.continent_code,
            _item.geo.country_code,
            _item.user_id
        },
        "/"
    )
    local _deploy_file = _item_path .. "/" .. _item.id
    if args._is_delete then
        -- _git_push(
        --     _deploy_dir,
        --     {},
        --     {
        --         _deploy_file
        --     }
        -- )
        -- local _k1 =
        --     _item.blockchain .. "/" .. _item.network .. "/" .. _item.geo.continent_code .. "/" .. _item.geo.country_code
        -- mkdirp(_deploy_dir .. "/" .. _k1)
        -- local _deploy_file = _deploy_dir .. "/" .. _k1 .. "/" .. _item.id
        _print("remove file:" .. _deploy_file)
        os.remove(_deploy_file)
    else
        table.merge(_item, args)
        _item._is_delete = nil
        _write_file(_deploy_file, json.encode(_item))
    end

    return true
end

local function _rescanconf_blockchain_network(_blockchain, _network)
    local _datacenters = {}
    local _actives = {}
    local _approved = {}
    local _blocknet_id = _blockchain .. "-" .. _network
    local _network_dir = _deploy_dir .. "/" .. _blockchain .. "/" .. _network
    for _, _continent in ipairs(show_folder(_network_dir)) do
        local _continent_dir = _network_dir .. "/" .. _continent
        if is_dir(_continent_dir) then
            for _, _country in ipairs(show_folder(_continent_dir)) do
                local _country_dir = _continent_dir .. "/" .. _country
                if is_dir(_country_dir) then
                    for _, _user_id in ipairs(show_folder(_country_dir)) do
                        local _user_dir = _country_dir .. "/" .. _user_id
                        if is_dir(_user_dir) then
                            for _, _id in ipairs(show_folder(_user_dir)) do
                                -- _print("_file:" .. _id)
                                if _id ~= ".gitkeep" then
                                    local _item = read_file(_user_dir .. "/" .. _id)

                                    _print("path:" .. _user_dir .. "/" .. _id)
                                    -- _print("item:" .. _item)
                                    if _item then
                                        if type(_item) == "string" then
                                            _item = json.decode(_item)
                                        end

                                        if tonumber(_item.status) == 1 then
                                            _item._is_enabled = true
                                            _actives[#_actives + 1] = _item
                                            if _item.approved and tonumber(_item.approved) == 1 then
                                                _approved[#_approved + 1] = _item
                                                _item._is_approved = true
                                                table.insert(_datacenters, _item)
                                            end
                                        end

                                    -- table.insert(_datacenter_ids_all, {id = _item.id, ip = _item.ip})
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    _print("datacenters:" .. inspect(_datacenters))
    if _datacenters and #_datacenters > 0 then
        -- _print("actives:" .. inspect(_actives))
        local _tmpl = _get_tmpl(rules, {node_type = _blocknet_id, nodes = _datacenters})
        local _str_tmpl = _tmpl("_gw_conf")
        _print(_str_tmpl)
        local _file_gw = _deploy_gatewayconfdir .. "/" .. _blocknet_id .. ".conf"
        _print(_file_gw)
        _write_file(_file_gw, _str_tmpl)
    end

    if _approved and #_approved > 0 then
        local _tmpl = _get_tmpl(rules, {nodes = _approved})
        local _str_stat = _tmpl("_node_stat_v1")

        mkdirp(_stat_dir .. "/etc/prometheus/stat_node/")
        local _file_stat = _stat_dir .. "/etc/prometheus/stat_node/" .. _blocknet_id .. ".yml"
        _print(_str_stat)
        _print(_file_stat)
        _write_file(_file_stat, _str_stat)
    end

    if _actives and #_actives > 0 then
        local _tmpl = _get_tmpl(rules, {nodes = _actives})
        local _str = _tmpl("_node_zones")
        local _file = _gwman_dir .. "/data/zones/" .. mytype .. "/" .. _blocknet_id .. ".zone"
        _print(_str)
        _print(_file)
        _write_file(_file, _str)
        -- local _tmpl = _get_tmpl(rules, {nodes = _actives})
        -- local _str_stat = _tmpl("_node_stat_v1")

        -- mkdirp(_stat_dir .. "/etc/prometheus/stat_node/")
        -- local _file_stat = _stat_dir .. "/etc/prometheus/stat_node/" .. _blocknet_id .. ".yml"
        -- _print(_str_stat)
        -- _print(_file_stat)
        -- _write_file(_file_stat, _str_stat)

        local _str_listid = _tmpl("_listids")
        mkdirp(_info_dir .. "/" .. mytype)
        local _file_listid = _info_dir .. "/" .. mytype .. "/listid-" .. _blocknet_id
        _print(_str_listid)
        _print(_file_listid)
        _write_file(_file_listid, _str_listid)
    end
end

local function _rescanconf()
    for _, _blockchain in ipairs(show_folder(_deploy_dir)) do
        local _blockchain_dir = _deploy_dir .. "/" .. _blockchain
        for _, _network in ipairs(show_folder(_blockchain_dir)) do
            _rescanconf_blockchain_network(_blockchain, _network)
        end
    end
end

local function _rescanconf1(instance, args)
    -- local _portal_commit_files = {}
    -- local _dns_commit_files = {}

    local _datacenter_ids_all = {}
    local _maps = {}
    for _, _blockchain in ipairs(show_folder(_deploy_dir)) do
        local _blockchain_dir = _deploy_dir .. "/" .. _blockchain
        for _, _network in ipairs(show_folder(_blockchain_dir)) do
            local _blk_id = _blockchain .. "-" .. _network
            _maps[_blk_id] =
                _maps[_blk_id] or
                {
                    maps = {},
                    datacenters = {},
                    datacenter_ids = {}
                }

            local _datacenter_ids = _maps[_blk_id].datacenter_ids

            local _network_dir = _blockchain_dir .. "/" .. _network
            for _, _continent in ipairs(show_folder(_network_dir)) do
                local _continent_dir = _network_dir .. "/" .. _continent
                if is_dir(_continent_dir) then
                    for _, _country in ipairs(show_folder(_continent_dir)) do
                        local _country_dir = _continent_dir .. "/" .. _country
                        if is_dir(_country_dir) then
                            for _, _user_id in ipairs(show_folder(_country_dir)) do
                                local _user_dir = _country_dir .. "/" .. _user_id
                                if is_dir(_user_dir) then
                                    for _, _id in ipairs(show_folder(_user_dir)) do
                                        _print("_gdnsd_file:" .. _id)
                                        if _id ~= ".gitkeep" then
                                            local _item = read_file(_user_dir .. "/" .. _id)

                                            _print("path:" .. _user_dir .. "/" .. _id)
                                            -- _print("item:" .. _item)
                                            if _item then
                                                if type(_item) == "string" then
                                                    _item = json.decode(_item)
                                                end

                                                if tonumber(_item.status) == 1 then
                                                    _item._is_enabled = true
                                                    if _item.approved and tonumber(_item.approved) == 1 then
                                                        _item._is_approved = true
                                                    end
                                                end

                                                table.insert(_datacenter_ids, _item)

                                                table.insert(_datacenter_ids_all, {id = _item.id, ip = _item.ip})
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    -- _print("maps:" .. inspect(_maps))
    for _k, _v in pairs(_maps) do
        do
            -- _print("k:" .. inspect(_k))
            -- _print("v:" .. inspect(_v))
            local _tmpl = _get_tmpl(rules, {node_type = _k, nodes = _v.datacenter_ids})
            local _str_tmpl = _tmpl("_gw_conf")

            local _file_gw = _deploy_gatewayconfdir .. "/" .. _k .. ".conf"
            _print(_file_gw)
            _write_file(_file_gw, _str_tmpl)
            -- table.insert(_portal_commit_files, _file_gw)
        end

        do
            local _tmpl = _get_tmpl(rules, {nodes = _v.datacenter_ids})
            local _str = _tmpl("_node_zones")
            local _file = _gwman_dir .. "/data/zones/" .. mytype .. "/" .. _k .. ".zone"
            _print(_file)
            _write_file(_file, _str)
            -- table.insert(_dns_commit_files, _file)
        end
    end

    local _zone_content = {}
    table.insert(_zone_content, read_file(_gwman_dir .. "/data/zones/massbitroute.com"))
    table.insert(_zone_content, read_dir(_gwman_dir .. "/data/zones/gateway"))
    table.insert(_zone_content, read_dir(_gwman_dir .. "/data/zones/node"))
    table.insert(_zone_content, read_dir(_gwman_dir .. "/data/zones/dapi"))

    local _zone_main = _gwman_dir .. "/zones/massbitroute.com"
    _print(_zone_main)
    _write_file(_zone_main, table.concat(_zone_content, "\n"))
    -- table.insert(_dns_commit_files, _zone_main)

    local _tmpl = _get_tmpl(rules, {nodes = _datacenter_ids_all})
    local _str_stat = _tmpl("_node_stat")

    local _file_stat = _stat_dir .. "/etc/prometheus/stat_node.yml"
    _write_file(_file_stat, _str_stat)
    -- _print(_file_stat)
    -- _git_push(
    --     _stat_dir,
    --     {
    --         _stat_dir .. "/etc/prometheus/stat_node.yml"
    --     }
    -- )

    -- _print(inspect(_portal_commit_files))
    -- _git_push(_portal_dir, _portal_commit_files)
    -- _print(inspect(_dns_commit_files))
    -- _git_push(_gwman_dir, _dns_commit_files)
end

local function _generate_item(instance, args)
    _print("generate_item:" .. inspect(args))
    local model = Model:new(instance)
    local _item1 = model:get(args)
    -- _print(inspect(_item1))
    local _item = _norm(_item1)

    -- _print(inspect(_item))
    if
        not _item or not _item.id or not _item.ip or not _item.blockchain or not _item.network or not _item.geo or
            not _item.geo.continent_code or
            not _item.geo.country_code
     then
        return nil, "invalid data"
    end

    local _item_path =
        table.concat(
        {
            _deploy_dir,
            _item.blockchain,
            _item.network,
            _item.geo.continent_code,
            _item.geo.country_code,
            _item.user_id
        },
        "/"
    )
    mkdirp(_item_path)
    local _deploy_file = _item_path .. "/" .. _item.id

    -- local _k1 = _k2 .. "/" .. _item.geo.continent_code .. "/" .. _item.geo.country_code
    -- mkdirp(_deploy_dir .. "/" .. _k1)
    -- local _deploy_file = _deploy_dir .. "/" .. _k1 .. "/" .. _item.id

    -- write data output for later inspector
    -- easy for other task follow
    -- _print(_deploy_file)
    _item._is_delete = nil
    args._is_delete = nil
    table.merge(_item, args)
    _write_file(_deploy_file, json.encode(_item))

    local _k2 = _item.blockchain .. "/" .. _item.network

    -- keep create dir blockchain/network
    local _deploy_file1 = _deploy_dir .. "/" .. _k2 .. "/.gitkeep"
    _write_file(_deploy_file1, "")

    local _tmpl = _get_tmpl(rules, _item)
    local _str_tmpl = _tmpl("_local")

    local _file_main = _deploy_nodeconfdir .. "/" .. _item.id .. ".conf"
    _print(_file_main)
    _write_file(_file_main, _str_tmpl)

    -- local _files = {
    --     _deploy_file,
    --     _deploy_file1,
    --     _deploy_nodeconfdir .. "/" .. _item.id .. ".conf"
    -- }
    -- _print("files:" .. inspect(_files))
    -- _git_push(_deploy_dir, _files)
    _rescanconf_blockchain_network(_item.blockchain, _item.network)
    return true
end

function JobsAction:generateconfAction(job)
    _print("generateconf:" .. inspect(job))

    local instance = self:getInstance()

    local job_data = job.data
    _generate_item(instance, job_data)
    -- _update_gdnsd(job_data)
end

function JobsAction:rescanconfAction(job)
    -- local instance = self:getInstance()
    -- local job_data = job.data
    _rescanconf()
end

function JobsAction:removeconfAction(job)
    _print("removeconf:" .. inspect(job))

    local instance = self:getInstance()
    local job_data = job.data
    _remove_item(instance, job_data)
    -- _update_gdnsd(job_data)
end

return JobsAction
