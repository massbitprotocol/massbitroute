local User = cc.class("Api")
local json = cc.import("#json")
local crypto = require "crypto"
local objectid = require "objectid"

local model_type = "api"
local model_id = 2000
local Model = cc.import("#model")
local uuid = require "jit-uuid"
local util = require "util"
local mkdirp = require "mkdirp"
local shell = require "resty.shell"
local inspect = require "inspect"

local CodeGen = require "CodeGen"
local PROVIDERS = {
    CUSTOM = 1,
    GETBLOCK = 2,
    QUICKNODE = 3,
    INFURA = 4
}

local rules = {
    _upstream = [[ 
 server unix:/tmp/${api_key}-${provider_id}.sock;
]],
    _upstreams = [[
upstream upstream_${api_key} {
    ${entrypoints/_upstream()}
    keepalive 32;
}
]],
    _server_main = [[
server {
    listen 80;
    listen 443 ssl;
    ssl_certificate /etc/letsencrypt/live/${blockchain}-${network}.massbitroute.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/${blockchain}-${network}.massbitroute.com/privkey.pem;
    resolver 8.8.4.4 ipv6=off;
    client_body_buffer_size 512K;
    client_max_body_size 1G;
    server_name ${gateway_domain};
    access_log /massbit/massbitroute/app/src/sites/services/gateway/logs/nginx-${gateway_domain}-access.log main_json;
    error_log /massbit/massbitroute/app/src/sites/services/gateway/logs/nginx-${gateway_domain}-error.log debug;
    location /${api_key} {
        rewrite /(.*) / break;
        proxy_cache_use_stale updating error timeout invalid_header http_500 http_502 http_503 http_504;
        proxy_next_upstream error timeout invalid_header http_500 http_502 http_503 http_504;
        proxy_connect_timeout 10s;
        proxy_cache_methods GET HEAD POST;
        proxy_cache_key $request_uri|$request_body;
        proxy_cache_min_uses 1;
        proxy_cache cache;
        proxy_cache_valid 200 3s;
        proxy_cache_background_update on;
        add_header X-Cached $upstream_cache_status;
        proxy_ssl_verify off;
        proxy_pass http://upstream_${api_key}/;

        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection $connection_upgrade;
    }
}
]],
    _server_backend_INFURA = [[
server {
    listen unix:/tmp/${api_key}-${provider_id}.sock;
    location / {
        proxy_redirect off;
        set_encode_base64 $digest :${infura_project_secret};
        proxy_set_header Authorization 'Basic $digest';
        proxy_ssl_verify off;
        proxy_ssl_server_name on;
        proxy_pass https://mainnet.infura.io/v3/${infura_project_id};
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection $connection_upgrade;
    }
}
]],
    _server_backend_QUICKNODE = [[
server {
    listen unix:/tmp/${api_key}-${provider_id}.sock;
    location / {
        proxy_redirect off;
        proxy_ssl_server_name on;
        proxy_pass ${quicknode_api_uri};
        proxy_http_version 1.1;
        proxy_ssl_verify off;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection $connection_upgrade;
    }
}
]],
    _server_backend_CUSTOM = [[
server {
    listen unix:/tmp/${api_key}-${provider_id}.sock;
    location / {
        proxy_redirect off;
        proxy_ssl_server_name on;
        proxy_pass ${custom_api_uri};
        proxy_http_version 1.1;
        proxy_ssl_verify off;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection $connection_upgrade;
    }
}
]],
    _server_backend_GETBLOCK = [[
server {
    listen unix:/tmp/${api_key}-${provider_id}.sock;
    location / {
        proxy_redirect off;
        proxy_ssl_server_name on;
        proxy_set_header X-Api-Key ${getblock_api_key};
        proxy_set_header Host ${blockchain}.getblock.io;
        proxy_pass https://${blockchain}.getblock.io/${network}/;
        proxy_ssl_verify off;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection $connection_upgrade;
    }
}
]]
}

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

local function _get_tmpl(rules, _data)
    local _rules = table.copy(rules)
    table.merge(_rules, _data)
    return CodeGen(_rules)
end
local function dirname(str)
    if str:match(".-/.-") then
        local name = string.gsub(str, "(.*/)(.*)", "%1")
        return name
    else
        return ""
    end
end

local function _write_file(_filepath, content)
    ngx.log(ngx.ERR, "write_file")
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

