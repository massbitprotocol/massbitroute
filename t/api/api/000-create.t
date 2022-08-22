use Test::Nginx::Socket::Lua 'no_plan';

repeat_each(1);

no_shuffle();

# plan tests => blocks() * repeat_each() * 2;
$ENV{TEST_NGINX_HTML_DIR} ||= html_dir();
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
map $http_x_forwarded_for $realip {
    ~^(\d+\.\d+\.\d+\.\d+) $1; # IPv4
    ~*([A-F0-9:]*) $1; # Very relaxed IPv6 regex
    default $remote_addr;
}
map $http_origin $allow_origin {
    include /massbit/massbitroute/app/src/sites/services/api/sites/../cors-whitelist.map;
    default '';
}
geoip2 /massbit/massbitroute/app/src/sites/services/api/sites/../data/geoip/GeoIP2-City.mmdb {
    auto_reload 60m;
    $db_timestamp metadata build_epoch;
    $db_last_check metadata last_check;
    $db_last_change metadata last_change;
    $continent_id source=$realip continent geoname_id;
    $continent_code source=$realip continent code;
    $continent_name source=$realip continent names en;
    $country_id source=$realip country geoname_id;
    $country_code source=$realip country iso_code;
    $country_name source=$realip country names en;
    $city_id source=$realip city geoname_id;
    $city_name source=$realip city names en;
    $location_acc source=$realip location accuracy_radius;
    $location_lat source=$realip location latitude;
    $location_lon source=$realip location longitude;
    $location_timezone source=$realip location time_zone;
}
lua_shared_dict portal_stats 10m;
variables_hash_max_size 2048;
_EOC_

our $config = <<'_EOC_';
     set $namespace massbitroute.net_admin;
    set $site_root /massbit/massbitroute/app/src/sites/services/api/sites/..;
    set $server_root /massbit/massbitroute/app/src/sites/services/api;
    set $redis_sock /massbit/massbitroute/app/src/sites/services/api/tmp/redis.sock;

    root /massbit/massbitroute/app/src/sites/services/api/sites/../public/admin;

 location /deploy {
        root /massbit/massbitroute/app/src/sites/services/api/public;
    }
location /_internal_api/v2 {
    access_log /massbit/massbitroute/app/src/sites/services/api/logs/internal_api_v2-access.log;
    error_log /massbit/massbitroute/app/src/sites/services/api/logs/internal_api_v2-error.log;
    include /massbit/massbitroute/app/src/sites/services/api/sites/../cors.conf;
    set $app_root /massbit/massbitroute/app/src/sites/services/api/apps/api;
    default_type application/json;
    limit_except OPTIONS POST GET {
        deny all;
    }
    content_by_lua 'nginxBootstrap:runapp("/massbit/massbitroute/app/src/sites/services/api/apps/api")';

}
_EOC_
run_tests();

__DATA__

=== Api create new

--- main_config eval: $::main_config
--- http_config eval: $::http_config
--- config eval: $::config
--- more_headers
Content-Type: application/json
--- request
POST /_internal_api/v2/?action=api.create
{
  "allow_methods" : {},
  "app_id" : "c237c346-7a0f-478b-bc0c-e3ca2522948f",
  "app_key" : "WJaEniHiudjuhLV7diHkDw",
  "blockchain" : "eth",
  "id" : "c237c346-7a0f-478b-bc0c-e3ca2522948f",
  "limit_rate_per_day" : 3000,
  "limit_rate_per_sec" : 100,
  "name" : "api-6",
  "network" : "mainnet",
  "status" : 1,
  "project_id" : "83260a9e-4e41-4293-abc5-fe47a2219534",
  "project_quota" : "100000",
  "partner_id" : "fc78b64c5c33f3f270700b0c4d3e7998188035ab",
  "sid" : "403716b0f58a7d6ddec769f8ca6008f2c1c0cea6",
  "user_id" : "b363ddf4-42cf-4ccf-89c2-8c42c531ac99"
}
--- response_body eval
qr/"result":true/
--- no_error_log

=== Check raw data if created or not

--- main_config eval: $::main_config
--- http_config eval: $::http_config
--- config eval: $::config
--- request
GET /deploy/dapi/eth/mainnet/b363ddf4-42cf-4ccf-89c2-8c42c531ac99/c237c346-7a0f-478b-bc0c-e3ca2522948f
--- error_code: 200
--- response_body eval
qr/"id":"c237c346-7a0f-478b-bc0c-e3ca2522948f"/
--- no_error_log

=== Check ID conf if created or not

--- main_config eval: $::main_config
--- http_config eval: $::http_config
--- config eval: $::config
--- request
GET /deploy/dapiconf/nodes/eth-mainnet/c237c346-7a0f-478b-bc0c-e3ca2522948f.conf
--- error_code: 200
--- response_body: 
--- no_error_log
