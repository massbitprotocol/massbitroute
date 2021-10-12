-- Copyright (C) 2016 Yunfeng Meng

-- MongoDB ObjectId
--[[
-- ObjectId 是一个12字节 BSON 类型数据，有以下格式：
-- 前4个字节表示时间戳
-- 接下来的3个字节是机器标识码
-- 紧接的两个字节由进程id组成（PID）
-- 最后三个字节是计数器
--]]

local ngx        = ngx
local floor      = math.floor
local str_char   = string.char
local str_format = string.format
local str_gsub   = string.gsub
local str_byte   = string.byte
local time       = ngx.time
local unpack     = unpack
local io_popen   = io.popen
local assert     = assert
local md5_bin    = ngx.md5_bin
local type       = type


local _M = { _VERSION = '0.01' }

local inc = 0 -- 计数器

local hostname = nil -- 计算机名

local function _get_inc()
    inc = (inc + 1) % 0xffffff
    return inc
end

local function _get_pid()
    return ngx.worker.pid() % 0xffff
end


local function _get_machineid()
    if hostname == nil then 
        hostname = io_popen("uname -n"):read("*l")
    end
    return hostname
end


local function _get_timestamp()
    return time()
end


-- number convert to unsigned int
local function _num2uint(num, bytes)
    bytes = bytes or 4
    local b = {}
    for i = bytes, 1, -1 do
        b[i], num = num % 2^8, floor(num / 2^8)
    end
    assert(num == 0)
    return str_char(unpack(b))
end


-- binary string convert to hex string
local function _bin2hex(str)
    str = str_gsub(str,"(.)", function (x) return str_format("%02x", str_byte(x)) end)
    return str
end


function _M.generate_id(mid)
    if mid == nil then -- auto generate
        mid = md5_bin(_get_machineid()):sub(1, 3)
    elseif type(mid) == "string" then
        mid = md5_bin(mid):sub(1, 3)
    elseif type(mid) == "number" then
        mid = _num2uint(mid, 3)
    end
    return _bin2hex(_num2uint(_get_timestamp(), 4) .. mid .. _num2uint(_get_pid(), 2) .. _num2uint(_get_inc(), 3))
end


return _M

