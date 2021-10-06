local _config = {
    modules = [[
	]],
    lua_package_path = [[_GBC_CORE_ROOT_/gbc/src/?.lua;]],
    lua_package_cpath = [[_GBC_CORE_ROOT_/gbc/src/?.so;]],
    sites = {
        portal = {
            path = "portal",
            maininit = [[
            env BIND_ADDRESS;
         ]],
         httpinit = [[
            resolver 8.8.8.8 ipv6=off;
            variables_hash_bucket_size 512;
            #ssl
            lua_shared_dict auto_ssl 1m;
            lua_shared_dict auto_ssl_settings 64k;

            #lua
            lua_capture_error_log 32m;
            #lua_need_request_body on;
            lua_regex_match_limit 1500;
            lua_check_client_abort on;
            lua_socket_log_errors off;

            lua_shared_dict _GBC_ 1024k;
            lua_shared_dict prometheus_metrics 10M;
            lua_code_cache on;
        ]],
            luainit = [[

        	require("framework.init")

        	local appKeys = dofile("_GBC_CORE_ROOT_/tmp/app_keys.lua")
        	local globalConfig = dofile("_GBC_CORE_ROOT_/tmp/config.lua")

        	cc.DEBUG = globalConfig.DEBUG

        	local gbc = cc.import("#gbc")

        	cc.exports.nginxBootstrap = gbc.NginxBootstrap:new(appKeys, globalConfig)
        ]],
            luawinit = [[

        ]]
        },
    },
    supervisor = [[


]]
}
return _config
