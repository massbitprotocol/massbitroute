local uuid = require 'jit-uuid'



local gbc = cc.import("#gbc")
local type = "api"
local Action = cc.class("Api" .. type, gbc.ActionBase)

local mkdirp = require "mkdirp"
local flatdb = require "flatdb"

local dir_data =  ngx.var.app_root .. "/data/"
local dir_detail = dir_data .. type  .. "/detail"

local util = require "api_util"
local showFolder = util.showFolder
local getIdByType = util.getIdByType
local typeParent = util.typeParent

function Action:updateAction(args)
   if not args.api_key or string.len(args.api_key) == 0 then
      uuid.seed(math.random())
      args.api_key = uuid()
   end
   
   if not args.api_id or string.len(args.api_id) == 0 then
      uuid.seed(math.random())
      args.api_id = uuid()
   end
   
    args.action = nil
    local id = args.id
    
    if id then
        local _dir = dir_detail
        mkdirp(_dir)
        local db = flatdb(_dir)

        if not db[id] then
            db[id] = {}
        end
        table.merge(db[id], args)
        db:save()

        local parent_type = typeParent[type]
        local parent_id = parent_type and db[id][parent_type .. "_id"]
        if parent_type and parent_id then
            local parent_dir = dir_data .. parent_type .. "/list/" .. type .. "/" .. parent_id
            mkdirp(parent_dir)
            local db_parent = flatdb(parent_dir)
            if not db[id] then
                db[id] = {}
            end
            db_parent[id] = db[id]
            db_parent:save()
        end
    end

    return {
        result = true
    }
end



function Action:getAction(args)
    local id = args.id
    args.action = nil
    mkdirp(dir_data)
    local _data = {}
    if not id then
        _data = showFolder(dir_detail)
    else
        local db = flatdb(dir_detail)
        _data = db[id]
    end
    return {
        result = true,
        data = _data
    }
end

function Action:genAction(args)
    local id = args.id
    args.action = nil
    local _data
    if id then
        _data = getIdByType(type, id)
        _data.dnss = {
            {id = 1, domain = "abc.com"}
        }
        _data.sites = {
            {id = 1}
        }
    end
    return {
        result = true,
        data = _data
    }
end

function Action:deleteAction(args)
    local id = args.id
    args.action = nil
    if id and id ~= "." and id ~= ".." then
        os.remove(dir_data .. "/" .. id)
    end

    return {
        result = true
    }
end

return Action
