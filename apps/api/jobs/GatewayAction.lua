local cc = cc
local mytype = "gateway"
local gbc = cc.import("#gbc")
local json = cc.import("#json")

local JobsAction = cc.class(mytype .. "JobsAction", gbc.ActionBase)

local mbrutil = require "mbutil" --cc.import("#mbrutil")

local read_dir = mbrutil.read_dir
local read_file = mbrutil.read_file
local show_folder = mbrutil.show_folder
local inspect = mbrutil.inspect

-- local table_map = table.map
-- local table_walk = table.walk
local table_filter = table.filter
local table_insert = table.insert
local table_concat = table.concat
local table_keys = table.keys
local table_merge = table.merge

local _write_file = mbrutil.write_file
local _get_tmpl = mbrutil.get_template
-- local _git_push = mbrutil.git_push

local mkdirp = require "mkdirp"

JobsAction.ACCEPTED_REQUEST_TYPE = "worker"

local Model = cc.import("#" .. mytype)

local _service_dir = "/massbit/massbitroute/app/src/sites/services"
local _portal_dir = _service_dir .. "/api"
local _deploy_dir = _portal_dir .. "/public/deploy/gateway"
local _info_dir = _portal_dir .. "/public/deploy/info"

local gwman_dir = _service_dir .. "/gwman"
local stat_dir = _service_dir .. "/stat"

