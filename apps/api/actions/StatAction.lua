local mytype = "stat"
local gbc = cc.import("#gbc")
local json = cc.import("#json")

local Action = cc.class(mytype .. "Action", gbc.ActionBase)

local inspect = require "inspect"

local httpc = require("resty.http").new()

local _cache_ttl = 60
local _cache = ngx.shared.portal_stats

local function _get_cache(_key, _data)
    local _ret = _cache:get(_key)
    if not _ret then
        _ret = _data
        _cache:set(_key, json.encode(_ret), _cache_ttl)
    else
        _ret = json.decode(_ret)
    end
    return _ret
end

local _countries = {
    {
        country_name = "Denmark",
        country_code = "DK",
        longitude = 9.501785,
        latitude = 56.26392,
        value = 4
    },
    {
        country_name = "Spain",
        country_code = "ES",
        longitude = 3.74922,
        latitude = 40.463667,
        value = 12
    },
    {
        country_name = "France",
        country_code = "FR",
        longitude = 2.213749,
        latitude = 46.227638,
        value = 33
    },
    {
        country_name = "United Kingdom",
        country_code = "GB",
        longitude = -3.435973,
        latitude = 55.378051,
        value = 9
    },
    {
        country_name = "Hungary",
        country_code = "HU",
        longitude = 19.503304,
        latitude = 47.162494,
        value = 11
    },
    {
        country_name = "Israel",
        country_code = "IL",
        longitude = 34.851612,
        latitude = 31.046051,
        value = 18
    },
    {
        country_name = "India",
        country_code = "IN",
        longitude = 78.96288,
        latitude = 20.593684,
        value = 13
    },
    {
        country_name = "Japan",
        country_code = "JP",
        longitude = 138.252924,
        latitude = 36.204824,
        value = 7
    },
    {
        country_name = "South Korea",
        country_code = "KR",
        longitude = 127.766922,
        latitude = 35.907757,
        value = 7
    },
    {
        country_name = "Philippines",
        country_code = "PH",
        longitude = 121.774017,
        latitude = 12.879721,
        value = 31
    },
    {
        country_name = "Russia",
        country_code = "RU",
        longitude = 105.318756,
        latitude = 61.52401,
        value = 23
    },
    {
        country_name = "Thailand",
        country_code = "TH",
        longitude = 100.992541,
        latitude = 15.870032,
        value = 14
    },
    {
        country_name = "Vietnam",
        country_code = "VN",
        longitude = 108.277199,
        latitude = 14.058324,
        value = 32
    },
    {
        country_name = "Sweden",
        country_code = "SE",
        longitude = 18.643501,
        latitude = 60.128161,
        value = 6
    },
    {
        country_name = "Australia",
        country_code = "AU",
        longitude = 133.775136,
        latitude = -25.274398,
        value = 9
    },
    {
        country_name = "Canada",
        country_code = "CA",
        longitude = -106.346771,
        latitude = 56.130366,
        value = 11
    },
    {
        country_name = "Indonesia",
        country_code = "ID",
        longitude = 113.921327,
        latitude = -0.789275,
        value = 22
    }
}
local function _get_nodes(_red, _type)
    local _nodes_count = {}
    local _nodes_info = {}
    local _items = _red:keys("*:" .. _type)
    for _, _k in ipairs(_items) do
        local _arr = _red:arrayToHash(_red:hgetall(_k))
        for _, _str in pairs(_arr) do
            local _node = json.decode(_str)
            if tonumber(_node.status) == 1 then
                if _node.geo and _node.geo.country_code then
                    if not _nodes_info[_node.geo.country_code] then
                        _nodes_info[_node.geo.country_code] = {
                            country_name = _node.geo.country_name,
                            country_code = _node.geo.country_code,
                            longitude = _node.geo.longitude,
                            latitude = _node.geo.latitude
                        }
                    end

                    _nodes_count[_node.geo.country_code] =
                        _nodes_count[_node.geo.country_code] and _nodes_count[_node.geo.country_code] + 1 or 1
                end
            end
        end
    end
    local _ret = {}
    for k, v in pairs(_nodes_count) do
        local _t = _nodes_info[k]
        _t.value = v
        _ret[#_ret + 1] = _t
    end

    for _i = 1, 20 do
        math.randomseed(os.clock() * 100000000000)
        local _ct = _countries[math.random(#_countries)]
        _ct.value = math.random(5, 40)
        table.insert(_ret, _ct)
    end

    return _ret
end

local function _get_nodes_count(_red, _type)
    local _nodes_count = 0
    local _items = _red:keys("*:" .. _type)
    for _, _k in ipairs(_items) do
        local _arr = _red:arrayToHash(_red:hgetall(_k))
        for _, _str in pairs(_arr) do
            local _node = json.decode(_str)
            if tonumber(_node.status) == 1 then
                _nodes_count = _nodes_count + 1
            end
        end
    end
    return _nodes_count
end

function Action:networkAction(args)
    local instance = self:getInstance()
    local _red = instance:getRedis()
    local _nodes = _get_nodes(_red, "node")
    local _gateways = _get_nodes(_red, "gateway")
    return {
        result = true,
        data = _get_cache(
            "portal_stats_network",
            {
                nodes = _nodes,
                gateways = _gateways
            }
        )
    }
end

function Action:overviewAction(args)
    local instance = self:getInstance()
    local _red = instance:getRedis()

    return {
        result = true,
        data = _get_cache(
            "portal_stats_overview",
            {
                dapi = {
                    value = 2134,
                    --_get_nodes_count(_red, "api"),
                    percent = 8.4
                },
                gateway = {
                    value = 617,
                    --_get_nodes_count(_red, "gateway"),
                    percent = 4.4
                },
                node = {
                    value = 101,
                    --_get_nodes_count(_red, "node"),
                    percent = 10
                }
            }
        )
    }
end

local function _stat_get(_proxy_id, _req_body, _field, _server_name)

    local _url =
        "https://stat.mbr." .. _server_name .. "/__internal_grafana/api/datasources/proxy/" .. _proxy_id .. "/api/v1/series"
    local _res, _err =
        httpc:request_uri(
        _url,
        {
            ssl_verify = false,
            method = "POST",
            body = _req_body,
            headers = {
                ["Content-Type"] = "application/x-www-form-urlencoded",
                ["x-grafana-org-id"] = 1
            }
        }
    )
    ngx.log(ngx.ERR, inspect(_req_body))
    ngx.log(ngx.ERR, inspect(_err))

    local _body = _res.body
    if _body and type(_body) == "string" then
        _body = json.decode(_body)
    end
    local _data = _body.data
    ngx.log(ngx.ERR, inspect(_data))
    local _ret = {}
    table.walk(
        _data,
        function(_v)
            _ret[_v[_field]] = 1
        end
    )
    return table.keys(_ret)
end

function Action:getinstanceAction(args)
    local _config = self:getInstanceConfig()
    local _server_name = _config.app.server_name or "massbitroute.com"
    local _instances = _stat_get(1, "match[]=nginx_vts_server_bytes_total", "instance", _server_name)
    _instances =
        table.concat(
        _instances -- ), --     end --         return _v:gsub("%.", "\\\\.") --     function(_v) --     _instances, -- table.map(
        "|"
    )
    -- local _filters = _stat_get(1, 'match[]=nginx_vts_server_bytes_total{instance=~"(' .. _instances .. ')"}', "filter")
    -- local _instances =
    --     _stat_get(
    --     1,
    --     'match[]=nginx_vts_filter_requests_total{instance=~"(0690da91-c7f1-4233-ad1e-31ee7e913721\\.gw\\.mbr\\.massbitroute\\.com:80|28829073-4715-49eb-aeef-0f6834062881\\.gw\\.mbr\\.massbitroute\\.com:80|3a2187e4-45b8-491f-be6a-d4222ee80e72\\.gw\\.mbr\\.massbitroute\\.com:80|88642bb8-e4b6-4caf-afe0-6461140fd2db\\.gw\\.mbr\\.massbitroute\\.com:80|e577b6d6-a4b5-40b5-8f84-21b81311bc27\\.gw\\.mbr\\.massbitroute\\.com:80)"}'
    -- )
    return {s = _instances}
end

function Action:dapiAction(args)
    local _from_date = args.fromDate
    local _to_date = args.toDate
    if not _from_date or not _to_date then
        return {
            result = false,
            err = "Invalid params"
        }
    end
    local year1, month1, day1 = _from_date:match("^(%d%d%d%d)%-(%d%d)%-(%d%d)")
    local year2, month2, day2 = _to_date:match("^(%d%d%d%d)%-(%d%d)%-(%d%d)")

    local _fdate = os.time({year = year1, month = month1, day = day1})
    local _tdate = os.time({year = year2, month = month2, day = day2})
    local _reqs = {}
    local _band = {}
    local _cur = _fdate
    -- math.randomseed(os.clock() * 100000000000)

    local _reqs_total = 0
    local _band_total = 0
    while _cur <= _tdate do
        math.randomseed(os.clock() * 100000000000)
        local _val = math.random(180000, 192000)
        local _date = os.date("%Y-%m-%d", _cur)
        _reqs_total = _reqs_total + _val
        local _val1 = _val * 512000
        _band_total = _band_total + _val1
        _reqs[#_reqs + 1] = {
            date = _date,
            value = _val
        }
        _band[#_band + 1] = {
            date = _date,
            value = _val1
        }
        _cur = _cur + 86400
    end

    return {
        result = true,
        data = {
            requests = {
                total = _reqs_total,
                data = _reqs
            },
            bandwidth = {
                total = _band_total,
                data = _band
            }
        }
    }
end

return Action
