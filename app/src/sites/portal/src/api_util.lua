local lfs = require("lfs")
local cjson = require("cjson")
local mkdirp = require "mkdirp"
local flatdb = require "flatdb"
local inspect = require "inspect"
local shell = require "resty.shell"
local util = require "util"
local json_fields = {
    map = {"map_geos"},
    datacenter = {"dc_hosts"}
}

local typeParent = {
    user = "billing",
    stack = "user",
    dns = "stack",
    site = "stack",
    record = "dns",
    monitor = "dns",
    map = "dns",
    datacenter = "dns"
}
local typeChild = {
    dns = {"record"}
}

local typeRelationId = {
    record = {"map"}
}
local typeRelation = {
    record = {"datacenter", "monitor"}
}

local _M = {}
_M.json_fields = json_fields
_M.typeParent = typeParent

local function _run_shell(cmd)
    ngx.log(ngx.ERR, inspect(cmd))
    local stdin = ""
    local timeout = 300000 -- ms
    local max_size = 409600 -- byte
    local ok, stdout, stderr, reason, status = shell.run(cmd, stdin, timeout, max_size)
    ngx.log(ngx.ERR, inspect(ok))
    ngx.log(ngx.ERR, inspect(stdout))
    ngx.log(ngx.ERR, inspect(stderr))
    return ok, stdout, stderr, reason, status
end

