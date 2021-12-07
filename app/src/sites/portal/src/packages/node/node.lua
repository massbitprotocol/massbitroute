local ngx, cc = ngx, cc
local Node = cc.class("Node")
local json = cc.import("#json")
-- local crypto = require "crypto"
-- local objectid = require "objectid"
-- local resty_string = require "resty.string"
-- local resty_md5 = require "resty.md5"

local model_type = "node"

-- local model_id = 3000

local Model = cc.import("#model")
local uuid = require "jit-uuid"
-- local util = require "util"
-- local mkdirp = require "mkdirp"
-- local shell = require "resty.shell"
local inspect = require "inspect"

-- local CodeGen = require "CodeGen"
-- local PROVIDERS = {
--     MASSBIT = 0,
--     CUSTOM = 1,
--     GETBLOCK = 2,
--     QUICKNODE = 3,
--     INFURA = 4
-- }

-- local rules = {
--     _upstream = [[server unix:/tmp/${server_name}.sock;]],
--     _upstreams = [[
-- upstream upstream_${api_key} {
--     ${entrypoints/_upstream()}
--     keepalive 32;
-- }
-- ]],
--     _api_method = [[
--         set $api_method '';
--         access_by_lua_file /massbit/massbitroute/app/src/sites/services/gateway/src/jsonrpc-access.lua;
--         vhost_traffic_status_filter_by_set_key $api_method ${server_name}::api_method;
-- ]],
--     _allow_methods1 = [[set $jsonrpc_whitelist '${security.allow_methods}';]],
--     _limit_rate_per_sec2 = [[limit_req zone=${api_key};]],
--     _limit_rate_per_sec1 = [[limit_req_zone $binary_remote_addr zone=${api_key}:10m rate=${security.limit_rate_per_sec}r/s;]],
--     _server_main = [[
-- ${security._is_limit_rate_per_sec?_limit_rate_per_sec1()}

-- server {
--     listen 80;
--     listen 443 ssl;
--     ssl_certificate /etc/letsencrypt/live/${blockchain}-${network}.massbitroute.com/fullchain.pem;
--     ssl_certificate_key /etc/letsencrypt/live/${blockchain}-${network}.massbitroute.com/privkey.pem;
--     resolver 8.8.4.4 ipv6=off;
--     client_body_buffer_size 512K;
--     client_max_body_size 1G;
--     server_name ${gateway_domain};
--     access_log /massbit/massbitroute/app/src/sites/services/gateway/logs/nginx-${gateway_domain}-access.log main_json;
--     error_log /massbit/massbitroute/app/src/sites/services/gateway/logs/nginx-${gateway_domain}-error.log debug;

--     location /${api_key} {
--         rewrite /(.*) / break;
--         ${security._is_limit_rate_per_sec?_limit_rate_per_sec2()}
--         ${_allow_methods1()}
--         set $api_method '';
--         access_by_lua_file /massbit/massbitroute/app/src/sites/services/gateway/src/filter-jsonrpc-access.lua;
--         vhost_traffic_status_filter_by_set_key $api_method ${api_key}::api_method;

--         proxy_cache_use_stale updating error timeout invalid_header http_500 http_502 http_503 http_504;
--         proxy_next_upstream error timeout invalid_header http_500 http_502 http_503 http_504;
--         proxy_connect_timeout 10s;
--         proxy_cache_methods GET HEAD POST;
--         proxy_cache_key $request_uri|$request_body;
--         proxy_cache_min_uses 1;
--         proxy_cache cache;
--         proxy_cache_valid 200 3s;
--         proxy_cache_background_update on;
--         add_header X-Cached $upstream_cache_status;
--         proxy_ssl_verify off;
--         proxy_pass http://upstream_${api_key}/;

--         proxy_http_version 1.1;
--         proxy_set_header Upgrade $http_upgrade;
--         proxy_set_header Connection $connection_upgrade;
-- #      proxy_set_header X-Real-IP $remote_addr;
-- #      proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
-- # proxy_set_header Host $http_host;
--     }
-- }
-- ]],
--     _server_backend_INFURA = [[
-- server {
--     listen unix:/tmp/${server_name}.sock;
--     location / {
--        ${_api_method()}
--         proxy_redirect off;
--         set_encode_base64 $digest :${infura_project_secret};
--         proxy_set_header Authorization 'Basic $digest';
--         proxy_ssl_verify off;
--         proxy_ssl_server_name on;
--         proxy_pass https://mainnet.infura.io/v3/${infura_project_id};
--         proxy_http_version 1.1;
--         proxy_set_header Upgrade $http_upgrade;
--         proxy_set_header Connection $connection_upgrade;
--     }
-- }
-- ]],
--     _server_backend_QUICKNODE = [[
-- server {
--     listen unix:/tmp/${server_name}.sock;
--     location / {
--        ${_api_method()}
--         proxy_redirect off;
--         proxy_ssl_server_name on;
--         proxy_pass ${quicknode_api_uri};
--         proxy_http_version 1.1;
--         proxy_ssl_verify off;
--         proxy_set_header Upgrade $http_upgrade;
--         proxy_set_header Connection $connection_upgrade;
--     }
-- }
-- ]],
--     _server_backend_CUSTOM = [[
-- server {
--     listen unix:/tmp/${server_name}.sock;
--     location / {
--        ${_api_method()}
--         proxy_redirect off;
--         proxy_ssl_server_name on;
--         proxy_pass ${custom_api_uri};
--         proxy_http_version 1.1;
--         proxy_ssl_verify off;
--         proxy_set_header Upgrade $http_upgrade;
--         proxy_set_header Connection $connection_upgrade;
--     }
-- }
-- ]],
--     _server_backend_GETBLOCK = [[
-- server {
--     listen unix:/tmp/${server_name}.sock;
--     location / {
--        ${_api_method()}
--         proxy_redirect off;
--         proxy_ssl_server_name on;
--         proxy_set_header X-Api-Key ${getblock_api_key};
--         proxy_set_header Host ${blockchain}.getblock.io;
--         proxy_pass https://${blockchain}.getblock.io/${network}/;
--         proxy_ssl_verify off;
--         proxy_http_version 1.1;
--         proxy_set_header Upgrade $http_upgrade;
--         proxy_set_header Connection $connection_upgrade;
--     }
-- }
-- ]],
--     _server_backend_MASSBIT = [[
-- server {
--     listen unix:/tmp/${server_name}.sock;
--     location / {
--        ${_api_method()}
--         proxy_redirect off;
--         proxy_ssl_server_name on;
--         proxy_pass http://${blockchain}-${network}.node.mbr.massbitroute.com;
--         proxy_ssl_verify off;
--         proxy_http_version 1.1;
--         proxy_set_header Upgrade $http_upgrade;
--         proxy_set_header Connection $connection_upgrade;
--     }
-- }
-- ]]
-- }

