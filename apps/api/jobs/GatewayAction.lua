local cc = cc
local mytype = "gateway"
local gbc = cc.import("#gbc")
local json = cc.import("#json")

local JobsAction = cc.class(mytype .. "JobsAction", gbc.ActionBase)

local mbrutil = require "mbutil" --cc.import("#mbrutil")
local env = require("env")
-- local read_dir = mbrutil.read_dir
local read_file = mbrutil.read_file
local show_folder = mbrutil.show_folder
local inspect = mbrutil.inspect

-- local table_map = table.map
-- local table_walk = table.walk
-- local table_filter = table.filter
local table_insert = table.insert
local table_concat = table.concat
-- local table_keys = table.keys
local table_merge = table.merge

local _write_file = mbrutil.write_file
local _get_tmpl = mbrutil.get_template
-- local _git_push = mbrutil.git_push

local mkdirp = require "mkdirp"

JobsAction.ACCEPTED_REQUEST_TYPE = "worker"

local Model = cc.import("#" .. mytype)
local _domain_name = env.DOMAIN or "massbitroute.com"
local _service_dir = "/massbit/massbitroute/app/src/sites/services"
local _portal_dir = _service_dir .. "/api"
local _deploy_dir = _portal_dir .. "/public/deploy/gateway"
local _info_dir = _portal_dir .. "/public/deploy/info"

local gwman_dir = _service_dir .. "/gwman/data"
local stat_dir = _service_dir .. "/stat/etc/conf"

local _print = mbrutil.print
local rules = {
    _listid = [[${id} ${user_id} ${blockchain} ${network} ${ip} ${geo.continent_code} ${geo.country_code} ${token} ${status} ${approved}]],
    _listids = [[${nodes/_listid(); separator='\n'}]],
    -- _listids_not_actives = [[${not_actives/_listid(); separator='\n'}]],
    _dcmap_map = [[${id} =>  [ ${ip} , 10 ],]],
    _dcmap_v1 = [[
${geo_id} => {
  ${datacenters/_dcmap_map(); separator='\n'}
},
]],
    _dcmap = [[
${id} => {
  ${str}
},
]],
    _dns_geo_resource = [[
mbr-map-${id} =>{
  map => mbr-map-${id},
  plugin => weighted,
  dcmap => {
    ${dcmaps/_dcmap(); separator='\n'}
  }
}
]],
    _dns_geo_resource_v1 = [[
mbr-map-${blocknet_id} =>{
  map => mbr-map-${blocknet_id},
  service_types => gateway_check,
  plugin => weighted,
  dcmap => {
    ${dcmaps/_dcmap_v1(); separator='\n'}
}
}
]],
    _datacenter = [[${it}]],
    _dns_geo_map = [[
mbr-map-${id} =>{
  geoip2_db => GeoIP2-City.mmdb
  map => {
    ${map}
  },
  datacenters => [
    ${datacenters/_datacenter(); separator=',\n'}
  ]
}
]],
    _gw_zone = [[${id}.gw.mbr 3600 A ${ip}]],
    _gw_zones = [[${nodes/_gw_zone(); separator='\n'}]],
    _gw_stat_target = [[          - ${id}.gw.mbr.${_domain_name}]],
    _gw_stat_v1 = [[${nodes/_gw_stat_target(); separator='\n'}]],
    _gw_stat = [[
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
${nodes/_gw_stat_target(); separator='\n'}
]]
}

local function _norm(_v)
    -- print(inspect(_v))
    if type(_v) == "string" then
        _v = json.decode(_v)
    end

    return _v
end

