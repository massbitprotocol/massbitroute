local cc = cc
local gbc = cc.import("#gbc")
local json = cc.import("#json")

local mytype = "node"
local JobsAction = cc.class(mytype .. "JobsAction", gbc.ActionBase)

local cURL = require "cURL"

local SENDGRID_API_KEY = "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"

local mbrutil = cc.import("#mbrutil")
local _get_tmpl = mbrutil.get_template
local _print = mbrutil.print

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
local rules = {
    login = [[An attempt to login was made from an unknown browser. Please confirm the following details are correct: - Time: ${time} - IP Address: ${ip} - Device: ${user_agent}]],
    register = [[<a href='https://dapi.massbit.io/api/v1?action=user.registerconfirm&token=${token}'>Confirm your email</a>]]
}

local function _sendmail(args)
    local _id = args.id
    if not _id then
        return false
    end

    _print(inspect(args))
    local _mailtype = args.mailtype
    local _tmpl = _get_tmpl(rules, args)
    local _str_tmpl = _tmpl(_mailtype)
    if _str_tmpl then
        _str_tmpl = _str_tmpl:gsub("%s+", " "):gsub('"', '\\"'):gsub("'", "\\'")
    end

    -- local _str_tmpl =
    --     "<a href='https://dapi.massbit.io/api/v1?action=user.registerconfirm&token=" ..
    --     args.token .. "'>Confirm your email</a>"

    local _subject = mails[_mailtype].subject
    local _body =
        [[{"personalizations": [{"to": [{"email": "]] ..
        args.email ..
            [["}]}],"from": {"email": "noreply@massbit.io"},"subject": "]] ..
                _subject .. [[","content": [{"type": "text/html", "value": "]] .. _str_tmpl .. [["}]}']]
    _print(_body)
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

    -- local instance = self:getInstance()

    local job_data = job.data
    job_data.mailtype = "register"
    _sendmail(job_data)
end

function JobsAction:loginAction(job)
    _print(inspect(job))

    -- local instance = self:getInstance()

    local job_data = job.data
    job_data.mailtype = "login"
    _sendmail(job_data)
end

return JobsAction
