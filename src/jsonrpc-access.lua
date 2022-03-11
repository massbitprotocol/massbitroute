local cjson = require("cjson")

local function empty(s)
    return s == nil or s == ""
end
-- get request content
ngx.req.read_body()

-- try to parse the body as JSON
local success, body = pcall(cjson.decode, ngx.var.request_body)
if not success then
    ngx.log(ngx.ERR, "invalid JSON request")
    ngx.exit(ngx.HTTP_BAD_REQUEST)
    return
end

local method = body["method"]
local version = body["jsonrpc"]

-- check we have a method and a version
if empty(method) or empty(version) then
    ngx.log(ngx.ERR, "no method and/or jsonrpc attribute")
    ngx.exit(ngx.HTTP_BAD_REQUEST)
    return
end

-- check the version is supported
if version ~= "2.0" then
    ngx.log(ngx.ERR, "jsonrpc version not supported: " .. version)
    ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
    return
end

ngx.var["api_method"] = method
