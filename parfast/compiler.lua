-- Parfast code generator (x86_64 only)

local util =require("parfast.util")
local parse = require("parfast.parser")
local union = require("parfast.union")
local symtab = require("parfast.symtab")
local comptime = require("parfast.comptime")
local concat = table.concat
local insert = table.insert
local format = string.format

-- symbol table entries
local tab = {}
union.define(tab, "tab", "Entry", {
  Mem = {"global", "offset"},
  Bind = {"offset"},
  Fn = {}
})

local compiler = util.class()

function compiler:constructor()
  self.data = {}
  self.bss = {}
  self.out = {}
  self.symtab = symtab.new(nil)
  self.rbp = 0
end

function compiler:pushk(val, ty)
  for i = 1, #self.data do
    local c = self.data[i]
    if c.value == val and c.type == ty then
      return format("$.LC%d", i)
    end
  end
  local k = {value = val, type = ty}
  insert(self.data, k)
  return format("$.LC%d", #self.data)
end

function compiler:pushm(name, global, offset, n)
  -- we need to make the number a multiple of 8
  local size = 8 * math.ceil(n / 8)
  for i = 1, #self.bss do
    local c = self.bss[i]
    if c.name == name then
      util.abort("Error", "Duplicate region '%s'", name)
    end
  end
  insert(self.bss, {name = name, size = size})
  self.symtab:set(name, tab.Entry.Mem(global, offset))
end

function compiler:outf(f, ...)
  insert(self.out, format(f, ...))
end

function compiler:value(v)
  if v.tt_ == "ast.Value.Number" then
    return tostring(v.value)
  elseif v.tt_ == "ast.Value.String" then
    return self:pushk(v.value, "string")
  elseif v.tt_ == "ast.Value.Name" then
    local s = self.symtab:find(v.symbol)
    if s.tt_ == "tab.Entry.Mem" then
      if s.global then
        self:outf("\tmov rax, %s", v.symbol)
        return "rax"
      else
        return string.format("[rbp - %d]", s.offset)
      end
    elseif s.tt_ == "tab.Entry.Bind" then
      self:outf("\tmov rax, [rbp - %d]", s.offset)
      return "rax"
    elseif s.tt_ == "tab.Entry.Fn" then
      self:outf("\tcall parfast.%s", v.symbol)
      return nil
    else
      return v.symbol
    end
  end
  return "0"
end

function compiler:enter()
  local parent = self.symtab
  self.symtab = symtab.new(parent)
end

function compiler:leave()
  if self.symtab.outer ~= nil then
    self.symtab = self.symtab.outer
  end
end

local Op = {}

Op["ast.Op.Push"] = function (c, i)
  local val = c:value(i.value)
  if val ~= nil then
    c:outf("; push")
    c:outf("\tparfast.core.push %s", val)
  end
end

Op["ast.Op.Dup"] = function (c, i)
  c:outf("; dup")
  c:outf("\tcall parfast.core.dup")
end

Op["ast.Op.Rot"] = function (c, i)
  c:outf("; rot")
  c:outf("\tcall parfast.core.rot")
end

Op["ast.Op.Swap"] = function (c, i)
  c:outf("; swap")
  c:outf("\tcall parfast.core.swap")
end

Op["ast.Op.Drop"] = function (c)
  c:outf("; drop")
  c:outf("\tparfast.core.drop rax")
end

Op["ast.Op.Add"] = function (c)
  c:outf("; add")
  c:outf("\tcall parfast.core.add")
end

Op["ast.Op.Sub"] = function (c)
  c:outf("; sub")
  c:outf("\tcall parfast.core.sub")
end

Op["ast.Op.Mul"] = function (c)
  c:outf("; mul")
  c:outf("\tcall parfast.core.mul")
end

Op["ast.Op.Div"] = function (c)
  c:outf("; div")
  c:outf("\tcall parfast.core.div")
end

Op["ast.Op.Load8"] = function (c)
  c:outf("; load (64)")
  c:outf("\tparfast.core.drop rbx")
  c:outf("\tmov al, [rbx]")
  c:outf("\tparfast.core.push rax")
end

Op["ast.Op.Store8"] = function (c)
  c:outf("; store (64)")
  c:outf("\tparfast.core.drop rbx")
  c:outf("\tparfast.core.drop rax")
  c:outf("\tmov [rax], bl")
end

Op["ast.Op.Load64"] = function (c)
  c:outf("; load (64)")
  c:outf("\tparfast.core.drop rax") -- pointer
  c:outf("\tparfast.core.push [rax]")
end

Op["ast.Op.Store64"] = function (c)
  c:outf("; store (64)")
  c:outf("\tparfast.core.drop rbx") -- value
  c:outf("\tparfast.core.drop rax") -- pointer
  c:outf("\tmov [rax], rbx")
end

function compiler:stat(s)
  if Op[s.tt_] ~= nil then
    Op[s.tt_](self, s)
  else
    if s.tt_ == "ast.Stat.Bind" then
      local oldrbp = self.rbp
      self:enter()
      self:outf("; begin bind")
      for i = 1, #s.vars do
        self.rbp = self.rbp + 8
        self:outf("\tsub r15, 8")
        self:outf("\tmov rax, [r15]")
        self:outf("\tmov [rbp - %d], rax", self.rbp)
        self.symtab:set(s.vars[i], tab.Entry.Bind(self.rbp))
      end
      for i = 1, #s.body do
        self:stat(s.body[i])
      end
      self:outf("; end bind")
      self:leave()
      self.rbp = oldrbp
    else -- TODO: local memory and functions.
      util.abort("Error", "Unknown stat '%s'", tostring(s))
    end
  end
end

local function count_vars(s)
  if s.tt_ == "ast.Stat.Bind" then
    local nvars = #s.vars
    local body_nvars;
    for i = 1, #s.body do
      body_nvars = count_vars(s.body[i])
      if body_nvars >= nvars then
        return body_nvars
      end
    end
    return nvars
  end
  return 0
end

function compiler:func(f)
  self:outf("parfast.%s: ; user function '%s'", f.name, f.name)
  self:outf("\tpush rbp")
  self:outf("\tmov rbp, rsp")
  self:outf("\tmov r15, parfast.stack")
  local nvars = 0
  local body_nvars
  for i = 1, #f.body do
    body_nvars = count_vars(f.body[i])
    if body_nvars >= nvars then
      nvars = body_nvars
    end
  end
  if nvars > 0 then
    -- allocate the stack space for the bindings
    self:outf("\tsub rbp, %d", ((nvars * 8) + 15) & ~15)
  end
  for i = 1, #f.body do
    self:stat(f.body[i])
  end
  if nvars > 0 then self:outf("\tleave")
  else self:outf("\tpop rbp")
  end
  self:outf("\tret")
end

function compiler:section_rodata()
  if #self.data == 0 then
    return
  end
  self:outf("; section rodata")
  for i = 1, #self.data do
    local c = self.data[i]
    if c.type == "string" then
      self:outf(".LC%d:", i)
      self:outf("\tdb %q", c.value)
    end
  end
end

function compiler:section_bss()
  if #self.bss == 0 then
    return
  end
  self:outf("; section bss")
  for i=1, #self.bss do
    local c = self.bss[i]
    self:outf("%s:\trb %d", c.name, c.size)
  end
end

function compiler:dostring(chunk, name)
  local ast = parse(name, chunk)
  for i=1, #ast do
    local c = ast[i]
    if c.tt_ == "ast.Stat.Fn" then
      self:enter()
      self:func(c)
      self:leave()
      self.symtab:set(c.name, tab.Entry.Fn())
    elseif c.tt_ == "ast.Stat.Mem" then
      local size = comptime(c.loc, c.body)
      self:pushm(c.name, true, -1, size)
    else
      util.abort("Error", "Unknown statement '%s'", c)
    end
  end
  self:section_rodata()
  self:section_bss()
  return concat(self.out, "\n")
end

return compiler