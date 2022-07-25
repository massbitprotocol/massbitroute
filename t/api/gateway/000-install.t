use Test::Nginx::Socket::Lua 'no_plan';

repeat_each(1);

no_shuffle();

# plan tests => blocks() * repeat_each() * 2;

$ENV{TEST_NGINX_BINARY} =
"/massbit/massbitroute/app/src/sites/services/api/bin/openresty/nginx/sbin/nginx";
our $main_config = <<'_EOC_';
      load_module /massbit/massbitroute/app/src/sites/services/api/bin/openresty/nginx/modules/ngx_http_geoip2_module.so;
      load_module /massbit/massbitroute/app/src/sites/services/api/bin/openresty/nginx/modules/ngx_stream_geoip2_module.so;
      load_module /massbit/massbitroute/app/src/sites/services/api/bin/openresty/nginx/modules/ngx_http_vhost_traffic_status_module.so;
      load_module /massbit/massbitroute/app/src/sites/services/api/bin/openresty/nginx/modules/ngx_http_stream_server_traffic_status_module.so;
      load_module /massbit/massbitroute/app/src/sites/services/api/bin/openresty/nginx/modules/ngx_stream_server_traffic_status_module.so;
	

env BIND_ADDRESS;
_EOC_

our $http_config = <<'_EOC_';

log_format main_json escape=json '{' '"msec": "$msec", ' '"connection": "$connection", ' '"connection_requests": "$connection_requests", ' '"pid": "$pid", ' '"request_id": "$request_id", ' '"request_length": "$request_length", ' '"remote_addr": "$remote_addr", ' '"remote_user": "$remote_user", ' '"remote_port": "$remote_port", ' '"time_local": "$time_local", ' '"time_iso8601": "$time_iso8601", ' '"request": "$request", ' '"request_uri": "$request_uri", ' '"args": "$args", ' '"status": "$status", ' '"body_bytes_sent": "$body_bytes_sent", ' '"bytes_sent": "$bytes_sent", ' '"http_referer": "$http_referer", ' '"http_user_agent": "$http_user_agent", ' '"http_x_forwarded_for": "$http_x_forwarded_for", ' '"http_host": "$http_host", ' '"server_name": "$server_name", ' '"request_time": "$request_time", ' '"upstream": "$upstream_addr", ' '"upstream_connect_time": "$upstream_connect_time", ' '"upstream_header_time": "$upstream_header_time", ' '"upstream_response_time": "$upstream_response_time", ' '"upstream_response_length": "$upstream_response_length", ' '"upstream_cache_status": "$upstream_cache_status", ' '"ssl_protocol": "$ssl_protocol", ' '"ssl_cipher": "$ssl_cipher", ' '"scheme": "$scheme", ' '"request_method": "$request_method", ' '"server_protocol": "$server_protocol", ' '"pipe": "$pipe", ' '"gzip_ratio": "$gzip_ratio", ' '"request_body": "$request_body", ' '"http_cf_ray": "$http_cf_ray"' '"real_ip": "$http_x_forwarded_for",' '}';
    lua_package_path '/massbit/massbitroute/app/src/sites/services/api/gbc/src/?.lua;/massbit/massbitroute/app/src/sites/services/api/lib/?.lua;/massbit/massbitroute/app/src/sites/services/api/src/?.lua;/massbit/massbitroute/app/src/sites/services/api/sites/../src/?.lua/massbit/massbitroute/app/src/sites/services/api/sites/../lib/?.lua;/massbit/massbitroute/app/src/sites/services/api/sites/../src/?.lua;/massbit/massbitroute/app/src/sites/services/api/bin/openresty/site/lualib/?.lua;;';
    lua_package_cpath '/massbit/massbitroute/app/src/sites/services/api/gbc/src/?.so;/massbit/massbitroute/app/src/sites/services/api/lib/?.so;/massbit/massbitroute/app/src/sites/services/api/src/?.so;/massbit/massbitroute/app/src/sites/services/api/sites/../src/?.so/massbit/massbitroute/app/src/sites/services/api/sites/../lib/?.so;/massbit/massbitroute/app/src/sites/services/api/sites/../src/?.so;/massbit/massbitroute/app/src/sites/services/api/bin/openresty/site/lualib/?.so;;';
                   

#_INCLUDE_SITES_HTTPINIT_
    init_by_lua '\n    
	   require("framework.init")
	   local appKeys = dofile("/massbit/massbitroute/app/src/sites/services/api/tmp/app_keys.lua")
	   local globalConfig = dofile("/massbit/massbitroute/app/src/sites/services/api/tmp/config.lua")
	   cc.DEBUG = globalConfig.DEBUG
	   local gbc = cc.import("#gbc")
	   cc.exports.nginxBootstrap = gbc.NginxBootstrap:new(appKeys, globalConfig)
        
';
lua_shared_dict portal_stats 10m;
_EOC_

run_tests();

__DATA__
=== TEST 1: api test
--- main_config eval: $::main_config
--- http_config eval: $::http_config

--- config 
 

    set $namespace massbitroute.net_admin;
    set $site_root /massbit/massbitroute/app/src/sites/services/api/sites/..;
    set $server_root /massbit/massbitroute/app/src/sites/services/api;
    set $redis_sock /massbit/massbitroute/app/src/sites/services/api/tmp/redis.sock;

    root /massbit/massbitroute/app/src/sites/services/api/sites/../public/admin;


location /api/v1/gateway_install {
    set $template_root /massbit/massbitroute/app/src/sites/services/api/apps/api/templates;
    content_by_lua_file /massbit/massbitroute/app/src/sites/services/api/apps/api/handlers/gateway_install.lua;
}

--- request
GET /api/v1/gateway_install?id=1af00408-d427-4fd1-b796-ba22296ffbac&user_id=b363ddf4-42cf-4ccf-89c2-8c42c531ac99&blockchain=eth&network=mainnet&zone=EU&app_key=2lh5jo-BWSo49R5ugpnVEg&portal_url=https://portal.massbitroute.net&env=keiko

--- response_body eval
qr/_register_node/
--- no_error_log
