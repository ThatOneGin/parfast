-- The parfast compiler

local lex = require("parfast.lex")
local parse = require("parfast.parser")

local parfastc = {}

function parfastc.main()
  local p = parse("main", arg[1] or "")
  print(#p)
  return 0
end

return parfastc