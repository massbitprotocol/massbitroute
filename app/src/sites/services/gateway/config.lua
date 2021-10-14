local _config = {
    server = {
        nginx = {
            port = "80",
            port_ssl = "443",
            server_name = "massbitroute"
        }
    },
    templates = {},
    apps = {},
    supervisor = [[

[program:prometheus]
command=/bin/bash _SITE_ROOT_/scripts/run loop _service_prometheus _SITE_ROOT_
directory=_SITE_ROOT_/data/prometheus
redirect_stderr=true         
stdout_logfile=_SITE_ROOT_/logs/prometheus.log
autorestart=true


[program:grafana]
command=/bin/bash _SITE_ROOT_/scripts/run loop _service_grafana _SITE_ROOT_
directory=_SITE_ROOT_/data/grafana
redirect_stderr=true         
stdout_logfile=_SITE_ROOT_/logs/grafana.log
autorestart=true
    ]]
}
return _config
