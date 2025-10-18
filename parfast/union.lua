-- Tagged unions
local union = {}

local function tag_new(namespace, typespace, union_name)
  return string.format("%s.%s.%s", namespace, typespace, union_name)
end

function union.define(namespace, namespace_name, typespace_name, constructors)
  namespace[typespace_name] = {}
  for type_name, fields in pairs(constructors) do
    local tag = tag_new(namespace_name, typespace_name, type_name)
    local constructor = function (...)
      local args = {...}
      if #args ~= #fields then
        error(string.format("Non-initialized fields in union '%s', expected %d args but got %d.",
          typespace_name, #fields, #args))
      end
      local uni = {tt_ = tag}
      for i, f in ipairs(fields) do
        uni[f] = args[i]
      end
      return uni
    end
    namespace[typespace_name][type_name] = constructor
  end
end

function union.typename(namespace, typename)
  return namespace[typename]
end

return union