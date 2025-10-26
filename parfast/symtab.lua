local util = require("parfast.util")
local symtab = util.class()

function symtab:constructor(outer)
  self.outer = outer -- parent symbol table
  self.symbols = {}
end

function symtab:find(name)
  if self.symbols[name] == nil then
    if self.outer ~= nil then
      return self.outer:find(name)
    else
      util.abort(nil, "Unknown symbol '%s'.", name)
    end
  end
  return self.symbols[name]
end

function symtab:set(name, value)
  if self.symbols[name] == nil then
    self.symbols[name] = value
  else
    util.abort(nil, "Trying to redefine symbol '%s'.")
  end
end

return symtab