local function _write_template(_files)
    ngx.log(ngx.ERR, "write_template")
    -- _tmpl("_domain")
    -- _files["zones/" .. _data.domain] = _zones_tmpl
    for _path, _content in pairs(_files) do
        ngx.log(ngx.ERR, "_path:" .. _path)
        ngx.log(ngx.ERR, "_content .. " .. json.encode(_content))
        if type(_content) == "string" then
            _write_file(_path, _content)
        else
            _write_file(_path, table.concat(_content, "\n"))
        end
    end
end

function User:ctor(instance)
    self._instance = instance
    self._redis = instance:getRedis()
    self._model = Model:new(instance)
end
function User:create(args)
    local user_id = args.user_id
    args.id = objectid.generate_id(model_id)
    local _now = ngx and ngx.time() or os.time()
    uuid.seed(_now)
    args.api_key = uuid()
    args.status = 1
    args.api_id = util.randomString(12)
    if args.blockchain and args.network then
        args.gateway_domain = args.api_id .. "." .. args.blockchain .. "-" .. args.network .. ".massbitroute.com"
        args.gateway_url = args.gateway_domain .. "/" .. args.api_key .. "/"
        args.gateway_http = "https://" .. args.gateway_url
        args.gateway_wss = "wss://" .. args.gateway_url
    end

    args.created_at = now

    self._model:_save_key(user_id .. ":" .. model_type, {[args.id] = json.encode(args)})
    -- self._model:_save_key(model_type .. ":" .. model_type, {[args.domain] = args.id})
    return args
end

function User:update(args)
    local user_id = args.user_id
    local _detail = self._model:_get_key(user_id .. ":" .. model_type, args.id)

    if _detail then
        _detail = json.decode(_detail)
        ngx.log(ngx.ERR, json.encode(_detail))
        -- if _detail.domain ~= args.domain then
        --     self._model:_del_key(model_type .. ":" .. model_type, _detail.domain)
        --     self._model:_save_key(model_type .. ":" .. model_type, {[args.domain] = args.id})
        -- end
        table.merge(_detail, args)
        self._model:_save_key(user_id .. ":" .. model_type, {[_detail.id] = json.encode(_detail)})
        -- _gen_template(args)
        local _files = {}
        ngx.log(ngx.ERR, json.encode(args))
        if args.entrypoints and type(args.entrypoints) == "string" then
            args.entrypoints = json.decode(args.entrypoints)
        end
        local _content = {}

        if args.entrypoints and #args.entrypoints > 0 then
            local _entrypoints =
                table.map(
                args.entrypoints,
                function(_ent, _idx)
                    _ent.provider_id = PROVIDERS[_ent.type] .. "_" .. _idx
                    _ent.api_key = args.api_key
                    _ent.blockchain = args.blockchain
                    _ent.network = args.network
                    local _tmpl = _get_tmpl(rules, _ent)
                    local _str_tmpl = _tmpl("_server_backend_" .. _ent.type)
                    ngx.log(ngx.ERR, _str_tmpl)
                    _content[#_content + 1] = _str_tmpl
                    ngx.log(ngx.ERR, json.encode(_ent))
                    return _ent
                end
            )

            local _tmpl = _get_tmpl(rules, {api_key = args.api_key, entrypoints = _entrypoints})
            local _str_tmpl = _tmpl("_upstreams")

            ngx.log(ngx.ERR, _str_tmpl)
            _content[#_content + 1] = _str_tmpl
            local _tmpl = _get_tmpl(rules, args)
            local _str_tmpl = _tmpl("_server_main")
            _content[#_content + 1] = _str_tmpl
            ngx.log(ngx.ERR, _str_tmpl)
            local _conf_file =
                "/massbit/massbitroute/app/src/sites/services/gateway/conf.d/" ..
                args.user_id .. "/" .. args.id .. "/server.conf"
            _write_template(
                {
                    [_conf_file] = _content
                }
            )

            local _ok = _run_shell("/massbit/massbitroute/app/src/cmd_server nginx -t")
            if not _ok then
                os.remove(_conf_file)
            else
                _run_shell("/massbit/massbitroute/app/src/cmd_server nginx -s reload")
            end
        end

    -- local _tmpl = _get_tmpl(rules, args)
    end

    return _detail
end
function User:delete(args)
    local user_id = args.user_id
    self._model:_del_key(user_id .. ":" .. model_type, args.id)
    -- self._model:_del_key(user_id .. ":" ..  model_type .. ":" .. model_type, args.domain)
    return args
end

function User:list(args)
    local user_id = args.user_id
    local _res = self._model:_getall_key(user_id .. ":" .. model_type)
    return _res
end

return User
