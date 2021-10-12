local uuid = require "jit-uuid"

local gbc = cc.import("#gbc")
local mytype = "user"
local type_id = 1000

local Action = cc.class("Api" .. mytype, gbc.ActionBase)

local mkdirp = require "mkdirp"
local flatdb = require "flatdb"
local json = require "cjson"

local dir_data = ngx.var.app_root .. "/data/"
local dir_detail = dir_data .. mytype .. "/detail"

local util = require "api_util"
local showFolder = util.showFolder
local showFolderDepth = util.showFolderDepth
local getIdByType = util.getIdByType
local typeParent = util.typeParent
local objectid = require "objectid"

function Action:updateAction(args)
    if not args.id or string.len(args.id) == 0 then
        args.id = objectid.generate_id(type_id)
    end
    -- if not args.api_key or string.len(args.api_key) == 0 then
    --     uuid.seed(math.random())
    --     args.api_key = uuid()
    -- end

    -- if not args.api_id or string.len(args.api_id) == 0 then
    --     uuid.seed(math.random())
    --     args.api_id = uuid()
    -- end

    ngx.log(ngx.ERR, "args:" .. json.encode(args))
    local parent_type = typeParent[mytype]
    local parent_id = parent_type and args[parent_type .. "_id"]

    ngx.log(ngx.ERR, "parent_id:" .. parent_id)
    args.action = nil
    local id = args.id

    if id then
        local _dir = dir_detail
        if parent_id then
            _dir = _dir .. "/" .. parent_id
        end

        mkdirp(_dir)
        local db = flatdb(_dir)

        if not db[id] then
            db[id] = {}
        end
        table.merge(db[id], args)
        db:save()

        -- local parent_type = typeParent[mytype]
        -- local parent_id = db[id][parent_type .. "_id"] or parent_id
        ngx.log(ngx.ERR, "parent_id:" .. parent_id)
        if parent_type and parent_id then
            local parent_dir = dir_data .. parent_type .. "/list/" .. mytype .. "/" .. parent_id

            ngx.log(ngx.ERR, "parent_dir:" .. parent_dir)
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

    local parent_type = typeParent[mytype]
    -- ngx.log(ngx.ERR, "parent_type:" .. parent_type)
    local parent_id = parent_type and args[parent_type .. "_id"]

    if parent_id then
       -- ngx.log(ngx.ERR, "parent_id:" .. parent_id)
        dir_detail = dir_detail .. "/" .. parent_id
    end
    ngx.log(ngx.ERR, "dir_detail:" .. dir_detail)
    if not id then
        -- if parent_id then
            _data = showFolder(dir_detail)
        -- else
	--    ngx.log(ngx.ERR, "showFolderDepth:dir_detail:" .. dir_detail)
        --     _data = showFolder(dir_detail)
        -- end
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
        _data = getIdByType(mytype, id)
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
        local _path = dir_detail .. "/" .. id
        ngx.log(ngx.ERR, "remove " .. _path)
        os.remove(_path)
    end

    return {
        result = true
    }
end

return Action
