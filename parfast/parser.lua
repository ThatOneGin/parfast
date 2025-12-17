-- parfast parser

local util = require("parfast.util")
local lex  = require("parfast.lex")
local ast = require("parfast.ast")
local abort = util.abort
local f = string.format
-- we have a limit of how nested a block
-- can be, this is to avoid the
-- generation of an unbalanced/too nested AST
local MAXNESTLEVEL = 20

local parser = util.class()

function parser:constructor(lexer)
  self.lexer = lexer
  self.previous = nil
  self.current = nil
  self.nestlevel = 0
  self.macros = {}

  self:next()
end

function parser:syntaxerror(f, ...)
  local near = (self.previous == nil) and
    self.current.loc or
    self.previous.loc
  abort("Error", tostring(near) .. ": " .. f, ...)
end

function parser:enter()
  if self.nestlevel >= MAXNESTLEVEL then
    self:syntaxerror("Max nest level reached")
  end
  self.nestlevel = self.nestlevel + 1
end

function parser:leave()
  assert(self.nestlevel >= 0)
  self.nestlevel = self.nestlevel - 1
end

function parser:consume()
  local success, token = self.lexer:lex()
  if not success then
    self:syntaxerror("Lexer error: %s", token)
  end
  self.previous = self.current
  self.current = token
end

function parser:next()
  local tk = self.current
  self:consume()
  return tk
end

function parser:match(t)
  assert(self.current)
  return self.current.type == t
end

function parser:expect(t, errmsg)
  errmsg = errmsg or f("Expected %s", t)
  local tk = self.current
  if tk.type ~= t then
    self:syntaxerror("%s", errmsg)
  else
    self:consume()
  end
  return tk
end

-- value = number|string|identifier
function parser:value()
  if self:match("number") then
    local v = self:next().value
    return ast.Value.Number(v)
  elseif self:match("string") then
    local v = self:next().value
    return ast.Value.String(v)
  elseif self:match("identifier") then
    local s = self:next().value
    return ast.Value.Name(s)
  else
    self:syntaxerror("Invalid value %s", tostring(self.current))
  end
end

local ops = {
  ["dup"] = ast.Op.Dup,
  ["rot"] = ast.Op.Rot,
  ["swap"] = ast.Op.Swap,
  ["ld"] = ast.Op.Load8,
  ["st"] = ast.Op.Store8,
  ["rld"] = ast.Op.Load64,
  ["rst"] = ast.Op.Store64,
  ["drop"] = ast.Op.Drop,
  ["+"] = ast.Op.Add,
  ["-"] = ast.Op.Sub,
  ["*"] = ast.Op.Mul,
  ["/"] = ast.Op.Div
}

-- an atom is an instrinsic (e.g. dup rot swap)
-- the first value is a boolean that if true, means
-- that it found a macro with the symbol that is returned
function parser:atom()
  local loc = self.current.loc
  if self:match("number") then
    local v = self:value()
    return false, ast.Op.Push(loc, v)
  elseif self:match("string") then
    local v = self:value()
    return false, ast.Op.Push(loc, v)
  elseif self:match("identifier") then
    local v = self:value()
    if self.macros[v.symbol] then
      return true, v.symbol
    end
    return false, ast.Op.Push(loc, v)
  else -- try operators
    local tk = self:next()
    local t = tk.type
    if ops[t] ~= nil then
      return false, ops[t](tk.loc)
    else
      self:syntaxerror("Unknown operator %s", t)
    end
  end
end

-- only atoms are allowed in this block
function parser:subsetblock(t)
  local block = {}
  local i = 1
  self:enter()
  while not self:match(t) and not self:match("EOF") do
    local expand, a = self:atom()
    if not expand then
      block[i] = a
    else
      local macro = self.macros[a]
      for j = i, #macro do
        block[j] = macro[j]
      end
      i = i + #macro
    end
    i = i + 1
  end
  self:leave()
  self:expect(t, nil)
  return block
end

-- parse statements until the current token is of type 't'
function parser:block(t)
  local block = {}
  local i = 1
  self:enter()
  while not self:match(t) and not self:match("EOF") do
    local expand, s = self:stat()
    if not expand then
      block[i] = s
    else
      local macro = self.macros[s]
      for j = i, #macro do
        block[j] = macro[j]
      end
      i = i + #macro
    end
    i = i + 1
  end
  self:leave()
  self:expect(t, "Unfinished block")
  return block
end

function parser:vars()
  local vars = {}
  local i = 1
  while self:match("identifier") and
        not self:match("EOF") do
    vars[i] = self:expect("identifier", nil).value
    i = i + 1
  end
  return vars
end

function parser:stat()
  if self:match("if") then -- if <cond> then <body> end
    local loc = self:next().loc
    local cond = self:block("then")
    local body = self:block("end")
    return false, ast.Stat.If(loc, cond, body)
  elseif self:match("while") then -- while <cond> do <body> end
    local loc = self:next().loc
    local cond = self:block("do")
    local body = self:block("end")
    return false, ast.Stat.While(loc, cond, body)
  elseif self:match("bind") then -- bind <vars> in <body> end
    local loc = self:next().loc
    local vars = self:vars()
    local _ = self:expect("in")
    local body = self:block("end")
    return false, ast.Stat.Bind(loc, vars, body)
  else
    return self:atom()
  end
end

local types = {
  ["str"] = ast.Types.Str(),
  ["ptr"] = ast.Types.Ptr(),
  ["int"] = ast.Types.Int(),
  ["bool"] = ast.Types.Bool()
}
function parser:type()
  local t = self:expect("identifier",
    "Expected valid type (str/ptr/int/bool)").value
  if types[t] ~= nil then
    return types[t]
  else
    self:syntaxerror("Expected valid type (str/ptr/int/bool)")
  end
end

-- parse types until current token is of type 't'
function parser:typelist(t)
  local types_ = {}
  while not self:match(t) and
        not self:match("EOF") do
    types_[#types_+1] = self:type()
  end
  self:expect(t, "Unfinished type list")
  return types_
end

-- top level is a block that should be
-- at the depth 0 of the parser
-- (global memory and function definitions)
function parser:toplevel()
  if self:match("fn") then
    local loc = self:next().loc
    local name = self:expect("identifier", "Expected function name").value
    local types = self:typelist("with")
    local body = self:block("end")
    return ast.Stat.Fn(loc, name, body, types)
  elseif self:match("mem") then
    local loc = self:next().loc
    local name = self:expect("identifier", "Expected region name").value
    local body = self:subsetblock("end")
    return ast.Stat.Mem(loc, name, body)
  elseif self:match("macro") then
    local _ = self:next()
    local name = self:expect("identifier", "Expected macro name").value
    local body = self:block("endm")
    if self.macros[name] == nil then
      self.macros[name] = body
    end
    return nil
  else
    self:syntaxerror("Expected function or memory allocation at top-level")
  end
end

-- only export the main function
return function (name, source)
  local l = lex.new(name, source)
  local p = parser.new(l)
  local program = {}
  while not p:match("EOF") do
    local t = p:toplevel()
    if t ~= nil then
      program[#program+1] = t
    end
  end
  return program
end