local _print = mbrutil.print
local rules = {
    _listid = [[${id} ${user_id} ${blockchain} ${network} ${ip} ${geo.continent_code} ${geo.country_code} ${token} ${status} ${approved}]],
    _listids = [[${nodes/_listid(); separator='\n'}]],
    _dcmap_map = [[${id} =>  [ ${ip} , 10 ],]],
    _dcmap_v1 = [[
${geo_id} => {
${id} =>  [ ${ip} , 10 ],
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
    _gw_zone = [[${id}.gw.mbr 60 A ${ip}]],
    _gw_zones = [[${nodes/_gw_zone(); separator='\n'}]],
    _gw_stat_target = [[          - ${id}.gw.mbr.massbitroute.com]],
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

local function _remove_item(instance, args)
    _print("remove_item:" .. inspect(args))
    local model = Model:new(instance)
    local _item = _norm(model:get(args))

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

    return true
end

--- Rescan gateway only for specific blockchain and network
-- using after update gateway
--
local function _rescanconf_blockchain_network(_blockchain, _network)
    _print("rescanconf_blockchain_network:" .. _blockchain .. ":" .. _network)
    local _datacenters = {}
    local _actives = {}
    local _approved = {}

    local _blocknet_id = _blockchain .. "-" .. _network

    local _network_dir = _deploy_dir .. "/" .. _blockchain .. "/" .. _network
    _print("dir:" .. _network_dir)
    for _, _continent in ipairs(show_folder(_network_dir)) do
        local _continent_dir = _network_dir .. "/" .. _continent
        for _, _country in ipairs(show_folder(_continent_dir)) do
            local _geo_id = _blocknet_id .. "-" .. _continent .. "-" .. _country

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
                        -- local _ip = _item.ip
                        -- print("ip:" .. inspect(_ip))
                        local _obj = {
                            ip = _item.ip,
                            id = _item.id,
                            -- id_block = _item.blockchain .. "-" .. _item.network,
                            geo_id = _geo_id
                            --_blocknet_id .. "-" .. _item.geo.continent_code .. "-" .. _item.geo.country_code
                        }
                        _print({id = _item.id, status = _item.status}, true)
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
                                -- _dc_geo[_blocknet_id] = _dc_geo[_blocknet_id] or {}
                                -- _dc_block[_blocknet_id] = _dc_block[_blocknet_id] or {}
                                _dc_block[_continent] = _dc_block[_continent] or {}
                                _dc_block[_continent][_country] = _dc_block[_continent][_country] or {}
                                _dc_block[_continent][_country] = _geo_id
                                table_insert(_dc_geo, _obj)
                            end
                        end
                    end
                end
            end
        end
    end
    _print("datacenters:")
    _print(_datacenters, true)
    if _datacenters["blocknet"] and #_datacenters["blocknet"] > 0 then
        local _geo_val = _datacenters["blocknet"]
        local _v_maps = {}
        local _v_datacenters = {}

        table_insert(_v_maps, _blocknet_id .. " => { ")
        for _k3, _v3 in pairs(_geo_val) do
            table_insert(_v_maps, _k3 .. " => { ")
            for _k4, _v4 in pairs(_v3) do
                table_insert(_v_maps, _k4 .. " => [ " .. _v4 .. "]")
                _v_datacenters[#_v_datacenters + 1] = _v4
            end
            table_insert(_v_maps, "}")
        end

        table_insert(_v_maps, "}")
        _print("v_maps:" .. inspect(_v_maps))
        _print("v_datacenters:" .. inspect(_v_datacenters))
        local _tmpl_map =
            _get_tmpl(
            rules,
            {
                id = _blocknet_id,
                datacenters = _v_datacenters,
                map = table_concat(_v_maps, "\n")
            }
        )
        local _geo_map = _tmpl_map("_dns_geo_map")
        print(_geo_map)
        local _file_map = gwman_dir .. "/conf.d/geolocation.d/maps.d/mbr-map-" .. _blocknet_id
        print(_file_map)
        _write_file(_file_map, _geo_map)
    end

    if _datacenters["geo"] and #_datacenters["geo"] > 0 then
        local _geo_val = _datacenters["geo"]
        local _tmpl_res =
            _get_tmpl(
            rules,
            {
                blocknet_id = _blocknet_id,
                dcmaps = _geo_val
            }
        )
        local _geo_res = _tmpl_res("_dns_geo_resource_v1")
        _print(_geo_res)
        local _file_res = gwman_dir .. "/conf.d/geolocation.d/resources.d/mbr-map-" .. _blocknet_id
        _print(_file_res)
        _write_file(_file_res, _geo_res)

        local _file_dapi = gwman_dir .. "/data/zones/dapi/" .. _blocknet_id .. ".zone"
        print(_file_dapi)
        _write_file(_file_dapi, "*." .. _blocknet_id .. " 60/60 DYNA	geoip!mbr-map-" .. _blocknet_id .. "\n")
    end

    if _approved and #_approved > 0 then
        local _tmpl = _get_tmpl(rules, {nodes = _approved})
        local _str_stat = _tmpl("_gw_stat_v1")
        mkdirp(stat_dir .. "/etc/prometheus/stat_gw")
        local _file_stat = stat_dir .. "/etc/prometheus/stat_gw/" .. _blocknet_id .. ".yml"
        _print(_str_stat)
        _print(_file_stat)
        _write_file(_file_stat, _str_stat)
    end

    if _actives and #_actives > 0 then
        -- _print(_actives, true)
        local _tmpl = _get_tmpl(rules, {nodes = _actives})
        local _str = _tmpl("_gw_zones")
        _print(_str)
        local _file = gwman_dir .. "/data/zones/" .. mytype .. "/" .. _blocknet_id .. ".zone"
        _print(_file)
        _write_file(_file, _str)

        -- local _tmpl = _get_tmpl(rules, {nodes = _datacenter_ids_all})
        -- local _str_stat = _tmpl("_gw_stat_v1")
        -- mkdirp(stat_dir .. "/etc/prometheus/stat_gw")
        -- local _file_stat = stat_dir .. "/etc/prometheus/stat_gw/" .. _blocknet_id .. ".yml"
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

local function _rescanconf1()
    -- local _commit_files = {}

    local _datacenter_ids_all = {}
    local _datacenter_ids_by_blockchain = {}
    local _maps = {}
    for _, _blockchain in ipairs(show_folder(_deploy_dir)) do
        local _blockchain_dir = _deploy_dir .. "/" .. _blockchain
        for _, _network in ipairs(show_folder(_blockchain_dir)) do
            local _blk_id = _blockchain .. "-" .. _network
            _maps[_blk_id] = _maps[_blk_id] or {datacenters = {}, datacenter_ids = {}}

            -- local _maps1 = _maps[_blk_id].maps
            local _datacenters1 = _maps[_blk_id].datacenters
            local _datacenter_ids = _maps[_blk_id].datacenter_ids

            -- table.insert(_maps1, _blk_id .. " => {")
            local _network_dir = _blockchain_dir .. "/" .. _network
            for _, _continent in ipairs(show_folder(_network_dir)) do
                -- table.insert(_maps1, _continent .. " => {")
                local _continent_dir = _network_dir .. "/" .. _continent
                for _, _country in ipairs(show_folder(_continent_dir)) do
                    local _dc_id = _blockchain .. "-" .. _network .. "-" .. _continent .. "-" .. _country

                    -- table.insert(_maps1, _country .. " => [ " .. _dc_id .. " ],")

                    local _country_dir = _continent_dir .. "/" .. _country
                    for _, _user_id in ipairs(show_folder(_country_dir)) do
                        local _user_dir = _country_dir .. "/" .. _user_id
                        for _, _id in ipairs(show_folder(_user_dir)) do
                            local _file = _user_dir .. "/" .. _id
                            local _item = read_file(_file)
                            if _item then
                                if type(_item) == "string" then
                                    _item = json.decode(_item)
                                end
                                local _ip = _item.ip
                                print("ip:" .. inspect(_ip))
                                if tonumber(_item.status) == 1 then
                                    _item._is_enabled = true
                                    if _item.approved and tonumber(_item.approved) == 1 then
                                        _item._is_approved = true
                                        _datacenters1[_dc_id] = _datacenters1[_dc_id] or {}
                                        table_insert(
                                            _datacenters1[_dc_id],
                                            _id .. " => " .. " [ " .. _ip .. " , " .. 10 .. " ],"
                                        )
                                        table_insert(_datacenter_ids, {id = _id, ip = _ip})
                                    end
                                    table_insert(_datacenter_ids_all, {id = _id, ip = _ip})
                                    _datacenter_ids_by_blockchain[_blk_id] =
                                        _datacenter_ids_by_blockchain[_blk_id] or {}
                                    table_insert(_datacenter_ids_by_blockchain[_blk_id], {id = _id, ip = _ip})
                                end
                            end
                        end
                    end
                end
                -- table.insert(_maps1, "},")
            end
            -- table.insert(_maps1, "},")
        end
    end

    _print("maps:" .. inspect(_maps))
    _print("datacenter_ids_all:" .. inspect(_datacenter_ids_all))
    _print("datacenter_ids_by_blockchain:" .. inspect(_datacenter_ids_by_blockchain))
    for _k, _v in pairs(_maps) do
        -- local _v_datacenters = _v.datacenters
        -- local _v_maps = _v.maps
        local _v_datacenters =
            table_filter(
            _v.datacenters,
            function(_v1)
                return #_v1 > 0
            end
        )

        _print("v_datacenters:" .. #_v_datacenters .. ":" .. inspect(_v_datacenters))
        -- _print("maps:" .. inspect(_v_maps))

        if next(_v_datacenters) ~= nil then
            local _dcmaps = {}
            local _new_maps = {}
            for _k1, _v1 in pairs(_v_datacenters) do
                _print(_k1)
                _print("v1:" .. inspect(_v1))

                if next(_v1) ~= nil then
                    local _list = _k1:split("-")
                    _print(_list, true)
                    local _blockchain = _list[1]
                    local _network = _list[2]
                    local _continent = _list[3]
                    local _country = _list[4]

                    local _blnet = _blockchain .. "-" .. _network

                    _new_maps[_blnet] = _new_maps[_blnet] or {}
                    _new_maps[_blnet][_continent] = _new_maps[_blnet][_continent] or {}
                    _new_maps[_blnet][_continent][_country] = _k1

                    _dcmaps[#_dcmaps + 1] = {
                        id = _k1,
                        str = table_concat(_v1, "\n")
                    }
                end
            end
            _print("dcmaps:" .. #_dcmaps .. ":" .. inspect(_dcmaps))
            _print("new_maps:" .. #_new_maps .. ":" .. inspect(_new_maps))

            -- if #_dcmaps == 0 then
            --     break
            -- end

            if #_dcmaps > 0 then
                local _tmpl_res =
                    _get_tmpl(
                    rules,
                    {
                        id = _k,
                        dcmaps = _dcmaps
                    }
                )
                local _geo_res = _tmpl_res("_dns_geo_resource")

                local _file_res = gwman_dir .. "/conf.d/geolocation.d/resources.d/mbr-map-" .. _k
                print(_file_res)
                _write_file(_file_res, _geo_res)

                local _v_maps1 = {}
                for _k2, _v2 in pairs(_new_maps) do
                    table_insert(_v_maps1, _k2 .. " => { ")
                    for _k3, _v3 in pairs(_v2) do
                        table_insert(_v_maps1, _k3 .. " => { ")
                        for _k4, _v4 in pairs(_v3) do
                            table_insert(_v_maps1, _k4 .. " => [ " .. _v4 .. "]")
                        end
                        table_insert(_v_maps1, "}")
                    end

                    table_insert(_v_maps1, "}")
                end

                -- table.insert(_commit_files, _file_res)
                -- if next(_v_datacenters) ~= nil then
                local _tmpl_map =
                    _get_tmpl(
                    rules,
                    {
                        id = _k,
                        datacenters = table_keys(_v_datacenters),
                        map = table_concat(_v_maps1, "\n")
                    }
                )
                local _geo_map = _tmpl_map("_dns_geo_map")
                -- print(_geo_map)
                local _file_map = gwman_dir .. "/conf.d/geolocation.d/maps.d/mbr-map-" .. _k
                print(_file_map)
                _write_file(_file_map, _geo_map)
                -- end

                -- table.insert(_commit_files, _file_map)

                -- print(inspect(_v.datacenter_ids))
                -- local _v_datacenter_ids = _v.datacenter_ids
                -- _print(" _v_datacenter_ids:" .. inspect(_v_datacenter_ids))
                -- if next(_v_datacenter_ids) ~= nil then
                --     local _tmpl = _get_tmpl(rules, {nodes = _v.datacenter_ids})
                --     local _str_stat = _tmpl("_gw_zones")
                --     local _file_zone = gwman_dir .. "/data/zones/" .. mytype .. "/" .. _k .. ".zone"
                --     print(_file_zone)
                --     _write_file(_file_zone, _str_stat)
                -- end

                -- table.insert(_commit_files, _file_zone)

                -- print(_str_stat)
                local _file_dapi = gwman_dir .. "/data/zones/dapi/" .. _k .. ".zone"
                print(_file_dapi)
                _write_file(_file_dapi, "*." .. _k .. " 60/60 DYNA	geoip!mbr-map-" .. _k .. "\n")
            -- table.insert(_commit_files, _file_dapi)
            end
        end
    end

    _print("generate common conf")

    local _zone_content = {}
    table_insert(_zone_content, read_file(gwman_dir .. "/data/zones/massbitroute.com"))
    table_insert(_zone_content, read_dir(gwman_dir .. "/data/zones/gateway"))
    table_insert(_zone_content, read_dir(gwman_dir .. "/data/zones/node"))
    table_insert(_zone_content, read_dir(gwman_dir .. "/data/zones/dapi"))

    -- print(inspect(_zone_content))
    local _zone_main = gwman_dir .. "/zones/massbitroute.com"
    print(_zone_main)
    _write_file(_zone_main, table_concat(_zone_content, "\n"))
    -- table.insert(_commit_files, _zone_main)

    for _k1, _v1 in pairs(_datacenter_ids_by_blockchain) do
        local _tmpl = _get_tmpl(rules, {nodes = _v1})
        local _str = _tmpl("_gw_zones")
        local _file = gwman_dir .. "/data/zones/" .. mytype .. "/" .. _k1 .. ".zone"
        _print(_file)
        _write_file(_file, _str)
    end

    local _tmpl = _get_tmpl(rules, {nodes = _datacenter_ids_all})
    local _str_stat = _tmpl("_gw_stat")
    local _file_stat = stat_dir .. "/etc/prometheus/stat_gw.yml"
    print(_file_stat)
    _write_file(_file_stat, _str_stat)
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

    _rescanconf_blockchain_network(_item.blockchain, _item.network)
    return true
end

--- Job handler for rescan conf
-- Scan all files and update status
--

function JobsAction:rescanconfAction(job)
    -- local instance = self:getInstance()
    -- local job_data = job.data
    _rescanconf()
end

--- Job handler for generate conf
--

function JobsAction:generateconfAction(job)
    print(inspect(job))

    local instance = self:getInstance()
    local job_data = job.data
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
