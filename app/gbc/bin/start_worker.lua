--[[

Copyright (c) 2015 gameboxcloud.com

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

]]

local args = {...}

local help = function()
    print [[

$ lua start_worker.lua <GBC_CORE_ROOT> <APP_ROOT_PATH>

]]
end

if #args < 2 then
    return help()
end

local ROOT_DIR = args[1]
local APP_ROOT_PATH = args[2]
local LUA_PATH = args[3]
local LUA_CPATH = args[4]



package.path = LUA_PATH.. ';' ..
   ROOT_DIR .. '/gbc/src/?.lua;' ..
   -- ROOT_DIR .. '/gbc/lib/?.lua;' ..
   -- ROOT_DIR .. '/gbc/lib/share/lua/5.1/?.lua;' ..
   ROOT_DIR .. '/bin/openresty/lualib/?.lua;' ..
   package.path
package.cpath = LUA_CPATH .. ';' ..
   ROOT_DIR .. '/gbc/src/?.so;' ..
   -- ROOT_DIR .. '/gbc/lib/?.so;' ..
   -- ROOT_DIR .. '/gbc/lib/lib/lua/5.1/?.so;' ..
   ROOT_DIR .. '/bin/openresty/lualib/?.so;' ..
   package.cpath


require("framework.init")
local appKeys = dofile(ROOT_DIR .. "/tmp/app_keys.lua")
local globalConfig = dofile(ROOT_DIR .. "/tmp/config.lua")

cc.DEBUG = globalConfig.DEBUG

local gbc = cc.import("#gbc")
local bootstrap = gbc.WorkerBootstrap:new(appKeys, globalConfig)

os.exit(bootstrap:runapp(APP_ROOT_PATH))