-- local function _run_shell(cmd)
--     ngx.log(ngx.ERR, inspect(cmd))
--     local stdin = ""
--     local timeout = 300000 -- ms
--     local max_size = 409600 -- byte
--     local ok, stdout, stderr, reason, status = shell.run(cmd, stdin, timeout, max_size)
--     ngx.log(ngx.ERR, inspect(ok))
--     ngx.log(ngx.ERR, inspect(stdout))
--     ngx.log(ngx.ERR, inspect(stderr))
--     return ok, stdout, stderr, reason, status
-- end

-- local function _get_tmpl(_rules, _data)
--     local _rules1 = table.copy(_rules)
--     table.merge(_rules1, _data)
--     return CodeGen(_rules1)
-- end

-- local function dirname(str)
--     if str:match(".-/.-") then
--         local name = string.gsub(str, "(.*/)(.*)", "%1")
--         return name
--     else
--         return ""
--     end
-- end

-- local function _write_file(_filepath, content)
--     ngx.log(ngx.ERR, "write_file")
--     if _filepath then
--         mkdirp(dirname(_filepath))
--         ngx.log(ngx.ERR, "write_file:" .. _filepath)
--         ngx.log(ngx.ERR, content)
--         local _file, _ = io.open(_filepath, "w+")
--         if _file ~= nil then
--             _file:write(content)
--             _file:close()
--         end
--     end
-- end

-- local function _write_template(_files)
--     ngx.log(ngx.ERR, "write_template")
--     -- _tmpl("_domain")
--     -- _files["zones/" .. _data.domain] = _zones_tmpl
--     for _path, _content in pairs(_files) do
--         ngx.log(ngx.ERR, "_path:" .. _path)
--         ngx.log(ngx.ERR, "_content .. " .. json.encode(_content))
--         if type(_content) == "string" then
--             _write_file(_path, _content)
--         else
--             _write_file(_path, table.concat(_content, "\n"))
--         end
--     end
-- end

function Node:ctor(instance)
    self._instance = instance
    self._redis = instance:getRedis()
    self._model = Model:new(instance)
end
function Node:create(args)
    local user_id = args.user_id
    --    args.id = objectid.generate_id(model_id)
    local _now = ngx and ngx.time() or os.time()
    uuid.seed(_now)

    args.status = 0
    args.id = uuid()
    -- args.auth_id = util.randomString(12)
    -- args.node_id = uuid()
    -- if args.blockchain and args.network then
    -- args.gateway_domain = args.api_id .. "." .. args.blockchain .. "-" .. args.network .. ".massbitroute.com"
    -- args.gateway_url = args.gateway_domain .. "/" .. args.api_key .. "/"
    -- args.gateway_http = "https://" .. args.gateway_url
    -- args.gateway_wss = "wss://" .. args.gateway_url
    -- end

    args.created_at = _now

    self._model:_save_key(user_id .. ":" .. model_type, {[args.id] = json.encode(args)})
    -- self._model:_save_key(model_type .. ":" .. model_type, {[args.domain] = args.id})
    return args
end

