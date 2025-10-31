-- function to evaluate
-- some operations at compile-time
local util = require("parfast.util")
local ast = require("parfast.ast")

local stack = {}
local sp = 1

local function push(value)
  stack[sp] = value
  sp = sp + 1
end

local function pop(loc)
  if sp == 0 then
    util.abort("Error", "%s: Stack underflow", loc)
  end
  sp = sp - 1
  return stack[sp]
end

local arithtable = {
  ["+"] = function (l, r) return l.value + r.value end,
  ["-"] = function (l, r) return l.value - r.value end,
  ["*"] = function (l, r) return l.value * r.value end,
  ["/"] = function (l, r) return l.value / r.value end
}
function arith(loc, op)
  local r = pop()
  local l = pop()
  if l.tt_ ~= "ast.Value.Number" or r.tt_ ~= "ast.Value.Number" then
    util.abort("Error", "%s: Invalid hand for compile-time execution",
      tostring(loc))
  end
  push(ast.Value.Number(arithtable[op](l, r)))
end

local function evaluate_op(loc, op)
  if op.tt_ == "ast.Op.Push" then push(op.value)
  elseif op.tt_ == "ast.Op.Add" then arith(loc, "+")
  elseif op.tt_ == "ast.Op.Sub" then arith(loc, "-")
  elseif op.tt_ == "ast.Op.Mul" then arith(loc, "*")
  elseif op.tt_ == "ast.Op.Div" then arith(loc, "/")
  else
    util.abort("Error",
      "%s: Invalid instruction for compile-time execution %s.", tostring(loc), op.tt_)
  end
end

return function (loc, body)
  for i = 1, #body do
    evaluate_op(loc, body[i])
  end
  if sp == 1 then
    util.abort("Error",
      "%s: compile-time block must produce a value",
      tostring(loc))
  end
  return pop().value
end