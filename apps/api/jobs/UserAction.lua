local cc = cc
local gbc = cc.import("#gbc")
local json = cc.import("#json")

local mytype = "user"
local JobsAction = cc.class(mytype .. "JobsAction", gbc.ActionBase)

local cURL = require "cURL"

-- local SENDGRID_API_KEY

local mbrutil = require "mbutil" -- cc.import("#mbrutil")
local _get_tmpl = mbrutil.get_template
local _print = mbrutil.print
local _write_file = mbrutil.write_file
local mkdirp = require "mkdirp"

local _deploy_dir = "/massbit/massbitroute/app/src/sites/services/api/public/deploy/user"
mkdirp(_deploy_dir)
JobsAction.ACCEPTED_REQUEST_TYPE = "worker"
local Model = cc.import("#" .. mytype)

local inspect = require "inspect"

local mails = {
    login = {
        subject = "Authorize log-in attempt"
    },
    register = {
        subject = "Welcome to Massbit! Confirm Your Email"
    }
}
local rules = {}

local function _sendmail(args, config)
    local _appconf = config.app
    _print("appconf:" .. inspect(_appconf))
    local SENDGRID_API_KEY = _appconf.sengrid_key
    local _mailtype = args.mailtype
    rules[_mailtype] = mbrutil.read_file(args.site_root .. "/public/mail-templates/" .. _mailtype .. ".html")
    -- local _str_tmpl = mbrutil.read_file(args.site_root .. "/public/mail-templates/test.html")
    -- mbrutil.read_file(args.site_root .. "/public/mail-templates/templates-inlined/basic-full/welcome/content.html")
    local _id = args.id
    if not _id then
        return false
    end

    local _tmpl = _get_tmpl(rules, args)
    local _str_tmpl = _tmpl(_mailtype)
    if _str_tmpl then
        _str_tmpl = _str_tmpl:gsub("%s+", " "):gsub("\\", "\\\\"):gsub('"', '\\"'):gsub("'", "")
    end
    _print(inspect(args))
    -- _print(_str_tmpl)
    -- local _str_tmpl =
    --     "<a href='https://dapi.massbit.io/api/v1?action=user.registerconfirm&token=" ..
    --     args.token .. "'>Confirm your email</a>"

    local _subject = mails[_mailtype].subject
    local _body =
        [[{"personalizations": [{"to": [{"email": "]] ..
        args.email ..
            [["}]}],"from": {"email": "noreply@massbit.io"},"subject": "]] ..
                _subject .. [[","content": [{"type": "text/html", "value": "]] .. _str_tmpl .. [["}]}']]
    -- _print(_body)
    local c =
        cURL.easy {
        url = "https://api.sendgrid.com/v3/mail/send",
        post = true,
        httpheader = {
            "Content-Type: application/json",
            "Authorization: Bearer " .. SENDGRID_API_KEY
        },
        postfields = _body
    }

    -- _print(inspect(c))

    local buffer = {}

    local ok, err = c:perform()
    if ok then
        local code, url, content = c:getinfo_effective_url(), c:getinfo_response_code(), table.concat(buffer)
        _print(code)
        _print(url)
        _print(content)
    else
        _print(err)
    end

    c:close()
end

function JobsAction:registerAction(job)
    _print(inspect(job))

    local job_data = job.data
    job_data.mailtype = "register"
    local _config = self:getInstanceConfig()
    _print("config:" .. inspect(_config))
    _sendmail(job_data, _config)
end

function JobsAction:loginAction(job)
    _print(inspect(job))

    -- local _instance = self:getInstance()
    -- local _config = self:getInstanceConfig()
    -- _print("config:" .. inspect(_config))

    local job_data = job.data
    -- job_data.mailtype = "login"
    -- _sendmail(job_data, _config)

    local _id = job_data.id
    local instance = self:getInstance()
    local _user = Model:new(instance)
    local _detail, _err = _user:get(_id)
    _print(_detail, true)

    local _deploy_file = _deploy_dir .. "/" .. _id
    _detail.password_hash = nil
    _detail.password_salt = nil
    _detail.site_root = nil
    _write_file(_deploy_file, json.encode(_detail))

    return true
end

return JobsAction
