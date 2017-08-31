local class = require("pl.class")
local ffi = require("ffi")
local tablex = require("pl.tablex")

-- may not be instanciated itself, may only be inherited

class.FXParameters()

function FXParameters:_init(struct)

  local meta = tablex.copy(getmetatable(self))

  self.__old_index = meta.__index

  self.obj = ffi.new(struct.."[1]")

  meta.__index = function(self, key)

    local tmp = rawget(self, key) or rawget(self, 'get_'..key)

    if type(tmp) == 'function' then
      return tmp(self)
    elseif tmp ~= nil then
      return tmp
    else
      return rawget(self, '__old_index')[key]
    end

  end

  setmetatable(self, meta)

end

function FXParameters:LinkParameter(struct_param, table_param)

  if self["get_"..table_param] ~= nil or self["set_"..table_param] ~= nil then
    return false
  end

  self["get_"..table_param] = function(self)

    return self.obj[0][struct_param]

  end

  self["set_"..table_param] = function(self, value)

    self.obj[0][struct_param] = value

  end

end

function FXParameters:GetPointer()

  return ffi.cast("void *", self.obj)

end

return FXParameters