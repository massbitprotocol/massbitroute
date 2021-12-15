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
local show_folder = mbrutil.show_folder
local inspect = mbrutil.inspect
-- local CodeGen = mbrutil.codegen
local _write_file = mbrutil.write_file
local _get_tmpl = mbrutil.get_template
local _git_push = mbrutil.git_push

JobsAction.ACCEPTED_REQUEST_TYPE = "worker"

local Model = cc.import("#" .. mytype)

-- local CodeGen = require "CodeGen"

local _deploy_dir = "/massbit/massbitroute/app/src/sites/portal/public/deploy/gateway"

local rules = {
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

-- local CodeGen = require "CodeGen"
-- local mkdirp = require "mkdirp"
local gwman_dir = "/massbit/massbitroute/app/src/sites/services/gwman"
local stat_dir = "/massbit/massbitroute/app/src/sites/services/stat"

local function _norm(_v)
    print(inspect(_v))
    if type(_v) == "string" then
        _v = json.decode(_v)
    end

    return _v
end

-- local function dirname(str)
--     if str:match(".-/.-") then
--         local name = string.gsub(str, "(.*/)(.*)", "%1")
--         return name
--     else
--         return ""
--     end
-- end

-- local function _read_file(path)
--     local file = io_open(path, "rb") -- r read mode and b binary mode
--     if not file then
--         return nil
--     end
--     local content = file:read "*a" -- *a or *all reads the whole file
--     file:close()
--     return content
-- end

-- local function _show_folder(folder)
--     local _files = {}
--     setmetatable(_files, cjson.array_mt)
--     mkdirp(folder)
--     for _file in lfs.dir(folder) do
--         if _file ~= "." and _file ~= ".." then
--             _files[#_files + 1] = _file
--         end
--     end
--     return _files
-- end

-- local function _read_dir(folder)
--     print("read_dir")
--     local _files = _show_folder(folder)
--     -- print(inspect(_files))
--     local _content = {}
--     for _, _file in ipairs(_files) do
--         print(folder .. "/" .. _file)
--         local _cont = _read_file(folder .. "/" .. _file)
--         -- print(_cont)
--         table.insert(_content, _cont)
--     end
--     return table.concat(_content, "\n")
-- end

-- local function _git_push(_dir, _files, _rfiles)
--     local _git = "git -C " .. _dir .. " "
--     local _cmd =
--         "export HOME=/tmp && " ..
--         _git ..
--             " pull origin master ;" ..
--                 _git ..
--                     "config --global user.email baysao@gmail.com" ..
--                         "&&" .. _git .. "config --global user.name baysao && " .. _git .. "remote -v"
--     for _, _file in ipairs(_files) do
--         mkdirp(dirname(_file))
--         _cmd = _cmd .. ";" .. _git .. "add -f " .. _file
--     end
--     if _rfiles then
--         for _, _file in ipairs(_rfiles) do
--             -- mkdirp(dirname(_file))
--             _cmd = _cmd .. ";" .. _git .. "rm -f " .. _file
--         end
--     end
--     _cmd = _cmd .. " ; " .. _git .. "commit -m update && " .. _git .. "push origin master"
--     -- print(_cmd)
--     local retcode, output = os.capture(_cmd)
--     print(retcode)
--     print(output)
-- end

-- local function _write_file(_filepath, content)
--     print("write_file:" .. _filepath)
--     print(inspect(content))
--     if _filepath and content then
--         mkdirp(dirname(_filepath))
--         -- print(_filepath)
--         -- print(content)
--         local _file, _ = io_open(_filepath, "w+")
--         if _file ~= nil then
--             _file:write(content)
--             _file:close()
--         end
--     end
-- end

-- local function _get_tmpl(_rules, _data)
--     local _rules1 = table.copy(_rules)
--     table.merge(_rules1, _data)
--     return CodeGen(_rules1)
-- end
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

    for _, _blockchain in ipairs(show_folder(_deploy_dir)) do
        print("blockchain:" .. _blockchain)
    end

    -- local _content_all = read_dir(_deploy_dir1)
    -- local _content_all_file = _deploy_dir .. "/" .. _k1 .. ".conf"
    -- _write_file(_content_all_file, _content_all)

    _git_push(
        _deploy_dir,
        {
            _deploy_file
            -- _content_all_file
        }
    )
    return true
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

function JobsAction:removeconfAction(job)
    print(inspect(job))

    local instance = self:getInstance()
    local job_data = job.data
    _remove_item(instance, job_data)
end

return JobsAction
