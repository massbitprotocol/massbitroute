local env = require("env")
local _config = {
    portal_domain = env.MBR_API,
    whitelist_sid = {
        [env.SID] = {
            partner_id = env.PARTNER_ID
        }
    },
    whitelist_test = {},
    sessionExpiredTime = 60 * 30,
    numOfJobWorkers = 10,
    sengrid_key = env.SENDGRID_KEY,
    ipapi_token = env.IPAPI_TOKEN
}
return _config
