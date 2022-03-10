local lfs = require('lfs')
local mkdirp = {}

local function basedir(p)
    return p:gsub('[^\\/]+[\\/]?$', '')
end

function mkdirp.mkdirp(p)
  if lfs.attributes(p, 'mode') == 'directory' then
      return nil, 'already exists'
  end

    local b = basedir(p)
    if #b > 0 and lfs.attributes(b, 'mode') ~= 'directory' then
        local r, m = mkdirp.mkdirp(b)
        if not r then return r, m end
    end
    return lfs.mkdir(p)
end

setmetatable(mkdirp, {
  __call = function(_, p) return mkdirp.mkdirp(p) end
})

return mkdirp
