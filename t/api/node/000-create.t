use Test::Nginx::Socket::Lua 'no_plan';

repeat_each(1);

no_shuffle();
# plan tests => blocks() * repeat_each() * 2;

$ENV{TEST_NGINX_BINARY} = "/massbit/massbitroute/app/src/sites/services/api/bin/openresty/nginx/sbin/nginx";
our $main_config = <<'_EOC_';
      load_module /massbit/massbitroute/app/src/sites/services/api/bin/openresty/nginx/modules/ngx_http_geoip2_module.so;
      load_module /massbit/massbitroute/app/src/sites/services/api/bin/openresty/nginx/modules/ngx_stream_geoip2_module.so;
      load_module /massbit/massbitroute/app/src/sites/services/api/bin/openresty/nginx/modules/ngx_http_vhost_traffic_status_module.so;
      load_module /massbit/massbitroute/app/src/sites/services/api/bin/openresty/nginx/modules/ngx_http_stream_server_traffic_status_module.so;
      load_module /massbit/massbitroute/app/src/sites/services/api/bin/openresty/nginx/modules/ngx_stream_server_traffic_status_module.so;
	

env BIND_ADDRESS;
_EOC_


our $http_config  = <<'_EOC_';

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

location /_internal_api/v3/ {

    set $app_root /massbit/massbitroute/app/src/sites/services/api/apps/api;
    default_type application/json;
 
    content_by_lua 'nginxBootstrap:runapp("/massbit/massbitroute/app/src/sites/services/api/apps/api")';
}

--- request
POST /_internal_api/v3/?action=node.create
{
  blockchain = "eth",
  data_url = "http://127.0.0.1:8545",
  data_ws = "ws://127.0.0.1:8546",
  geo = {
    city = "Omaha",
    continent_code = "NA",
    continent_name = "North America",
    country_code = "US",
    country_name = "United States",
    ip = "34.68.244.83",
    latitude = 41.232959747314,
    longitude = -95.87735748291
  },
  id = "e22663c3-9b33-4d8a-864a-b48f8f9ca0d9",
  name = "baysao-node-1",
  network = "mainnet",
  partner_id = "xxx",
  sid = "yyy",
  status = 0,
  token = "zzz",
  user_id = "eeee",
  zone = "EU"
}
--- response_body eval
qr/"result":false/
--- no_error_log
