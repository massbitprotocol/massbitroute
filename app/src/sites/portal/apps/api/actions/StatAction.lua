local mytype = "stat"
local gbc = cc.import("#gbc")
local json = cc.import("#json")

local Action = cc.class(mytype .. "Action", gbc.ActionBase)

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
                    value = _get_nodes_count(_red, "api"),
                    percent = 8.4
                },
                gateway = {
                    value = _get_nodes_count(_red, "gateway"),
                    percent = 4.4
                },
                node = {
                    value = _get_nodes_count(_red, "node"),
                    percent = 10
                }
            }
        )
    }
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
    math.randomseed(os.clock() * 100000000000)

    local _reqs_total = 0
    local _band_total = 0
    while _cur <= _tdate do
        local _val = math.random(10000, 65000)
        local _date = os.date("%Y-%m-%d", _cur)
        _reqs_total = _reqs_total + _val
        local _val1 = _val * 256000
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
