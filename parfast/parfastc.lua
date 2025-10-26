-- The parfast compiler

local compiler = require("parfast.compiler")
local parfastc = {}

function parfastc.main()
  local c = compiler.new()
  print(c:dostring(arg[1], "main"))
  return 0
end

return parfastc