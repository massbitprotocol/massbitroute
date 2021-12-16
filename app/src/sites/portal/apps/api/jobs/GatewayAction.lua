local mytype = "gateway"
local cc = cc
local gbc = cc.import("#gbc")
local json = cc.import("#json")
-- local io_open = io.open

local JobsAction = cc.class(mytype .. "JobsAction", gbc.ActionBase)

local mbrutil = cc.import("#mbrutil")

-- local mkdirp = mbrutil.mkdirp
-- local dirname = mbrutil.dirname
local read_dir = mbrutil.read_dir
local read_file = mbrutil.read_file
local show_folder = mbrutil.show_folder
local inspect = mbrutil.inspect
-- local CodeGen = mbrutil.codegen
local _write_file = mbrutil.write_file
local _get_tmpl = mbrutil.get_template
local _git_push = mbrutil.git_push

JobsAction.ACCEPTED_REQUEST_TYPE = "worker"

local Model = cc.import("#" .. mytype)

local _deploy_dir = "/massbit/massbitroute/app/src/sites/portal/public/deploy/gateway"

local gwman_dir = "/massbit/massbitroute/app/src/sites/services/gwman"
local stat_dir = "/massbit/massbitroute/app/src/sites/services/stat"

local rules = {
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
    _gw_zone = [[${id}.gw.mbr 600 A ${ip}]],
    _gw_zones = [[${nodes/_gw_zone(); separator='\n'}]],
    _gw_stat_target = [[          - ${id}.gw.mbr.massbitroute.com]],
    _gw_stat = [[
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
${nodes/_gw_stat_target(); separator='\n'}
]]
}

local function _norm(_v)
    print(inspect(_v))
    if type(_v) == "string" then
        _v = json.decode(_v)
    end

    return _v
end

local function _remove_item(instance, args)
    local model = Model:new(instance)
    local _item = _norm(model:get(args))
    print("item:")
    print(inspect(_item))

    if
        not _item or not _item.id or not _item.ip or not _item.blockchain or not _item.network or not _item.geo or
            not _item.geo.continent_code or
            not _item.geo.country_code
     then
        return nil, "invalid data"
    end

    local _k1 =
        _item.blockchain .. "/" .. _item.network .. "/" .. _item.geo.continent_code .. "/" .. _item.geo.country_code

    local _deploy_file = _deploy_dir .. "/" .. _k1 .. "/" .. _item.id
    os.remove(_deploy_file)
    _git_push(
        _deploy_dir,
        {},
        {
            _deploy_file
        }
    )

    return true