function Node:update(args)
    local user_id = args.user_id
    local id = args.id
    local _detail = self._model:_get_key(user_id .. ":" .. model_type, id)

    if _detail then
        -- _gen_template(args)
        -- local _files = {}
        -- if args.entrypoints and type(args.entrypoints) == "string" then
        --     args.entrypoints = json.decode(args.entrypoints)
        -- end
        -- if args.security and type(args.security) == "string" then
        --     args.security = json.decode(args.security)
        --     if
        --         args.security.limit_rate_per_sec and type(args.security.limit_rate_per_sec) == "string" and
        --             string.len(args.security.limit_rate_per_sec) == 0
        --      then
        --         args.security.limit_rate_per_sec = 100
        --     end
        -- end
        -- ngx.log(ngx.ERR, inspect(args))
        -- local _content = {}
        -- if args.entrypoints and #args.entrypoints > 0 then
        --     local _entrypoints =
        --         table.map(
        --         args.entrypoints,
        --         function(_ent)
        --             _ent.provider_id = PROVIDERS[_ent.type] .. "-" .. _ent.id
        --             _ent.api_key = args.api_key
        --             _ent.server_name = args.api_key .. "-" .. _ent.provider_id
        --             _ent.blockchain = args.blockchain
        --             _ent.network = args.network
        --             local _tmpl = _get_tmpl(rules, _ent)
        --             local _str_tmpl = _tmpl("_server_backend_" .. _ent.type)
        --             ngx.log(ngx.ERR, _str_tmpl)
        --             _content[#_content + 1] = _str_tmpl
        --             ngx.log(ngx.ERR, json.encode(_ent))
        --             return _ent
        --         end
        --     )
        --     local _tmpl = _get_tmpl(rules, {api_key = args.api_key, entrypoints = _entrypoints})
        --     local _str_tmpl = _tmpl("_upstreams")
        --     ngx.log(ngx.ERR, inspect(_str_tmpl))
        --     if args.security.limit_rate_per_sec and tonumber(args.security.limit_rate_per_sec) > 0 then
        --         args.security._is_limit_rate_per_sec = true
        --     end
        --     if args.security.allow_methods and string.len(args.security.allow_methods) > 0 then
        --         args.security._is_allow_methods = true
        --     end
        --     -- ngx.log(ngx.ERR, inspect(args))
        --     -- ngx.log(ngx.ERR, _str_tmpl)
        --     _content[#_content + 1] = _str_tmpl
        --     local _tmpl = _get_tmpl(rules, args)
        --     local _str_tmpl = _tmpl("_server_main")
        --     _content[#_content + 1] = _str_tmpl
        --     ngx.log(ngx.ERR, _str_tmpl)
        --     local _conf_file =
        --         "/massbit/massbitroute/app/src/sites/services/gateway/conf.d/" ..
        --         args.user_id .. "/" .. args.id .. "/server.conf"
        --     ngx.log(ngx.ERR, _conf_file)
        --     _write_template(
        --         {
        --             [_conf_file] = _content
        --         }
        --     )
        --     local _ok = _run_shell("/massbit/massbitroute/app/src/cmd_server nginx -t")
        --     if not _ok then
        --         os.remove(_conf_file)
        --     else
        --         _run_shell("/massbit/massbitroute/app/src/sites/services/gateway/scripts/run _commit " .. _conf_file)
        --     end
        -- end
        -- local _tmpl = _get_tmpl(rules, args)
        _detail = json.decode(_detail)
        ngx.log(ngx.ERR, inspect(_detail))
        -- if _detail.domain ~= args.domain then
        --     self._model:_del_key(model_type .. ":" .. model_type, _detail.domain)
        --     self._model:_save_key(model_type .. ":" .. model_type, {[args.domain] = args.id})
        -- end
        table.merge(_detail, args)
        local _now = ngx and ngx.time() or os.time()
        _detail.updated_at = _now
        self._model:_save_key(user_id .. ":" .. model_type, {[_detail.id] = json.encode(_detail)})
    else
        ngx.log(ngx.ERR, "gateway:" .. id .. " not found")
    end

    return _detail
end
function Node:delete(args)
    local user_id = args.user_id
    self._model:_del_key(user_id .. ":" .. model_type, args.id)
    -- local _conf_file =
    --     "/massbit/massbitroute/app/src/sites/services/gateway/conf.d/" ..
    --     args.user_id .. "/" .. args.id .. "/server.conf"

    -- _run_shell("/massbit/massbitroute/app/src/sites/services/gateway/scripts/run _remove " .. _conf_file)
    -- self._model:_del_key(user_id .. ":" ..  model_type .. ":" .. model_type, args.domain)
    return args
end

function Node:list(args)
    local user_id = args.user_id
    local _res = self._model:_getall_key(user_id .. ":" .. model_type)
    return _res
end
function Node:get(args)
    local user_id = args.user_id
    local _detail = self._model:_get_key(user_id .. ":" .. model_type, args.id)
    return _detail
end

return Node
