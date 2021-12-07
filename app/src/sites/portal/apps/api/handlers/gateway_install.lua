require "framework.init"

local params, payload, files = require "resty.reqargs"()
local inspect = require "inspect"
local template = require "resty.template"

local id = params.id
local _token = ndk.set_var.set_encrypt_session(id)
local token = ndk.set_var.set_encode_base32(_token)
ngx.log(ngx.ERR, token)
params.token = token
ngx.log(ngx.ERR, inspect(params))
template.render("gateway_install.sh", params)
