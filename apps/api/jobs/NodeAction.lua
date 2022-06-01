local cc = cc
local gbc = cc.import("#gbc")
local json = cc.import("#json")

local mytype = "node"
local JobsAction = cc.class(mytype .. "JobsAction", gbc.ActionBase)

local mbrutil = require "mbutil" -- cc.import("#mbrutil")
local env = require("env")
-- local read_dir = mbrutil.read_dir
local read_file = mbrutil.read_file
local show_folder = mbrutil.show_folder
local inspect = mbrutil.inspect

-- local shell = require "shell-games"
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
local _domain_name = env.DOMAIN or "massbitroute.com"
local mkdirp = require "mkdirp"
local _gwman_dir = _service_dir .. "/gwman/data"
local _stat_dir = _service_dir .. "/stat/etc/conf"

local rules = {
    _listid = [[${id} ${user_id} ${blockchain} ${network} ${ip} ${geo.continent_code} ${geo.country_code} ${token} ${status} ${approved}]],
    _listids = [[${nodes/_listid(); separator='\n'}]],
    _listids_not_actives = [[${not_actives/_listid(); separator='\n'}]],
    _node_zone = [[${id}.node.mbr 3600 A ${ip}]],
    _node_zones = [[${nodes/_node_zone(); separator='\n'}]],
    _node_stat_target = [[          - ${id}.node.mbr.${_domain_name}]],
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
    _gw_node_upstream_ws = [[
server unix:/tmp/${id}-ws.sock max_fails=1 fail_timeout=3s;
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
    _gw_node_upstreams_v1 = [[
 ${upstream_extra}
upstream ${node_type}.node.mbr.${_domain_name} {
  ${nodes/_gw_node_upstream()}
  ${upstream_backup}
    include /massbit/massbitroute/app/src/sites/services/gateway/etc/_upstream_server.conf;
}
server {
    listen unix:/tmp/${node_type}.node.mbr.${_domain_name}.sock;
    location / {
        proxy_pass http://${node_type}.node.mbr.${_domain_name};

  include /massbit/massbitroute/app/src/sites/services/gateway/etc/_provider_server.conf;
    }
}
 ${upstream_extra_ws}
upstream ws-${node_type}.node.mbr.${_domain_name} {
  ${nodes/_gw_node_upstream_ws()}
  ${upstream_backup_ws}
    include /massbit/massbitroute/app/src/sites/services/gateway/etc/_upstream_server_ws.conf;

}
server {
    listen unix:/tmp/ws-${node_type}-ws.node.mbr.${_domain_name}.sock;
    location / {
        proxy_pass http://ws-${node_type}.node.mbr.${_domain_name};

  include /massbit/massbitroute/app/src/sites/services/gateway/etc/_provider_server_ws.conf;
    }
}
upstream ${node_type}-ws.node.mbr.${_domain_name} {
  ${nodes/_gw_node_upstream_ws()}
  ${upstream_backup_ws}
    include /massbit/massbitroute/app/src/sites/services/gateway/etc/_upstream_server_ws.conf;

}
server {
    listen unix:/tmp/${node_type}-ws.node.mbr.${_domain_name}.sock;
    location / {
        proxy_pass http://${node_type}-ws.node.mbr.${_domain_name};

  include /massbit/massbitroute/app/src/sites/services/gateway/etc/_provider_server_ws.conf;
    }
}
]],
    ["_gw_upstream_backup_name_dot-mainnet"] = [[ unix:/tmp/dot-mainnet-getblock-1.sock ]],
    ["_gw_upstream_backup_name_ws_dot-mainnet"] = [[ unix:/tmp/dot-mainnet-getblock-ws-1.sock ]],
    ["_gw_upstream_backup_dot-mainnet"] = [[
server {
    listen unix:/tmp/dot-mainnet-getblock-1.sock;
    location / {
        add_header X-Mbr-Node-Id dot-mainnet-getblock-1;
        proxy_set_header X-Api-Key 6c4ddad0-7646-403e-9c10-744f91d37ccf;
        proxy_pass https://dot.getblock.io/mainnet/;

  include /massbit/massbitroute/app/src/sites/services/gateway/etc/_provider_server.conf;
    }
}
 ]],
    ["_gw_upstream_backup_ws_dot-mainnet"] = [[
server {
    listen unix:/tmp/dot-mainnet-getblock-ws-1.sock;
    location / {
        add_header X-Mbr-Node-Id dot-mainnet-getblock-1;
        proxy_set_header X-Api-Key 6c4ddad0-7646-403e-9c10-744f91d37ccf;
        proxy_pass https://dot.getblock.io/mainnet/;

  include /massbit/massbitroute/app/src/sites/services/gateway/etc/_provider_server_ws.conf;
    }
}
 ]],
    ["_gw_upstream_backup_name_eth-mainnet"] = [[ unix:/tmp/eth-mainnet-getblock-1.sock ]],
    ["_gw_upstream_backup_name_ws_eth-mainnet"] = [[ unix:/tmp/eth-mainnet-getblock-ws-1.sock ]],
    ["_gw_upstream_backup_eth-mainnet"] = [[
server {
    listen unix:/tmp/eth-mainnet-getblock-1.sock;
    location / {
        add_header X-Mbr-Node-Id eth-mainnet-getblock-1;
        proxy_set_header X-Api-Key 6c4ddad0-7646-403e-9c10-744f91d37ccf;
        proxy_pass https://eth.getblock.io/mainnet/;
  include /massbit/massbitroute/app/src/sites/services/gateway/etc/_provider_server.conf;
    }
}
]],
    ["_gw_upstream_backup_ws_eth-mainnet"] = [[
server {
    listen unix:/tmp/eth-mainnet-getblock-ws-1.sock;
    location / {
        add_header X-Mbr-Node-Id eth-mainnet-getblock-1;
        proxy_set_header X-Api-Key 6c4ddad0-7646-403e-9c10-744f91d37ccf;
        proxy_pass https://eth.getblock.io/mainnet/;
  include /massbit/massbitroute/app/src/sites/services/gateway/etc/_provider_server_ws.conf;
    }
}
]],
    _gw_node_upstreams = [[

upstream ${node_type}.node.mbr.${_domain_name} {
  ${nodes/_gw_node_upstream()}
  ${upstream_backup}
  include /massbit/massbitroute/app/src/sites/services/gateway/etc/_upstream_server.conf;
}
]],
    _gw_node = [[
server {
    listen unix:/tmp/${id}-ws.sock;
    location / {
        proxy_set_header X-Api-Key ${token};
        proxy_set_header Host ${id}-ws.node.mbr.${_domain_name};
        proxy_pass https://${ip};

  include /massbit/massbitroute/app/src/sites/services/gateway/etc/_provider_server_ws.conf;
    }
}
server {
    listen unix:/tmp/${id}.sock;
    location / {
        proxy_set_header X-Api-Key ${token};
        proxy_set_header Host ${id}.node.mbr.${_domain_name};
        proxy_pass https://${ip};

  include /massbit/massbitroute/app/src/sites/services/gateway/etc/_provider_server.conf;
    }
}
]],
    _gw_nodes = [[
${nodes/_gw_node()}
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
    include /massbit/massbitroute/app/src/sites/services/node/etc/_pre_server_ws.conf;
    include /massbit/massbitroute/app/src/sites/services/node/etc/_ssl_node.mbr.${_domain_name}.conf;
    server_name ${id}-ws.node.mbr.${_domain_name};
    location / {
        add_header X-Mbr-Node-Id ${id};
        vhost_traffic_status_filter_by_set_key $api_method user::${user_id}::node::${id}::v1::api_method;
        proxy_pass ${data_ws};
        include /massbit/massbitroute/app/src/sites/services/node/etc/_node_server_ws.conf;
    }
    location /__internal_status_vhost/ {
        include /massbit/massbitroute/app/src/sites/services/node/etc/_vts_server_ws.conf;
    }
    include /massbit/massbitroute/app/src/sites/services/node/etc/_location_server_ws.conf;
}

server {
    include /massbit/massbitroute/app/src/sites/services/node/etc/_pre_server.conf;
    include /massbit/massbitroute/app/src/sites/services/node/etc/_ssl_node.mbr.${_domain_name}.conf;
    server_name ${id}.node.mbr.${_domain_name};
    location / {
        add_header X-Mbr-Node-Id ${id};
        vhost_traffic_status_filter_by_set_key $api_method user::${user_id}::node::${id}::v1::api_method;
        proxy_pass ${data_url};
        include /massbit/massbitroute/app/src/sites/services/node/etc/_node_server.conf;
    }
    location /__internal_status_vhost/ {
        include /massbit/massbitroute/app/src/sites/services/node/etc/_vts_server.conf;
    }
    include /massbit/massbitroute/app/src/sites/services/node/etc/_location_server.conf;
}
]],
    _upstream_server = [[server unix:/tmp/${id}.sock max_fails=1 fail_timeout=3s;]],
    _upstream = [[
upstream eth-mainnet.node.mbr.${_domain_name} {
${_upstream_server}
  include /massbit/massbitroute/app/src/sites/services/gateway/etc/_upstream_server.conf;
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
        proxy_set_header X-Api-Key ${token};
        proxy_set_header Host ${id}.node.mbr.${_domain_name};
        proxy_pass https://${ip};

        include /massbit/massbitroute/app/src/sites/services/gateway/etc/_provider_server.conf;
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

local function _gen_upstream_block(
    _prefix,
    _name,
    _nodes,
    _job_data,
    _upstream_backup,
    _upstream_backup_ws,
    _upstream_extra,
    _upstream_extra_ws)
    local _backup = ";"
    if #_nodes > 0 then
        _backup = " backup;"
    end

    if not _upstream_extra then
        _upstream_extra = ""
    end

    if not _upstream_extra_ws then
        _upstream_extra_ws = ""
    end

    if not _upstream_backup then
        _upstream_backup =
            "server unix:/tmp/" .. _prefix .. ".node.mbr." .. _job_data._domain_name .. ".sock " .. _backup
    end
    if not _upstream_backup_ws then
        _upstream_backup_ws =
            "server unix:/tmp/" .. _prefix .. ".node.mbr." .. _job_data._domain_name .. "-ws.sock " .. _backup
    end
    local _tmpl =
        _get_tmpl(
        rules,
        {
            node_type = _prefix .. _name,
            nodes = _nodes,
            _domain_name = _job_data._domain_name,
            upstream_backup = _upstream_backup,
            upstream_backup_ws = _upstream_backup_ws,
            upstream_extra = _upstream_extra,
            upstream_extra_ws = _upstream_extra_ws
        }
    )

    return _tmpl("_gw_node_upstreams_v1")
end

local function _rescanconf_blockchain_network(_blockchain, _network, _job_data)
    _print("rescanconf_blockchain_network:" .. _blockchain .. ":" .. _network)
    -- _print(inspect(_job_data))
    local _allnodes = {}
    local _nodes = {}
    local _nodes1 = {}
    local _nodes2 = {}
    local _datacenters = {}
    local _actives = {}
    -- local _not_actives = {}
    local _approved = {}
    local _blocknet_id = _blockchain .. "-" .. _network
    local _network_dir = _deploy_dir .. "/" .. _blockchain .. "/" .. _network
    for _, _continent in ipairs(show_folder(_network_dir)) do
        -- _print("continent:" .. _continent)
        local _continent_dir = _network_dir .. "/" .. _continent
        if is_dir(_continent_dir) then
            for _, _country in ipairs(show_folder(_continent_dir)) do
                -- _print("country:" .. _country)
                local _country_dir = _continent_dir .. "/" .. _country
                if is_dir(_country_dir) then
                    for _, _user_id in ipairs(show_folder(_country_dir)) do
                        local _user_dir = _country_dir .. "/" .. _user_id
                        if is_dir(_user_dir) then
                            for _, _id in ipairs(show_folder(_user_dir)) do
                                -- _print("_file:" .. _id)
                                if _id ~= ".gitkeep" then
                                    local _item = read_file(_user_dir .. "/" .. _id)

                                    -- _print("path:" .. _user_dir .. "/" .. _id)
                                    -- _print("item:" .. _item)
                                    if _item then
                                        if type(_item) == "string" then
                                            _item = json.decode(_item)
                                        end
                                        _item._domain_name = _job_data._domain_name
                                        -- if _item.status and tonumber(_item.status) == 0 then
                                        --     _not_actives[#_not_actives + 1] = _item
                                        -- end

                                        if _continent and _country and _item.status and _item.approved then
                                            local _t =
                                                _blocknet_id ..
                                                "-" ..
                                                    _continent ..
                                                        "-" .. _country .. "-" .. _item.status .. "-" .. _item.approved
                                            local _t1 =
                                                _blocknet_id ..
                                                "-" .. _continent .. "-" .. _item.status .. "-" .. _item.approved
                                            local _t2 = _blocknet_id .. "-" .. _item.status .. "-" .. _item.approved
                                            _allnodes[_t] = _allnodes[_t] or {}
                                            _allnodes[_t1] = _allnodes[_t1] or {}
                                            _allnodes[_t2] = _allnodes[_t2] or {}
                                            table.insert(_allnodes[_t], _item)
                                            table.insert(_allnodes[_t1], _item)
                                            table.insert(_allnodes[_t2], _item)
                                        end

                                        if _item.status and tonumber(_item.status) == 1 then
                                            _item._is_enabled = true
                                            _actives[#_actives + 1] = _item
                                            if _item.approved and tonumber(_item.approved) == 1 then
                                                _approved[#_approved + 1] = _item
                                                _item._is_approved = true
                                                table.insert(_datacenters, _item)
                                                local _blocknet_continent = _item.geo.continent_code
                                                local _blocknet_country = _item.geo.country_code
                                                _nodes[_blocknet_id] = _nodes[_blocknet_id] or {}
                                                _nodes1[_blocknet_id] = _nodes1[_blocknet_id] or {}
                                                _nodes2[_blocknet_id] = _nodes2[_blocknet_id] or {}

                                                _nodes1[_blocknet_id][_blocknet_continent] =
                                                    _nodes1[_blocknet_id][_blocknet_continent] or {}

                                                _nodes2[_blocknet_id][_blocknet_continent] =
                                                    _nodes2[_blocknet_id][_blocknet_continent] or {}

                                                _nodes2[_blocknet_id][_blocknet_continent][_blocknet_country] =
                                                    _nodes2[_blocknet_id][_blocknet_continent][_blocknet_country] or {}
                                                table.insert(_nodes[_blocknet_id], _item)
                                                table.insert(_nodes1[_blocknet_id][_blocknet_continent], _item)
                                                table.insert(
                                                    _nodes2[_blocknet_id][_blocknet_continent][_blocknet_country],
                                                    _item
                                                )
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

    do
        local _tmpl =
            _get_tmpl(
            rules,
            {
                node_type = _blocknet_id,
                nodes = _nodes[_blocknet_id],
                _domain_name = _job_data._domain_name
            }
        )

        local _str_tmpl = _tmpl("_gw_nodes")
        -- _print(_str_tmpl)
        local _file_gw = _deploy_gatewayconfdir .. "/" .. _blocknet_id .. "-nodes.conf"
        -- _print(_file_gw)
        _write_file(_file_gw, _str_tmpl)
    end

    local _upstream_str = {}
    if next(_nodes2) == nil then
        local _k1 = _blocknet_id
        local _backup = ";"
        -- if #_nodes[_k1] > 0 then
        --     _backup = " backup;"
        -- end

        local _tmpl1 =
            _get_tmpl(
            rules,
            {
                node_type = _k1,
                nodes = {},
                _domain_name = _job_data._domain_name,
                upstream_backup = rules["_gw_upstream_backup_name_" .. _k1] and
                    "server " .. rules["_gw_upstream_backup_name_" .. _k1] .. _backup or
                    "",
                upstream_backup_ws = rules["_gw_upstream_backup_name_ws_" .. _k1] and
                    "server " .. rules["_gw_upstream_backup_name_ws_" .. _k1] .. _backup or
                    "",
                upstream_extra = rules["_gw_upstream_backup_" .. _k1] and rules["_gw_upstream_backup_" .. _k1] or "",
                upstream_extra_ws = rules["_gw_upstream_backup_ws_" .. _k1] and rules["_gw_upstream_backup_ws_" .. _k1] or
                    ""
            }
        )

        local _str_tmpl1 = _tmpl1("_gw_node_upstreams_v1")
        table.insert(_upstream_str, _str_tmpl1)
    else
        for _k1, _v1 in pairs(_nodes2) do
            local _backup = ";"
            if #_nodes[_k1] > 0 then
                _backup = " backup;"
            end
            table.insert(
                _upstream_str,
                _gen_upstream_block(
                    "",
                    _k1,
                    _nodes[_k1],
                    _job_data,
                    rules["_gw_upstream_backup_name_" .. _k1] and
                        "server " .. rules["_gw_upstream_backup_name_" .. _k1] .. _backup or
                        "",
                    rules["_gw_upstream_backup_name_ws_" .. _k1] and
                        "server " .. rules["_gw_upstream_backup_name_ws_" .. _k1] .. _backup or
                        "",
                    rules["_gw_upstream_backup_" .. _k1],
                    rules["_gw_upstream_backup_ws_" .. _k1]
                )
            )
            -- local _backup = ";"
            -- if #_nodes[_k1] > 0 then
            --     _backup = " backup;"
            -- end

            -- local _tmpl1 =
            --     _get_tmpl(
            --     rules,
            --     {
            --         node_type = _k1,
            --         nodes = _nodes[_k1],
            --         _domain_name = _job_data._domain_name,
            --         upstream_backup = "server " .. rules["_gw_upstream_backup_name_" .. _k1] .. _backup,
            --         upstream_extra = rules["_gw_upstream_backup_" .. _k1]
            --     }
            -- )

            -- local _str_tmpl1 = _tmpl1("_gw_node_upstreams_v1")
            -- table.insert(_upstream_str, _str_tmpl1)
            for _k2, _v2 in pairs(_v1) do
                table.insert(_upstream_str, _gen_upstream_block(_k1, "-" .. _k2, _nodes1[_k1][_k2], _job_data))
                -- local _backup2 = ";"
                -- if #_nodes1[_k1][_k2] > 0 then
                --     _backup2 = " backup;"
                -- end
                -- local _tmpl2 =
                --     _get_tmpl(
                --     rules,
                --     {
                --         node_type = _k1 .. "-" .. _k2,
                --         nodes = _nodes1[_k1][_k2],
                --         _domain_name = _job_data._domain_name,
                --         upstream_backup = "server unix:/tmp/" ..
                --             _k1 .. ".node.mbr." .. _job_data._domain_name .. _backup2
                --     }
                -- )

                -- local _str_tmpl2 = _tmpl2("_gw_node_upstreams_v1")
                -- table.insert(_upstream_str, _str_tmpl2)

                for _k3, _v3 in pairs(_v2) do
                    local _ids_country = {}
                    for _, _vi in ipairs(_v3) do
                        _ids_country[_vi.id] = 1
                    end

                    local _ids_continent = {}
                    local _nodes_continent = {}
                    for _, _vi in ipairs(_nodes1[_k1][_k2]) do
                        _ids_continent[_vi.id] = 1
                        if not _ids_country[_vi.id] then
                            _nodes_continent[#_nodes_continent + 1] = _vi
                        end
                    end

                    local _nodes_global = {}
                    for _, _vi in ipairs(_nodes[_k1]) do
                        if not _ids_continent[_vi.id] then
                            _nodes_global[#_nodes_global + 1] = _vi
                        end
                    end

                    local _block_name = _k1 .. "-" .. _k2 .. "-" .. _k3
                    -- _print("nodes_continent:" .. inspect(_nodes_continent))
                    -- _print("nodes_global:" .. inspect(_nodes_global))

                    local _backup_global = ";"
                    if #_nodes_global > 0 then
                        _backup_global = " backup;"
                    end

                    table.insert(
                        _upstream_str,
                        _gen_upstream_block(
                            "",
                            _block_name .. "-v1",
                            _nodes_global,
                            _job_data,
                            rules["_gw_upstream_backup_name_" .. _k1] and
                                "server " .. rules["_gw_upstream_backup_name_" .. _k1] .. _backup_global or
                                "",
                            rules["_gw_upstream_backup_name_ws_" .. _k1] and
                                "server " .. rules["_gw_upstream_backup_name_ws_" .. _k1] .. _backup_global or
                                ""
                            -- ,
                            -- rules["_gw_upstream_backup_" .. _k1]
                        )
                    )

                    table.insert(
                        _upstream_str,
                        _gen_upstream_block(_block_name .. "-v1", "-v2", _nodes_continent, _job_data)
                    )

                    local _backup_country = ";"
                    if #_v3 > 0 then
                        _backup_country = " backup;"
                    end
                    table.insert(
                        _upstream_str,
                        _gen_upstream_block(
                            _k1 .. "-" .. _k2,
                            "-" .. _k3,
                            _v3,
                            _job_data,
                            "server unix:/tmp/" ..
                                _block_name ..
                                    "-v1-v2.node.mbr." .. _job_data._domain_name .. ".sock " .. _backup_country,
                            "server unix:/tmp/" ..
                                _block_name ..
                                    "-v1-v2-ws.node.mbr." .. _job_data._domain_name .. ".sock " .. _backup_country
                        )
                    )
                    -- table.insert(_upstream_str, _gen_upstream_block(_k1 .. "-" .. _k2, "-" .. _k3, _v3, _job_data))
                end
            end
        end
    end
    -- _print("upstream_str:" .. table.concat(_upstream_str, "\n"))

    local _file_gw = _deploy_gatewayconfdir .. "/" .. _blocknet_id .. "-upstreams.conf"
    local _str_tmpl = table.concat(_upstream_str, "\n")
    -- _print(_file_gw)
    _write_file(_file_gw, _str_tmpl)

    if _approved and #_approved > 0 then
        local _tmpl = _get_tmpl(rules, {nodes = _approved, _domain_name = _job_data._domain_name})
        local _str_stat = _tmpl("_node_stat_v1")

        mkdirp(_stat_dir .. "/stat_node")
        local _file_stat = _stat_dir .. "/stat_node/" .. _blocknet_id .. ".yml"
        -- _print(_str_stat)
        -- _print(_file_stat)
        _write_file(_file_stat, _str_stat)
    end

    if _allnodes and next(_allnodes) then
        for _t, _v in pairs(_allnodes) do
            local _tmpl = _get_tmpl(rules, {nodes = _v, _domain_name = _job_data._domain_name})
            local _str_listid = _tmpl("_listids")
            mkdirp(_info_dir .. "/" .. mytype)
            local _file_listid = _info_dir .. "/" .. mytype .. "/listid-" .. _t
            -- _print(_str_listid)
            -- _print(_file_listid)
            _write_file(_file_listid, _str_listid)
        end
    end

    if _actives and #_actives > 0 then
        local _tmpl = _get_tmpl(rules, {nodes = _actives, _domain_name = _job_data._domain_name})
        local _str = _tmpl("_node_zones")
        local _file = _gwman_dir .. "/zones/" .. mytype .. "/" .. _blocknet_id .. ".zone"
        -- _print(_str)
        -- _print(_file)
        _write_file(_file, _str)
        -- local _tmpl = _get_tmpl(rules, {nodes = _actives})
        local _str_listid = _tmpl("_listids")
        mkdirp(_info_dir .. "/" .. mytype)
        local _file_listid = _info_dir .. "/" .. mytype .. "/listid-" .. _blocknet_id
        -- _print(_str_listid)
        -- _print(_file_listid)
        _write_file(_file_listid, _str_listid)

    -- local _str_listid_not_actives = _tmpl("_listids_not_actives")
    -- local _file_listid_not_actives = _info_dir .. "/" .. mytype .. "/listid-not-active-" .. _blocknet_id
    -- _print(_str_listid_not_actives)
    -- _print(_file_listid_not_actives)
    -- _write_file(_file_listid_not_actives, _str_listid_not_actives)
    end
end

local function _rescanconf(_job_data)
    _print("rescanconf:" .. inspect(_job_data))
    for _, _blockchain in ipairs(show_folder(_deploy_dir)) do
        local _blockchain_dir = _deploy_dir .. "/" .. _blockchain
        for _, _network in ipairs(show_folder(_blockchain_dir)) do
            _rescanconf_blockchain_network(_blockchain, _network, _job_data)
        end
    end
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
    local _deploy_conf_file = _deploy_nodeconfdir .. "/" .. _item.id .. ".conf"
    if args._is_delete then
        _print("remove file:" .. _deploy_file)

        os.remove(_deploy_file)

        _print("remove conf file:" .. _deploy_conf_file)
        os.remove(_deploy_conf_file)
    else
        table.merge(_item, args)
        _item._is_delete = nil
        _write_file(_deploy_file, json.encode(_item))
    end

    _rescanconf_blockchain_network(_item.blockchain, _item.network, args)

    return true
end

local function _generate_item(instance, args)
    _print("generate_item:" .. inspect(args))
    local model = Model:new(instance)
    local _item1 = model:get(args)
    _print("stored item: " .. inspect(_item1))
    local _item = _norm(_item1)
    if _item and not _item.data_ws or type(_item.data_ws) ~= "string" or _item.data_ws == "null" then
        _item.data_ws = _item.data_url
    end

    if _item and _item.data_ws and type(_item.data_ws) == "string" then
        _item.data_ws = _item.data_ws:gsub("ws:", "http:"):gsub("wss:", "https:")
    end
    if args and args.data_ws and type(args.data_ws) == "string" then
        args.data_ws = args.data_ws:gsub("ws:", "http:"):gsub("wss:", "https:")
    end

    if
        not _item or not _item.id or not _item.ip or not _item.blockchain or not _item.network or not _item.geo or
            not _item.geo.continent_code or
            not _item.geo.country_code
     then
        return nil, "invalid data"
    end

    local _old_file =
        table.concat(
        {
            _deploy_dir,
            "*",
            "*",
            "*",
            "*",
            "*",
            _item.id
        },
        "/"
    )
    local _cmd = "/usr/bin/rm " .. _old_file

    local handle = io.popen(_cmd)
    local _res = handle:read("*a")
    handle:close()

    -- local _res = shell.run(_cmd)
    _print("rm old:" .. _old_file .. ":" .. inspect(_res))

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

    _item._is_delete = nil
    args._is_delete = nil
    table.merge(_item, args)
    _print("item:" .. inspect(_item))
    _write_file(_deploy_file, json.encode(_item))

    local _k2 = _item.blockchain .. "/" .. _item.network

    -- keep create dir blockchain/network
    local _deploy_file1 = _deploy_dir .. "/" .. _k2 .. "/.gitkeep"
    _write_file(_deploy_file1, "")
    _item._domain_name = args._domain_name
    local _tmpl = _get_tmpl(rules, _item)

    local _str_tmpl = _tmpl("_local")

    local _file_main = _deploy_nodeconfdir .. "/" .. _item.id .. ".conf"

    -- _print(_file_main)
    _write_file(_file_main, _str_tmpl)

    _rescanconf_blockchain_network(_item.blockchain, _item.network, args)
    return true
end

function JobsAction:generateconfAction(job)
    _print("generateconf:" .. inspect(job))

    local instance = self:getInstance()

    local job_data = job.data or {}
    job_data._domain_name = _domain_name
    _print("job_data: " .. inspect(job_data))
    _generate_item(instance, job_data)
    -- _update_gdnsd(job_data)
end

function JobsAction:rescanconfAction(job)
    -- local instance = self:getInstance()
    local job_data = job.data or {}
    job_data._domain_name = _domain_name
    _rescanconf(job_data)
end

function JobsAction:removeconfAction(job)
    _print("removeconf:" .. inspect(job))

    local instance = self:getInstance()
    -- local _config = self:getInstanceConfig()
    local job_data = job.data or {}
    job_data._domain_name = _domain_name
    _remove_item(instance, job_data)
    -- _update_gdnsd(job_data)
end

return JobsAction