end
local function _update_gdnsd()
    local _commit_files = {}
    -- local _datacenters = {}
    local _maps = {}
    for _, _blockchain in ipairs(show_folder(_deploy_dir)) do
        print("blockchain:" .. _blockchain)
        for _, _network in ipairs(show_folder(_deploy_dir .. "/" .. _blockchain)) do
            print("network:" .. _network)
            local _blk_id = _blockchain .. "-" .. _network
            _maps[_blk_id] = _maps[_blk_id] or {maps = {}, datacenters = {}, datacenter_ids = {}}
            -- _datacenters[_blk_id] = _datacenters[_blk_id] or {}
            local _maps1 = _maps[_blk_id].maps
            local _datacenters1 = _maps[_blk_id].datacenters
            local _datacenter_ids = _maps[_blk_id].datacenter_ids

            table.insert(_maps1, _blk_id .. " => {")
            for _, _continent in ipairs(show_folder(_deploy_dir .. "/" .. _blockchain .. "/" .. _network)) do
                print("continent:" .. _continent)
                table.insert(_maps1, _continent .. " => {")
                for _, _country in ipairs(
                    show_folder(_deploy_dir .. "/" .. _blockchain .. "/" .. _network .. "/" .. _continent)
                ) do
                    print("country:" .. _country)
                    local _dc_id = _blockchain .. "-" .. _network .. "-" .. _continent .. "-" .. _country

                    table.insert(_maps1, _country .. " => [ " .. _dc_id .. " ],")
                    _datacenters1[_dc_id] = _datacenters1[_dc_id] or {}
                    for _, _id in ipairs(
                        show_folder(
                            _deploy_dir .. "/" .. _blockchain .. "/" .. _network .. "/" .. _continent .. "/" .. _country
                        )
                    ) do
                        local _ip =
                            read_file(
                            _deploy_dir ..
                                "/" ..
                                    _blockchain .. "/" .. _network .. "/" .. _continent .. "/" .. _country .. "/" .. _id
                        )
                        table.insert(_datacenter_ids, {id = _id, ip = _ip})
                        table.insert(_datacenters1[_dc_id], _id .. " => " .. " [ " .. _ip .. " , " .. 10 .. " ],")
                    end
                end
                table.insert(_maps1, "},")
            end
            table.insert(_maps1, "},")
        end
    end

    print(inspect(_maps))
    for _k, _v in pairs(_maps) do
        local _dcmaps = {}
        for _k1, _v1 in pairs(_v.datacenters) do
            _dcmaps[#_dcmaps + 1] = {
                id = _k1,
                str = table.concat(_v1, "\n")
            }
        end

        local _tmpl_res =
            _get_tmpl(
            rules,
            {
                id = _k,
                dcmaps = _dcmaps
            }
        )
        print(
            inspect(
                {
                    id = _k,
                    dcmaps = _dcmaps
                }
            )
        )
        local _geo_res = _tmpl_res("_dns_geo_resource")
        print(_geo_res)
        local _file_res = gwman_dir .. "/conf.d/geolocation.d/resources.d/mbr-map-" .. _k
        _write_file(_file_res, _geo_res)
        table.insert(_commit_files, _file_res)
        local _tmpl_map =
            _get_tmpl(
            rules,
            {
                id = _k,
                datacenters = table.keys(_v.datacenters),
                map = table.concat(_v.maps, "\n")
            }
        )
        local _geo_map = _tmpl_map("_dns_geo_map")
        print(_geo_map)
        local _file_map = gwman_dir .. "/conf.d/geolocation.d/maps.d/mbr-map-" .. _k
        _write_file(_file_map, _geo_map)
        table.insert(_commit_files, _file_map)

        print(inspect(_v.datacenter_ids))
        local _tmpl = _get_tmpl(rules, {nodes = _v.datacenter_ids})
        local _str_stat = _tmpl("_gw_zones")
        print(_str_stat)
        local _file_zone = gwman_dir .. "/data/zones/gateway/" .. _k .. ".zone"
        _write_file(_file_zone, _str_stat)
        table.insert(_commit_files, _file_zone)

        local _zone_content = {}
        table.insert(_zone_content, read_file(gwman_dir .. "/data/zones/massbitroute.com"))
        table.insert(_zone_content, read_dir(gwman_dir .. "/data/zones/gateway"))
        table.insert(_zone_content, read_dir(gwman_dir .. "/data/zones/node"))
        print(inspect(_zone_content))
        local _zone_main = gwman_dir .. "/zones/massbitroute.com"
        _write_file(_zone_main, table.concat(_zone_content, "\n"))
        table.insert(_commit_files, _zone_main)

        local _tmpl = _get_tmpl(rules, {nodes = _v.datacenter_ids})
        local _str_stat = _tmpl("_gw_stat")
        _write_file(stat_dir .. "/etc/prometheus/stat_gw.yml", _str_stat)
        _git_push(
            stat_dir,
            {
                stat_dir .. "/etc/prometheus/stat_gw.yml"
            }
        )
    end

    _git_push(gwman_dir, _commit_files)
end

local function _generate_item(instance, args)
    local model = Model:new(instance)
    local _item = _norm(model:get(args))
    print(inspect(_item))

    if
        not _item or not _item.id or not _item.ip or not _item.blockchain or not _item.network or not _item.geo or
            not _item.geo.continent_code or
            not _item.geo.country_code
     then
        return nil, "invalid data"
    end

    local _k1 =
        _item.blockchain .. "/" .. _item.network .. "/" .. _item.geo.continent_code .. "/" .. _item.geo.country_code
    local _deploy_file = _deploy_dir .. "/" .. _k1 .. "/" .. _item.id
    _write_file(_deploy_file, _item.ip)
    _git_push(_deploy_dir, {_deploy_file})
    _update_gdnsd()

    return true
end

--- Generate conf for gateway

function JobsAction:generateconfAction(job)
    print(inspect(job))

    local instance = self:getInstance()
    local job_data = job.data
    _generate_item(instance, job_data)
    -- _update_gateway_conf(instance)
end

function JobsAction:removeconfAction(job)
    print(inspect(job))

    local instance = self:getInstance()
    local job_data = job.data
    _remove_item(instance, job_data)
end

return JobsAction