--- Rescan gateway only for specific blockchain and network
-- using after update gateway
--
local function _rescanconf_blockchain_network(_blockchain, _network, _job_data)
    _print("rescanconf_blockchain_network:" .. _blockchain .. ":" .. _network)
    -- _print(inspect(_job_data))

    local _datacenters = {}
    local _allnodes = {}
    local _actives = {}
    -- local _not_actives = {}
    local _approved = {}

    local _blocknet_id = _blockchain .. "-" .. _network
    local _dc_global = {}

    local _dc_country = {}
    local _dc_continent = {}

    local _network_dir = _deploy_dir .. "/" .. _blockchain .. "/" .. _network
    -- _print("dir:" .. _network_dir)
    for _, _continent in ipairs(show_folder(_network_dir)) do
        local _continent_dir = _network_dir .. "/" .. _continent
        for _, _country in ipairs(show_folder(_continent_dir)) do
            local _geo_id = _blocknet_id .. "-" .. _continent .. "-" .. _country
            local _geo_country_default = _blocknet_id .. "-" .. _continent .. "-default"
            local _geo_continent_default = _blocknet_id .. "-default-default"

            local _country_dir = _continent_dir .. "/" .. _country
            for _, _user_id in ipairs(show_folder(_country_dir)) do
                local _user_dir = _country_dir .. "/" .. _user_id
                for _, _id in ipairs(show_folder(_user_dir)) do
                    local _file = _user_dir .. "/" .. _id
                    -- _print("file:" .. _file)
                    local _item = read_file(_file)
                    if _item then
                        if type(_item) == "string" then
                            _item = json.decode(_item)
                        end
                        _item._domain_name = _job_data._domain_name
                        -- local _ip = _item.ip
                        -- print("ip:" .. inspect(_ip))
                        local _obj = {
                            ip = _item.ip,
                            id = _item.id,
                            -- id_block = _item.blockchain .. "-" .. _item.network,
                            geo_id = _geo_id
                            --_blocknet_id .. "-" .. _item.geo.continent_code .. "-" .. _item.geo.country_code
                        }
                        -- _print({id = _item.id, status = _item.status}, true)
                        if _continent and _country and _item.status and _item.approved then
                            local _t =
                                _blocknet_id ..
                                "-" .. _continent .. "-" .. _country .. "-" .. _item.status .. "-" .. _item.approved
                            local _t1 =
                                _blocknet_id .. "-" .. _continent .. "-" .. _item.status .. "-" .. _item.approved
                            local _t2 = _blocknet_id .. "-" .. _item.status .. "-" .. _item.approved
                            _allnodes[_t] = _allnodes[_t] or {}
                            _allnodes[_t1] = _allnodes[_t1] or {}
                            _allnodes[_t2] = _allnodes[_t2] or {}
                            table.insert(_allnodes[_t], _item)
                            table.insert(_allnodes[_t1], _item)
                            table.insert(_allnodes[_t2], _item)
                        end

                        -- if _item.status and tonumber(_item.status) == 0 then
                        --     _not_actives[#_not_actives + 1] = _item
                        -- end

                        if _item.status and tonumber(_item.status) == 1 then
                            _item._is_enabled = true
                            _actives[#_actives + 1] = _item
                            if _item.approved and tonumber(_item.approved) == 1 then
                                _approved[#_approved + 1] = _item
                                _item._is_approved = true

                                _datacenters["geo"] = _datacenters["geo"] or {}
                                _datacenters["blocknet"] = _datacenters["blocknet"] or {}
                                local _dc_geo = _datacenters["geo"]
                                local _dc_block = _datacenters["blocknet"]
                                -- _datacenters["blocknet1"] = _datacenters["blocknet1"] or {}

                                _dc_global[_geo_id] = 1

                                _dc_continent[_continent] = _dc_continent[_continent] or {}
                                _dc_continent[_continent][_geo_id] = 1

                                _dc_country[_continent] = _dc_country[_continent] or {}

                                _dc_country[_continent][_country] = _dc_country[_continent][_country] or {}

                                _dc_country[_continent][_country][_geo_id] = 1

                                -- _dc_geo[_blocknet_id] = _dc_geo[_blocknet_id] or {}
                                -- _dc_block[_blocknet_id] = _dc_block[_blocknet_id] or {}
                                _dc_block[_continent] = _dc_block[_continent] or {}

                                _dc_block[_continent][_country] = _dc_block[_continent][_country] or {}

                                _dc_block[_continent]["default"] = _dc_block[_continent]["default"] or {}

                                _dc_block["default"] = _dc_block["default"] or {}
                                -- _dc_block1["default"] = _dc_block1["default"] or {}

                                _dc_block[_continent][_country] = _geo_id

                                table.insert(_dc_block[_continent]["default"], _geo_id)
                                table.insert(_dc_block["default"], _geo_id)

                                _dc_geo[_geo_id] = _dc_geo[_geo_id] or {}
                                _dc_geo[_geo_country_default] = _dc_geo[_geo_country_default] or {}
                                _dc_geo[_geo_continent_default] = _dc_geo[_geo_continent_default] or {}
                                table_insert(_dc_geo[_geo_id], _obj)
                                table_insert(_dc_geo[_geo_country_default], _obj)
                                table_insert(_dc_geo[_geo_continent_default], _obj)
                            end
                        end
                    end
                end
            end
        end
    end
    if _dc_country and next(_dc_country) then
        _print("dc_country:")
        _print(_dc_country, true)
        _print("dc_continent:")
        _print(_dc_continent, true)

        _print("dc_global:")
        _print(_dc_global, true)

        local _v_maps = {}
        table_insert(_v_maps, _blocknet_id .. " => { ")
        for _continent_code, _continents in pairs(_dc_country) do
            _print("_continent_code:" .. _continent_code)
            table_insert(_v_maps, "  " .. _continent_code .. " => { ")
            for _country_code, _countries in pairs(_continents) do
                _print("_country_code:" .. _country_code)

                local _dcs = table.keys(_countries)
                for _k, _ in pairs(_dc_continent[_continent_code]) do
                    if not _countries[_k] then
                        table.insert(_dcs, _k)
                        _countries[_k] = 1
                    end
                end
                for _k, _ in pairs(_dc_global) do
                    if not _countries[_k] then
                        table.insert(_dcs, _k)
                    end
                end
                _print("dcs")
                _print(_dcs, true)

                table_insert(_v_maps, "    " .. _country_code .. " => [ ")
                for _, _dc in ipairs(_dcs) do
                    table_insert(_v_maps, "        " .. _dc .. ",")
                end
                table_insert(_v_maps, "    ],")
            end
            local _country_code = "default"
            local _countries = _dc_continent[_continent_code]
            local _dcs = table.keys(_countries)
            for _k, _ in pairs(_dc_global) do
                if not _countries[_k] then
                    table.insert(_dcs, _k)
                end
            end
            table_insert(_v_maps, "    " .. _country_code .. " => [ ")
            for _, _dc in ipairs(_dcs) do
                table_insert(_v_maps, "        " .. _dc .. ",")
            end
            table_insert(_v_maps, "    ],")

            table_insert(_v_maps, "  },")
        end

        local _dc_global_keys = table.keys(_dc_global)
        table_insert(_v_maps, "  default => [ ")
        for _, _dc in ipairs(_dc_global_keys) do
            table_insert(_v_maps, "        " .. _dc .. ",")
        end
        table_insert(_v_maps, "  ],")
        _print("_v_maps:")
        _print(_v_maps, true)
        -- _print(table_concat(_v_maps, "\n"))
        local _tmpl_map =
            _get_tmpl(
            rules,
            {
                id = _blocknet_id,
                datacenters = _dc_global_keys,
                map = table_concat(_v_maps, "\n"),
                _domain_name = _job_data._domain_name
            }
        )
        local _geo_map = _tmpl_map("_dns_geo_map")
        print(_geo_map)
        local _file_map = gwman_dir .. "/conf.d/geolocation.d/maps.d/mbr-map-" .. _blocknet_id
        print(_file_map)
        _write_file(_file_map, _geo_map)
    end
    -- if _datacenters["blocknet"] and next(_datacenters["blocknet"]) ~= nil then
    --     local _geo_val = _datacenters["blocknet"]
    --     _print("blocknet:")
    --     _print(_geo_val, true)

    --     local _v_maps = {}
    --     local _v_datacenters = {}
    --     table_insert(_v_maps, _blocknet_id .. " => { ")

    --     for _k3, _v3 in pairs(_geo_val) do
    --         if _k3 ~= "default" then
    --             table_insert(_v_maps, _k3 .. " => { ")
    --             for _k4, _v4 in pairs(_v3) do
    --                 if _k4 and _k4 ~= "default" then
    --                     table_insert(_v_maps, "  " .. _k4 .. " => [ " .. _v4 .. "],")
    --                     _v_datacenters[_v4] = 1
    --                 else
    --                     _v_datacenters[_blocknet_id .. "-" .. _k3 .. "-" .. _k4] = 1
    --                     -- if _v4 then
    --                     --     table.insert(_v_datacenters, _v4)
    --                     -- end
    --                     local _cache = {}
    --                     table_insert(_v_maps, "  " .. _k4 .. " => [ ")
    --                     for _, _v5 in ipairs(_v4) do
    --                         if _v5 and not _cache[_v5] then
    --                             table_insert(_v_maps, "    " .. _v5 .. ",")
    --                             _cache[_v5] = 1
    --                             _v_datacenters[_v5] = 1
    --                         end
    --                     end
    --                     table_insert(_v_maps, "  ],")
    --                 end
    --             end
    --             table_insert(_v_maps, "},")
    --         else
    --             _v_datacenters[_blocknet_id .. "-" .. _k3 .. "-" .. _k3] = 1
    --             table_insert(_v_maps, "  " .. _k3 .. " => [ ")
    --             local _cache = {}
    --             for _, _v4 in ipairs(_v3) do
    --                 if _v4 and not _cache[_v4] then
    --                     table_insert(_v_maps, "    " .. _v4 .. ",")
    --                     _v_datacenters[_v4] = 1
    --                     _cache[_v4] = 1
    --                 end
    --             end
    --             table_insert(_v_maps, "  ],")
    --         end
    --     end

    --     table_insert(_v_maps, "}")
    --     _print("v_maps:" .. inspect(_v_maps))
    --     _print("v_datacenters:" .. inspect(_v_datacenters))
    --     local _tmpl_map =
    --         _get_tmpl(
    --         rules,
    --         {
    --             id = _blocknet_id,
    --             datacenters = table.keys(_v_datacenters),
    --             map = table_concat(_v_maps, "\n"),
    --             _domain_name = _job_data._domain_name
    --         }
    --     )
    --     local _geo_map = _tmpl_map("_dns_geo_map")
    --     print(_geo_map)
    --     local _file_map = gwman_dir .. "/conf.d/geolocation.d/maps.d/mbr-map-" .. _blocknet_id
    --     print(_file_map)
    --     _write_file(_file_map, _geo_map)
    -- end

    if _datacenters["geo"] and next(_datacenters["geo"]) ~= nil then
        local _geo_val = _datacenters["geo"]
        _print("geo:")
        _print(_geo_val, true)

        -- _print("_geo_val:" .. inspect(_geo_val))
        local _dc_maps_new = {}
        for _geo_id, _geo_svrs in pairs(_geo_val) do
            -- _print("_geo_id:" .. inspect(_geo_id))
            -- _print("_geo_svrs:" .. inspect(_geo_svrs))
            table.insert(
                _dc_maps_new,
                {
                    geo_id = _geo_id,
                    datacenters = _geo_svrs
                }
            )
        end

        -- _print("_dc_maps_new:" .. inspect(_dc_maps_new))

        local _tmpl_res =
            _get_tmpl(
            rules,
            {
                blocknet_id = _blocknet_id,
                dcmaps = _dc_maps_new,
                _domain_name = _job_data._domain_name
            }
        )
        local _geo_res = _tmpl_res("_dns_geo_resource_v1")
        -- _print(_geo_res)
        local _file_res = gwman_dir .. "/conf.d/geolocation.d/resources.d/mbr-map-" .. _blocknet_id
        -- _print(_file_res)
        _write_file(_file_res, _geo_res)

        local _file_dapi = gwman_dir .. "/zones/dapi/" .. _blocknet_id .. ".zone"
        print(_file_dapi)
        _write_file(_file_dapi, "*." .. _blocknet_id .. " 10/10 DYNA	geoip!mbr-map-" .. _blocknet_id .. "\n")
    end

    if _approved and #_approved > 0 then
        local _tmpl = _get_tmpl(rules, {nodes = _approved, _domain_name = _job_data._domain_name})
        local _str_stat = _tmpl("_gw_stat_v1")
        mkdirp(stat_dir .. "/stat_gw")
        local _file_stat = stat_dir .. "/stat_gw/" .. _blocknet_id .. ".yml"
        -- _print(_str_stat)
        -- _print(_file_stat)
        _write_file(_file_stat, _str_stat)
    end

    if _actives and #_actives > 0 then
        -- _print(_actives, true)
        local _tmpl = _get_tmpl(rules, {nodes = _actives, _domain_name = _job_data._domain_name})
        local _str = _tmpl("_gw_zones")
        -- _print(_str)
        local _file = gwman_dir .. "/zones/" .. mytype .. "/" .. _blocknet_id .. ".zone"
        -- _print(_file)
        _write_file(_file, _str)

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
    -- _print("stored_item:" .. inspect(_item))
    if args._is_delete then
        model:delete({id = args.id, user_id = args.user_id})
    end

    if
        not _item or not _item.id or not _item.ip or not _item.blockchain or not _item.network or not _item.geo or
            not _item.geo.continent_code or
            not _item.geo.country_code
     then
        return nil, "invalid data"
    end

    local _item_path =
        table_concat(
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
        _print("remove_file:" .. _deploy_file)
        os.remove(_deploy_file)
    else
        table_merge(_item, args)
        _item._is_delete = nil
        _write_file(_deploy_file, json.encode(_item))
    end
    _rescanconf_blockchain_network(_item.blockchain, _item.network, args)
    return true
end

--- Generate gateway conf
--
local function _generate_item(instance, args)
    local model = Model:new(instance)

    -- query db for detail
    local _item = _norm(model:get(args))

    if
        not _item or not _item.id or not _item.ip or not _item.blockchain or not _item.network or not _item.geo or
            not _item.geo.continent_code or
            not _item.geo.country_code
     then
        return nil, "invalid data"
    end

    -- detail dump path
    local _item_path =
        table_concat(
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
    -- make sure directory created
    mkdirp(_item_path)

    local _deploy_file = _item_path .. "/" .. _item.id
    table_merge(_item, args)

    -- remove unused props
    _item._is_delete = nil

    -- dump detail
    _write_file(_deploy_file, json.encode(_item))

    _rescanconf_blockchain_network(_item.blockchain, _item.network, args)
    return true
end

--- Job handler for rescan conf
-- Scan all files and update status
--

function JobsAction:rescanconfAction(job)
    -- local instance = self:getInstance()
    local job_data = job.data
    job_data._domain_name = _domain_name
    _rescanconf(job_data)
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

return JobsAction
