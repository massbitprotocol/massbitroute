local gbc = cc.import("#gbc")
local Action = cc.class("PingAction", gbc.ActionBase)

function Action:helloAction(args)
    return {result = true, data = "pong"}
end
return Action
