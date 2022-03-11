local _config = {
    server = {
        nginx = {
            port = "80",
            port_ssl = "443",
            server_name = "massbitroute"
        }
    },
    templates = {},
    apps = {
        api = "apps/api",
        node = "apps/node",
        gateway = "apps/gateway"
    },
    supervisor = [[
[program:portal_update_listid]
command=/bin/bash _SITE_ROOT_/scripts/run loop _update_listid
autorestart=true
redirect_stderr=true
stdout_logfile=_SITE_ROOT_/logs/update_listid.log

[program:monitor_client]
command=/bin/bash _SITE_ROOT_/etc/mkagent/agents/push.sh _SITE_ROOT_
autorestart=true
redirect_stderr=true
stdout_logfile=_SITE_ROOT_/logs/monitor_client.log

[program:portal_homepage_prod]
command=/bin/bash _SITE_ROOT_/script/mbr_app.sh _start_prod
autorestart=true
redirect_stderr=true
stdout_logfile=_SITE_ROOT_/logs/portal_homepage_prod.log
]]
}
return _config
