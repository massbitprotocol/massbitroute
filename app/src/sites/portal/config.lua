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
       api = "apps/api" 
    },
    supervisor = [[
    ]]
}
return _config
