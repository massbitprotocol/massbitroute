local cc = cc
local mytype = "gateway"
local gbc = cc.import("#gbc")
local json = cc.import("#json")

local JobsAction = cc.class(mytype .. "JobsAction", gbc.ActionBase)

local mbrutil = require "mbutil" --cc.import("#mbrutil")
local env = require("env")

local read_file = mbrutil.read_file
local show_folder = mbrutil.show_folder
local inspect = mbrutil.inspect

local table_insert = table.insert
local table_concat = table.concat
local table_keys = table.keys

local table_merge = table.merge

local _write_file = mbrutil.write_file
local _get_tmpl = mbrutil.get_template

local mkdirp = require "mkdirp"

JobsAction.ACCEPTED_REQUEST_TYPE = "worker"

local Model = cc.import("#" .. mytype)
local _domain_name = env.DOMAIN or "massbitroute.com"
local _service_dir = "/massbit/massbitroute/app/src/sites/services"
local _portal_dir = _service_dir .. "/api"
local _deploy_dir = _portal_dir .. "/public/deploy/gateway"
local _info_dir = _portal_dir .. "/public/deploy/info"

local gwman_dir = _service_dir .. "/gwman/data"
-- local stat_dir = _service_dir .. "/stat/etc/conf"

local _print = mbrutil.print
local rules = {
    _listid = [[${id} ${user_id} ${blockchain} ${network} ${ip} ${geo.continent_code} ${geo.country_code} ${token} ${status} ${approved} ${updated_at}]],
    _listids = [[${nodes/_listid(); separator='\n'}]],
    -- _listids_not_actives = [[${not_actives/_listid(); separator='\n'}]],
    _dcmap_map = [[${id} =>  [ ${ip} , ${weighted} ],]],
    _dcmap_maps = [[
  ${datacenters/_dcmap_map(); separator='\n'}
]],
    _dcmap_v2 = [[
${geo_id} => {$include{../dcmap/${geo_id}}},
]],
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
    ${dcmaps/_dcmap_v2(); separator='\n'}
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
    _print(inspect(_job_data))

    local _datacenters = {}
    local _allnodes = {}
    local _actives = {}
    -- local _not_actives = {}
    local _approved = {}

    local _blocknet_id = _blockchain .. "-" .. _network
    local _dc_global = {}
    local _dc_global1 = {}

    local _dc_country = {}
    local _dc_continent = {}
    local _dc_geo = {}
    local _dc_geo1 = {}
    local _dc_geo2 = {}
    local _dc_geo_domain = {}

    local _network_dir = _deploy_dir .. "/" .. _blockchain .. "/" .. _network

    for _, _continent in ipairs(show_folder(_network_dir)) do
        local _continent_dir = _network_dir .. "/" .. _continent
        for _, _country in ipairs(show_folder(_continent_dir)) do
            local _geo_id = _blocknet_id .. "-" .. _continent .. "-" .. _country
            local _geo_continent = _blocknet_id .. "-" .. _continent

            local _country_dir = _continent_dir .. "/" .. _country
            for _, _user_id in ipairs(show_folder(_country_dir)) do
                local _user_dir = _country_dir .. "/" .. _user_id
                for _, _id in ipairs(show_folder(_user_dir)) do
                    local _file = _user_dir .. "/" .. _id
                    _print("file:" .. _file)
                    local _item = read_file(_file)
                    if _item then
                        if type(_item) == "string" then
                            _item = json.decode(_item)
                        end
                    end
                    _print(_item, true)
                    if _item then
                        _item._domain_name = _job_data._domain_name

                        local _obj = {
                            ip = _item.ip,
                            id = _item.id,
                            geo_id = _geo_id,
                            weighted = 1000000
                        }

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

                        if _item.status and tonumber(_item.status) == 1 then
                            _item._is_enabled = true
                            _actives[#_actives + 1] = _item
                            if _item.approved and tonumber(_item.approved) == 1 then
                                _approved[#_approved + 1] = _item
                                _item._is_approved = true

                                _datacenters["geo"] = _datacenters["geo"] or {}
                                _datacenters["blocknet"] = _datacenters["blocknet"] or {}

                                _dc_continent[_continent] = _dc_continent[_continent] or {}
                                _dc_continent[_continent][_geo_id] = 1

                                _dc_country[_continent] = _dc_country[_continent] or {}

                                _dc_country[_continent][_country] = _dc_country[_continent][_country] or {}

                                _dc_country[_continent][_country][_geo_id] = 1

                                _dc_geo[_blocknet_id] = _dc_geo[_blocknet_id] or {}
                                _dc_geo[_geo_id] = _dc_geo[_geo_id] or {}
                                _dc_geo[_geo_continent] = _dc_geo[_geo_continent] or {}
                                _dc_geo1[_geo_id] = _geo_continent
                                _dc_geo2[_geo_id] = _blocknet_id
                                _dc_geo2[_geo_continent] = _blocknet_id

                                local _geo_myid = _blocknet_id .. "-" .. _item.id

                                _dc_geo_domain[_geo_id] = "*-" .. _continent .. "-" .. _country .. "." .. _blocknet_id
                                _dc_geo_domain[_geo_continent] = "*-" .. _continent .. "." .. _blocknet_id

                                _dc_geo_domain[_geo_myid] = _item.id .. "." .. _blocknet_id
                                _dc_geo[_geo_myid] = _dc_geo[_geo_myid] or {}

                                table_insert(_dc_geo[_blocknet_id], _obj)
                                table_insert(_dc_geo[_geo_myid], _obj)
                                table_insert(_dc_geo[_geo_id], _obj)
                                table_insert(_dc_geo[_geo_continent], _obj)

                                _dc_global1[_geo_myid] = 1
                                _dc_global[_geo_id] = 1
                                _dc_global1[_geo_continent] = 1
                            end
                        end
                        _print(_item, true)
                    end
                end
            end
        end
    end
    _print(_dc_country, true)
    if _dc_country and next(_dc_country) then
        _print("dc_country:")
        _print(_dc_country, true)
        -- _print("dc_continent:")
        -- _print(_dc_continent, true)

        -- _print("dc_global:")
        -- _print(_dc_global, true)

        local _v_maps = {}
        -- table_insert(_v_maps, _blocknet_id .. " => { ")
        for _continent_code, _continents in pairs(_dc_country) do
            -- _print("_continent_code:" .. _continent_code)
            table_insert(_v_maps, "  " .. _continent_code .. " => { ")
            for _country_code, _countries in pairs(_continents) do
                -- _print("_country_code:" .. _country_code)

                local _dcs = table_keys(_countries)
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
                -- _print("dcs")
                -- _print(_dcs, true)

                table_insert(_v_maps, "    " .. _country_code .. " => [ ")
                for _, _dc in ipairs(_dcs) do
                    table_insert(_v_maps, "        " .. _dc .. ",")
                end
                table_insert(_v_maps, "    ],")
            end
            local _country_code = "default"
            local _countries = _dc_continent[_continent_code]
            local _dcs = table_keys(_countries)
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

        local _dc_global2 = {}
        table.merge(_dc_global2, _dc_global)
        table.merge(_dc_global2, _dc_global1)
        local _dc_global_keys = table_keys(_dc_global2)

        table_insert(_v_maps, "  default => [ ")
        for _, _dc in ipairs(_dc_global_keys) do
            table_insert(_v_maps, "        " .. _dc .. ",")
        end
        table_insert(_v_maps, "  ],")
        -- table_insert(_v_maps, "}")

        -- _print("_v_maps:")
        -- _print(_v_maps, true)
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
        -- print(_geo_map)
        local _file_map = gwman_dir .. "/conf.d/geolocation.d/maps.d/mbr-map-" .. _blocknet_id
        print(_file_map)
        _write_file(_file_map, _geo_map)
    end

    -- _print("dc_geo")
    -- _print(_dc_geo, true)
    if _dc_geo and next(_dc_geo) then
        local _dapi_domains = {}
        local _dc_maps_new = {}
        for _geo_id, _geo_svrs in pairs(_dc_geo) do
            if _geo_id ~= _blocknet_id then
                -- _print("==> geo_svrs:" .. inspect(_geo_svrs))
                local _record_name = _dc_geo_domain[_geo_id]
                if _record_name then
                    table.insert(
                        _dapi_domains,
                        _record_name .. " 10/10 DYNA	geoip!mbr-map-" .. _blocknet_id .. "/" .. _geo_id
                    )
                else
                    table.insert(
                        _dapi_domains,
                        "*." .. _geo_id .. " 10/10 DYNA	geoip!mbr-map-" .. _blocknet_id .. "/" .. _geo_id
                    )
                end

                local _geo_continent = _dc_geo1[_geo_id]
                local _geo_global = _dc_geo2[_geo_id]

                local _geo_svrs1 = table.copy(_geo_svrs)
                -- _print("step 0: geo_svrs1:" .. inspect(_geo_svrs1))

                if _geo_global then
                    local _tmp = {}
                    for _, _v in ipairs(_geo_svrs1) do
                        if _v.id then
                            _tmp[_v.id] = 1
                        end
                    end
                    -- _print("step 0: geo_svrs1:" .. inspect(_geo_svrs1))

                    if _geo_continent and _dc_geo[_geo_continent] then
                        for _, _v11 in ipairs(_dc_geo[_geo_continent]) do
                            local _v1 = table.copy(_v11)
                            if _v1.id and not _tmp[_v1.id] then
                                _v1.weighted = 1000
                                table.insert(_geo_svrs1, _v1)
                                _tmp[_v1.id] = 1
                            end
                        end
                    end
                    -- _print("step 1: geo_svrs1:" .. inspect(_geo_svrs1))
                    if _geo_global and _dc_geo[_geo_global] then
                        for _, _v11 in ipairs(_dc_geo[_geo_global]) do
                            local _v1 = table.copy(_v11)
                            if _v1.id and not _tmp[_v1.id] then
                                _v1.weighted = 1
                                table.insert(_geo_svrs1, _v1)
                            end
                        end
                    end
                end
                -- _print("step 2: geo_svrs1:" .. inspect(_geo_svrs1))
                table.insert(
                    _dc_maps_new,
                    {
                        geo_id = _geo_id,
                        datacenters = _geo_svrs1
                    }
                )

                local _tmpl_res =
                    _get_tmpl(
                    rules,
                    {
                        datacenters = _geo_svrs1,
                        _domain_name = _job_data._domain_name
                    }
                )
                local _geo_dcmaps = _tmpl_res("_dcmap_maps")
                -- _print(_geo_res)
                local _file_dc_maps = gwman_dir .. "/conf.d/geolocation.d/dcmap/" .. _geo_id
                _print(_file_dc_maps)
                _write_file(_file_dc_maps, _geo_dcmaps)
            end
        end

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
        _print(_file_res)
        _write_file(_file_res, _geo_res)

        local _file_dapi = gwman_dir .. "/zones/dapi/" .. _blocknet_id .. ".zone"
        -- print(_file_dapi)
        table.insert(_dapi_domains, "*." .. _blocknet_id .. " 10/10 DYNA	geoip!mbr-map-" .. _blocknet_id .. "\n")

        _write_file(_file_dapi, table.concat(_dapi_domains, "\n"))
    end

    if _allnodes and next(_allnodes) then
        for _t, _v in pairs(_allnodes) do
            local _tmpl = _get_tmpl(rules, {nodes = _v, _domain_name = _job_data._domain_name})
            local _str_listid = _tmpl("_listids")
            mkdirp(_info_dir .. "/" .. mytype)
            local _file_listid = _info_dir .. "/" .. mytype .. "/listid-" .. _t

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
    if args._is_delete then
        local _ret = model:delete({id = args.id, user_id = args.user_id})
        if not _ret then
            return false
        end
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
    _print("item:" .. inspect(_item))
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
    local _ret = _rescanconf(job_data)
    print("result:" .. inspect(_ret))
    return true
end

--- Job handler for generate conf
--

function JobsAction:generateconfAction(job)
    print(inspect(job))
    local instance = self:getInstance()
    local job_data = job.data
    job_data._domain_name = _domain_name
    local _ret = _generate_item(instance, job_data)
    print("result:" .. inspect(_ret))
    return true
end

--- Job handler for remove conf
--
function JobsAction:removeconfAction(job)
    print(inspect(job))

    local instance = self:getInstance()
    local job_data = job.data
    local _ret = _remove_item(instance, job_data)
    print("result:" .. inspect(_ret))
    return true
end

return JobsAction