local function showFolder(folder)
    local _files = {}
    setmetatable(_files, cjson.array_mt)
    mkdirp(folder)
    for _file in lfs.dir(folder) do
        if _file ~= "." and _file ~= ".." then
            _files[#_files + 1] = {id = _file}
        end
    end
    return _files
end

local function dirname(str)
    if str:match(".-/.-") then
        local name = string.gsub(str, "(.*/)(.*)", "%1")
        return name
    else
        return ""
    end
end
local function groupBy(_dc_hosts)
    local _groups = {}
    local _tmp = {}
    table.walk(
        _dc_hosts,
        function(_host)
            if _host.group then
                if not _groups[_host.group] then
                    _groups[_host.group] = {}
                end
                if _host then
                    table.insert(_groups[_host.group], _host)
                end
            end
        end
    )

    for _idx, _list in pairs(_groups) do
        table.insert(_tmp, {id = _idx, dc_hosts = _list})
    end
    return _tmp
end
local function getIdByType(_type, id, _data)
    if not id and _data.id then
        id = _data.id
    end
    if id then
        local _dir = ngx.var.app_root .. "/data/" .. _type .. "/detail"
        mkdirp(_dir)
        local _db = flatdb(_dir)
        if not _db[id] then
            _db[id] = {}
        end
        _data = table.copy(_db[id])
    end
    if id and _data then
        if _data.id then
            id = _data.id
        end
        local _type_childs = typeChild[_type]

        local _dir_list = ngx.var.app_root .. "/data/" .. _type .. "/list"

        if _type_childs then
            for _, _child in pairs(_type_childs) do
                if _child then
                    ngx.log(ngx.ERR, inspect(_child))
                    local _dir_child = _dir_list .. "/" .. _child .. "/" .. id

                    mkdirp(_dir_child)
                    local _data_child = showFolder(_dir_child)

                    if _data_child then
                        local _tmps = {}
                        for _, _child1 in ipairs(_data_child) do
                            local _id1 = _child1.id

                            local _data1 = getIdByType(_child, _id1)

                            _tmps[#_tmps + 1] = _data1
                        end
                        _data[_child .. "s"] = _tmps
                    end
                end
            end
        end
    end

    local _json_fields = json_fields[_type]
    if _json_fields then
        for _, _field in ipairs(_json_fields) do
            if _data[_field] and type(_data[_field]) == "string" then
                local _tmp = cjson.decode(_data[_field])
                if _tmp then
                    _data[_field] = _tmp
                end
            end
        end
    end
    local _parentTypes = typeRelationId[_type]
    if _parentTypes then
        for _, _parentType in ipairs(_parentTypes) do
            local _parentTypeId = _parentType .. "_id"
            if _parentTypeId and _data[_parentTypeId] then
                local _id2 = _data[_parentTypeId]
                local _tmp = getIdByType(_parentType, _id2)
                if _tmp then
                    _data[_parentType] = _tmp
                end
            end
        end
    end
    _parentTypes = typeRelation[_type]
    if _parentTypes then
        for _, _parentType in ipairs(_parentTypes) do
            local _arr = _data[_parentType .. "s"]
            if _arr then
                if type(_arr) == "string" then
                    local _tmp = string.split(_arr, ",")
                    _arr = _tmp
                end
                ngx.log(ngx.ERR, cjson.encode(_arr))
                local _data_tmp = {}
                for _, _id2 in ipairs(_arr) do
                    local _tmp = getIdByType(_parentType, _id2)
                    if _tmp then
                        _data_tmp[#_data_tmp + 1] = _tmp
                    end
                end
                _data[_parentType .. "s"] = _data_tmp
            end
        end
    end

    return _data
end

local function _write_file(_filepath, content)
    if _filepath then
        mkdirp(dirname(_filepath))
        ngx.log(ngx.ERR, "write_file:" .. _filepath)
        ngx.log(ngx.ERR, content)
        local _file, _ = io.open(_filepath, "w+")
        if _file ~= nil then
            _file:write(content)
            _file:close()
        end
    end
end

local CodeGen = require "CodeGen"
local rules = {
    zones = {
        _domain = [[
$TTL 300
$ORIGIN ${domain}.
@		SOA ns${ns1}.${domain_root}. hostmaster.${domain_root}.(
		20180908000001
		7200
		30M
		3D
		900
)
@		NS ns${ns1}.${domain_root}.
@		NS ns${ns2}.${domain_root}.
]]
    },
    monitor = {
        tcp_connect = [[
monitor_${rand} => {
    plugin => tcp_connect,
    port => ${port},
    up_thresh => ${up_thresh},
    ok_thresh => ${ok_thresh},
    down_thresh => ${down_thresh},
    interval => ${interval},
    timeout => ${timeout}
}
]],
        http_status = [[
 monitor_${rand} => {
    plugin => http_status,
    port => ${port},
    url_path => ${url_path},
    vhost => ${vhost},
    ok_codes => [ ${ok_codes} ],
    up_thresh => ${up_thresh},
    ok_thresh => ${ok_thresh},
    down_thresh => ${down_thresh},
    interval => ${interval},
    timeout => ${timeout}
}
]]
    },
    record = {
        static = {
            _default = [[
${name} ${ttl} ${type} ${static}
]],
            _mx = [[
${name} ${type} ${priority} ${static}
]]
        },
        weighted = {
            _dc_hosts = [[
 ${dc_hosts/_dc_host(); separator='\n'}
]],
            _dc_host = [[
host_${group}_${id} = [${value}, ${weight}]
]],
            _datacenter_groups = [[
#groups
 ${dc_hosts/_datacenter_group(); separator='\n'}
]],
            _datacenter_group = [[
#group
group_${id} => {
 ${_dc_hosts()}
}
]],
            _datacenter = [[
#dc
${_is_grouped?_datacenter_groups()!_dc_hosts()}
]],
            _zone = [[
${name} ${ttl} DYN${_type} ${routing_type}!record_${user_id}_${stack_id}_${dns_id}_${id}
]],
            _service_types = [[service_types =>  ${service_types}]],
            _default = [[
record_${user_id}_${stack_id}_${dns_id}_${id} => {
     ${service_types?_service_types()}
     multi = ${_is_multi}
     up_thresh => ${up_thresh}
     ${_datacenter()}
}
]]
        }
    }
}

local function _get_tmpl(rules, _data)
    local _rules = table.copy(rules)
    table.merge(_rules, _data)
    return CodeGen(_rules)
end

function _M.generateDnsZonesDomain(_old_data, _data)
    ngx.log(ngx.ERR, "generateDnsZonesDomain:")
    -- ngx.log(ngx.ERR, "old:" .. cjson.encode(_old_data))
    -- ngx.log(ngx.ERR, "new:" .. cjson.encode(_data))
    local _dir = ngx.var.site_root .. "/services/dns"
    if _old_data then
        if _old_data.domain then
            local _record_list = {}
--            os.remove(_dir .. "/zones/" .. _old_data.domain)
            --ngx.log(ngx.ERR, "remove:" .. _dir .. "/zones/" .. _old_data.domain)

            if _old_data.records then
                for _, _record in ipairs(_old_data.records) do
                    local _id = _record.id
                    if _id then
                        _record_list[#_record_list + 1] = _id
                    -- local _monitor_path =
                    --     "conf.d/monitors.d/" .. _data.user_id .. "/" .. _data.stack_id .. "/" .. _data.id
                    -- local _record_path =
                    --     "conf.d/" ..
                    --     _record.routing_type .. ".d/" .. _data.user_id .. "/" .. _data.stack_id .. "/" .. _data.id
                    -- os.remove(_dir .. "/" .. _monitor_path .. "/" .. _id)
                    -- ngx.log(ngx.ERR, "remove:" .. _dir .. "/" .. _monitor_path .. "/" .. _id)
                    -- os.remove(_dir .. "/" .. _record_path .. "/" .. _id)
                    -- ngx.log(ngx.ERR, "remove:" .. _dir .. "/" .. _record_path .. "/" .. _id)
                    end
                end
            end

            local _tmp_records = table.concat(_record_list, " ")
            local _cmd =
                table.concat(
                {
                    ngx.var.site_root .. "/services/dns/run clean",
                    _old_data.domain,
                    _old_data.user_id,
                    _old_data.stack_id,
                    _old_data.id,
                    _tmp_records
                },
                " "
            )
            ngx.log(ngx.ERR, _cmd)
	    _run_shell(_cmd)
        end
    end

    local _files = {}

    local _record_list = {}

    if _data and _data.domain then
        if tonumber(_data.status) == 0 then
            if _data and _data.domain then
                os.remove(_dir .. "/zones/" .. _data.domain)
            end
        else
            if _old_data and _old_data.domain and _old_data.domain ~= _data.domain then
                os.remove(_dir .. "/zones/" .. _old_data.domain)
            end

            if not _data.domain_root then
                _data.domain_root = "vngstack.com"
            end
            if not _data.ns1 then
                _data.ns1 = "1"
            end
            if not _data.ns2 then
                _data.ns2 = "2"
            end

            local _zones_tmpl = {}
            local _monitors_tmpl = {}

            local _tmpl = _get_tmpl(rules.zones, _data)

            if _data.records then
                table.insert(_zones_tmpl, _tmpl("_domain"))
                for _, _record in ipairs(_data.records) do
                    if _record.id then
                        table.insert(_record_list, _record.id)
                    end
                    local _records_tmpl = {}
                    ngx.log(ngx.ERR, cjson.encode(_record))

                    if _record.address_mixed and tonumber(_record.address_mixed) == 1 then
                        _record["_is_mixed"] = true
                    end
                    if _record.grouped and tonumber(_record.grouped) == 1 then
                        _record["_is_grouped"] = true
                    end

                    if _record.multi and tonumber(_record.multi) == 1 then
                        _record["_is_multi"] = true
                    end

                    if _record.type == "CNAME" and _record.routing_type ~= "static" then
                        _record._type = "C"
                    else
                        _record._type = _record.type
                    end

                    if (_record.type == "A" or _record.type == "AAAA") and _record.monitors then
                        local _service_types = {}
                        if _record.monitors == "up" then
                            _service_types = {"up"}
                        else
                            _service_types[#_service_types + 1] = "["
                            for _, _monitor in ipairs(_record.monitors) do
                                if _monitor.timeout then
                                    _monitor.timeout = tonumber(_monitor.timeout)
                                end
                                if _monitor.interval then
                                    _monitor.interval = tonumber(_monitor.interval)
                                end
                                if _monitor.timeout >= _monitor.interval then
                                    _monitor.timeout = _monitor.interval - 1
                                end

                                _monitor.rand = util.randomString(8)
                                _service_types[#_service_types + 1] = "monitor_" .. _monitor.rand
                                -- _data.user_id ..
                                --     "_" ..
                                --         _data.stack_id ..
                                --             "_" .. _data.id .. "_" .. _monitor.id .. "_" .. _monitor.rand
                                local _tmpl_monitor = _get_tmpl(rules.monitor, _monitor)
                                if _monitor.monitor_type then
                                    _monitors_tmpl[_monitor.id] = _tmpl_monitor(_monitor.monitor_type)
                                end
                            end
                            _service_types[#_service_types + 1] = "]"
                        end
                        _record["service_types"] = table.concat(_service_types, " ")
                    end

                    if _record.routing_type == "static" then
                        local _tmpl_record = _get_tmpl(rules.record[_record.routing_type], _record)
                        if _record.type == "MX" then
                            table.insert(_zones_tmpl, _tmpl_record("_mx"))
                        else
                            table.insert(_zones_tmpl, _tmpl_record("_default"))
                        end
                    elseif _record.routing_type == "weighted" then
                        local _dc_hosts_cname = {}
                        local _dc_hosts_v4 = {}
                        local _dc_hosts_v6 = {}
                        local _datacenters = {}
                        table.walk(
                            _record.datacenters,
                            function(_datacenter)
                                local _dc_hosts = _datacenter.dc_hosts
                                ngx.log(ngx.ERR, cjson.encode(_dc_hosts))
                                if _dc_hosts then
                                    table.walk(
                                        _dc_hosts,
                                        function(_host, _idx)
                                            _host.group = _datacenter.id
                                            _host.id = _idx
                                            if _host.address_type == "cname" then
                                                _host.value = _host.value .. "."
                                                table.insert(_dc_hosts_cname, _host)
                                            end
                                            if _host.address_type == "addrs_v4" then
                                                table.insert(_dc_hosts_v4, _host)
                                            end
                                            if _host.address_type == "addrs_v6" then
                                                table.insert(_dc_hosts_v6, _host)
                                            end
                                        end
                                    )
                                end

                                return _datacenter
                            end
                        )
                        if _record["_is_grouped"] then
                            _dc_hosts_v4 = groupBy(_dc_hosts_v4)
                            _dc_hosts_v6 = groupBy(_dc_hosts_v6)
                        --_dc_hosts_cname = groupBy(_dc_hosts_cname)
                        end

                        if _record.type == "A" then
                            _datacenters = _dc_hosts_v4
                        elseif _record.type == "AAAA" then
                            _datacenters = _dc_hosts_v6
                        elseif _record.type == "CNAME" then
                            _record["_is_grouped"] = false
                            _record["_is_multi"] = false
                            _datacenters = _dc_hosts_cname
                        end

                        _record.dc_hosts = _datacenters
                    end
                    --		    ngx.log(ngx.ERR, cjson.encode(_record))
                    ngx.log(ngx.ERR, inspect(_record.dc_hosts))
                    local _tmpl_record = _get_tmpl(rules.record[_record.routing_type], _record)
                    _records_tmpl[_record.id] = _tmpl_record("_default")
                    table.insert(_zones_tmpl, _tmpl_record("_zone"))
                    local _monitor_path =
                        "conf.d/monitors.d/" .. _data.user_id .. "/" .. _data.stack_id .. "/" .. _data.id
                    local _record_path =
                        "conf.d/" ..
                        _record.routing_type .. ".d/" .. _data.user_id .. "/" .. _data.stack_id .. "/" .. _data.id
                    for _id, _content in pairs(_monitors_tmpl) do
                        _files[_monitor_path .. "/" .. _id] = _content
                    end
                    for _id, _content in pairs(_records_tmpl) do
                        _files[_record_path .. "/" .. _id] = _content
                    end
                end
            end
            _files["zones/" .. _data.domain] = _zones_tmpl

            ngx.log(ngx.ERR, cjson.encode(_files))
            for _path, _content in pairs(_files) do
                if type(_content) == "string" then
                    _write_file(_dir .. "/" .. _path, _content)
                else
                    _write_file(_dir .. "/" .. _path, table.concat(_content, "\n"))
                end
            end
        end
        local _tmp_records = table.concat(_record_list, " ")
        local _cmd =
            table.concat(
            {
                ngx.var.site_root .. "/services/dns/run commit",
                _data.domain,
                _data.user_id,
                _data.stack_id,
                _data.id,
                _tmp_records
            },
            " "
        )
        ngx.log(ngx.ERR, _cmd)
        _run_shell(_cmd)
    end
end
_M.showFolder = showFolder
_M.getIdByType = getIdByType

return _M
