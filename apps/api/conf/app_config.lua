local env = require("env")
--local inspect = require("inspect")
env = env or {}
--print(inspect(env))
local _config = {
   whitelist_sid = {},
   whitelist_test = {},
   sessionExpiredTime = 60 * 30,
   numOfJobWorkers = 10,
}
if env.MBR_API then
   _config.portal_domain = env.MBR_API
end

if env.SID then
   _config.whitelist_sid[env.SID] = {
      partner_id = env.PARTNER_ID
   }
end
if env.SENDGRID_KEY then
   _config.sengrid_key = env.SENDGRID_KEY
end

if env.IPAPI_TOKEN then
   _config.ipapi_token = env.IPAPI_TOKEN
end

return _config
