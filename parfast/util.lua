-- utilities

local util = {}

function util.log(prefix, format, ...)
  prefix = prefix or "Log"
  io.write(string.format("[%s] ", prefix))
  print(string.format(format, ...))
end

function util.abort(prefix, format, ...)
  util.log(prefix, format, ...)
  print("\naborting due to previous error")
  os.exit(1)
end

function util.class()
  local c = {}
  c.__index = c
  function c.new(...)
    local self = setmetatable({}, c)
    self:constructor(...)
    return self
  end
  return c
end

util.location = util.class()

function util.location:constructor(file, line, column)
  self.file = file
  self.line = line
  self.column = column
end

function util.location:__tostring()
  return string.format("%s: at line %d and column %d", self.file, self.line, self.column)
end

local counter = 0
function util.enum(reset)
  reset = reset or false
  if reset then
    counter = 0
  else
    local c = counter
    counter = counter + 1
    return c
  end
end

function util.todo(kind, name)
  util.abort(nil, "%s %s is not implemented!", kind, name)
end

return util