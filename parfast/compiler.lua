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
  self.outname = "a.out"
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
    return "$" .. tostring(v.value)
  elseif v.tt_ == "ast.Value.String" then
    return self:pushk(v.value, "string")
  elseif v.tt_ == "ast.Value.Name" then
    local s = self.symtab:find(v.symbol)
    if s.tt_ == "tab.Entry.Mem" then
      if s.global then
        self:outf("\tmovq $%s, %%rax", v.symbol)
        return "%rax"
      else
        self:outf("\tmovq -%d(%%rbp), %%rax", s.offset)
        return "%rax"
      end
    elseif s.tt_ == "tab.Entry.Bind" then
      self:outf("\tmovq -%d(%%rbp), %%rax", s.offset)
      return "%rax"
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
  c:outf("\tmovq %s, %%rdi", c:value(i.value))
  c:outf("\tcall parfast.core.push")
end

Op["ast.Op.Dup"] = function (c, i)
  c:outf("\tcall parfast.core.dup")
end

Op["ast.Op.Rot"] = function (c, i)
  c:outf("\tcall parfast.core.rot")
end

Op["ast.Op.Swap"] = function (c, i)
  c:outf("\tcall parfast.core.swap")
end

Op["ast.Op.Drop"] = function (c, i)
  c:outf("\tcall parfast.core.pop")
end

function compiler:stat(s)
  if Op[s.tt_] ~= nil then
    Op[s.tt_](self, s)
  else
    if s.tt_ == "ast.Stat.Bind" then
      local oldrbp = self.rbp
      self:enter()
      self:outf("/* begin bind */")
      for i = 1, #s.vars do
        self.rbp = self.rbp + 8
        self:outf("\tcall parfast.core.pop")
        self:outf("\tmovq %%rax, -%d(%%rbp)", self.rbp)
        self.symtab:set(s.vars[i], tab.Entry.Bind(self.rbp))
      end
      for i = 1, #s.body do
        self:stat(s.body[i])
      end
      self:outf("/* end bind */")
      self:leave()
      self.rbp = oldrbp
    else -- TODO: local memory and functions.
      util.abort("Error", "Unknown stat '%s'", tostring(s))
    end
  end
end

function compiler:func(f)
  self:outf("%s:", f.name)
  self:outf("\tpushq %%rbp")
  self:outf("\tmovq %%rsp, %%rbp")
  for i = 1, #f.body do
    self:stat(f.body[i])
  end
  self:outf("\tpopq %%rbp")
  self:outf("\tret")
end

function compiler:section_rodata()
  if #self.data == 0 then
    return
  end
  self:outf(".section .rodata")
  for i = 1, #self.data do
    local c = self.data[i]
    if c.type == "string" then
      self:outf(".LC%d:", i)
      self:outf("\t.string %q", c.value)
    end
  end
end

function compiler:section_bss()
  if #self.bss == 0 then
    return
  end
  self:outf(".section .bss")
  for i=1, #self.bss do
    local c = self.bss[i]
    self:outf("%s:\t.zero %d", c.name, c.size)
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