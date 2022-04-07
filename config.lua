local _config = {
    server = {
        nginx = {
            port = "80",
            port_ssl = "443",
            server_name = "massbitroute.dev"
        }
    },
    templates = {},
    apps = {
        api = "apps/api",
        tests = "apps/tests"
    },
    supervisors = {
        ["monitor_client"] = [[
[program:monitor_client]
command=/bin/bash _SITE_ROOT_/../mkagent/agents/push.sh _SITE_ROOT_/../mkagent
autorestart=true
redirect_stderr=true
stopasgroup=true
killasgroup=true
stopsignal=INT
stdout_logfile=_SITE_ROOT_/../mkagent/logs/monitor_client.log
    ]]
    },
    supervisor = [[
[program:portal_update_listid]
command=/bin/bash _SITE_ROOT_/scripts/run loop _update_listid
autorestart=true
redirect_stderr=true
stopasgroup=true
killasgroup=true
stopsignal=INT
stdout_logfile=_SITE_ROOT_/logs/update_listid.log

[program:portal_homepage_prod]
command=/bin/bash _SITE_ROOT_/scripts/mbr_app.sh _start_prod
autorestart=true
redirect_stderr=true
stopasgroup=true
killasgroup=true
stopsignal=INT
stdout_logfile=_SITE_ROOT_/logs/portal_homepage_prod.log
]]
}
return _config
