-- Tagged unions
local union = {}

-- we do this like that to avoid collisions with other names
local function tag_new(namespace, union_name, type_name)
  return string.format("%s.%s.%s", namespace, union_name, type_name)
end

local function union_tostring(self)
  local s = {"{"}
  for i, v in pairs(self) do
    s[#s+1] = string.format("%s=%s", tostring(i), tostring(v))
    s[#s+1] = ", "
  end
  s[#s] = "}"
  return table.concat(s)
end

local function generate_constructor(tag, fields)
  return function (...)
    local args = {...}
    if #args ~= #fields then
      error(string.format("Non-initialized fields in union '%s', expected %d args but got %d.",
        union_name, #fields, #args))
    end
    local uni = {tt_ = tag}
    for i, f in ipairs(fields) do
      uni[f] = args[i]
    end
    uni.__tostring = union_tostring
    return uni
  end
end

function union.define(namespace, namespace_name, union_name, constructors)
  namespace[union_name] = {}
  for type_name, fields in pairs(constructors) do
    local tag = tag_new(namespace_name, union_name, type_name)
    namespace[union_name][type_name] =
      generate_constructor(tag, fields)
  end
end

function union.typename(namespace, typename)
  return namespace[typename]
end

return union