local union = require("parfast.union")

local ast = {}

union.define(ast, "ast", "Value", {
  Number = {"value"},
  String = {"value"},
  Name = {"symbol"}
})

-- some instrinsics are missing,
-- this will stay as a todo
union.define(ast, "ast", "Op", {
  Push = {"loc", "value"},
  Dup = {"loc"},
  Rot = {"loc"},
  Swap = {"loc"},
  Load8 = {"loc"},
  Store8 = {"loc"},
  Load64 = {"loc"},
  Store64 = {"loc"},
  Drop = {"loc"},
  Add = {"loc"},
  Sub = {"loc"},
  Mul = {"loc"},
  Div = {"loc"}
})

union.define(ast, "ast", "Stat", {
  Fn = {"loc", "name", "body", "types"},
  If = {"loc", "cond", "body"},
  While = {"loc", "cond", "body"},
  Bind = {"loc", "vars", "body"},
  Mem = {"loc", "body"} -- body will be evaluated at compile-time (after type-checking)
})

union.define(ast, "ast", "Types", {
  Ptr = {},
  Str = {},
  Int = {},
  Bool = {}
})

return ast