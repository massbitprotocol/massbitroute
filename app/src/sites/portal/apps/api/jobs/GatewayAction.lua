local cc = cc
local gbc = cc.import("#gbc")
local json = cc.import("#json")
local io_open = io.open
local mytype = "gateway"
local JobsAction = cc.class(mytype .. "JobsAction", gbc.ActionBase)

local inspect = require "inspect"

JobsAction.ACCEPTED_REQUEST_TYPE = "worker"

local function _git_push(_dir, _files)
    local _git = "git -C " .. _dir .. " "
    local _cmd =
        "export HOME=/tmp && " ..
        _git ..
            "config --global user.email baysao@gmail.com" ..
                "&&" .. _git .. "config --global user.name baysao && " .. _git .. "remote -v"
    for _, _file in ipairs(_files) do
        _cmd = _cmd .. "&&" .. _git .. "add " .. _file
    end
    _cmd = _cmd .. " && " .. _git .. "commit -m update && " .. _git .. "push origin master"
    -- print(_cmd)
    local retcode, output = os.capture(_cmd)
    print(retcode)
    print(output)

    -- local handle = io.popen(_cmd)
    -- local result = handle:read("*a")
    -- handle:close()
    -- print(result)
end

local Model = cc.import("#" .. mytype)

-- local CodeGen = require "CodeGen"
local mkdirp = require "mkdirp"
local gwman_dir = "/massbit/massbitroute/app/src/sites/services/gwman"
local stat_dir = "/massbit/massbitroute/app/src/sites/services/stat"
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

--- Generate conf for gateway

function JobsAction:generateconfAction(job)
    print(inspect(job))
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

    local instance = self:getInstance()

    local model = Model:new(instance)
    local args = job.data
    local _gateway = model:get(args)
    print(inspect(_gateway))
    local _datacenters = {}

    local _red = instance:getRedis()
    local _user_gw = _red:keys("*:" .. mytype)
    print(inspect(_user_gw))
    for _, _k in ipairs(_user_gw) do
        local _gw_arr = _red:arrayToHash(_red:hgetall(_k))
        print(inspect(_gw_arr))
        for _, _gw_str in pairs(_gw_arr) do
            local _gw = json.decode(_gw_str)
            print(inspect(_gw))
            local _dc_id = table.concat({"mbr", "map", _gw.blockchain, _gw.network}, "-")
            _datacenters[_dc_id] = _datacenters[_dc_id] or {}
            _datacenters[_dc_id][_gw.geo.continent_code] = _datacenters[_dc_id][_gw.geo.continent_code] or {}
            _datacenters[_dc_id][_gw.geo.continent_code][_gw.geo.country_code] =
                _datacenters[_dc_id][_gw.geo.continent_code][_gw.geo.country_code] or {}
            table.insert(_datacenters[_dc_id][_gw.geo.continent_code][_gw.geo.country_code], _gw)
        end
    end
    print(inspect(_datacenters))

    for _k1, _v1 in pairs(_datacenters) do
        local _dcs = {}
        local _mapstr = {}
        local _resstr = {}
        local _zonesstr = {}

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
                    table.insert(_prometheus, "          - " .. _v4.id .. ".gw.mbr.massbitroute.com")
                    table.insert(_zonesstr, _v4.id .. ".gw.mbr 600 A " .. _v4.ip)
                    table.insert(_resstr, _v4.ip .. ",")
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
        print(table.concat(_mapstr, "\n"))
        _write_file(gwman_dir .. "/conf.d/geolocation.d/maps.d/" .. _k1, table.concat(_mapstr, "\n"))
        print(table.concat(_resstr, "\n"))
        _write_file(gwman_dir .. "/conf.d/geolocation.d/resources.d/" .. _k1, table.concat(_resstr, "\n"))
        print(table.concat(_zonesstr, "\n"))

        _write_file(gwman_dir .. "/data/zones/" .. _k1 .. ".zone", table.concat(_zonesstr, "\n"))
        _git_push(
            gwman_dir,
            {
                gwman_dir .. "/conf.d/geolocation.d/maps.d/" .. _k1,
                gwman_dir .. "/conf.d/geolocation.d/resources.d/" .. _k1,
                gwman_dir .. "/data/zones/" .. _k1 .. ".zone"
            }
        )
    end
    _write_file(stat_dir .. "/etc/prometheus/stat.yml", table.concat(_prometheus, "\n"))
    _git_push(
        stat_dir,
        {
            stat_dir .. "/etc/prometheus/stat.yml"
        }
    )
end
return JobsAction
