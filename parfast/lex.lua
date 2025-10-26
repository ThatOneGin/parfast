-- parfast lexer

local util = require("parfast.util")
local lpeg = require("lpeg")
local re_mod = require("re")
local location = util.location

local token = util.class()
function token:constructor(type, value, loc)
  self.type = type
  self.value = value
  self.loc = loc
end

function token:__tostring()
  return self.type
end

local p = lpeg.P
local r = lpeg.R
local s = lpeg.S
local re = re_mod.compile

local space = s("\t\n\v\f\r ")
local newline = p("\r\n") + p("\n\r") + p("\r") + p("\n")
local digit = re("[0-9]*")
local identifier = re("[_A-Za-z][_A-Za-z0-9]*")
local string_delm = s("\"\'")
local string_content = (1 - string_delm)^0
local comment = p("//") * (1 - newline)^0

local keywords_ = {}
do
  local k =
    [[
      fn in
      else while
      end puts
      if end
      dup swap
      while do
      else mbuf
      st ld
      drop macro
      include endm
      rot rst
      rld elseif
      then syscall0
      syscall1 syscall2
      syscall3 syscall4
      syscall5 syscall6
      mem argc
      arv fn
      asm bind
      castptr caststr
      castint castboool
      with
    ]]
  for s in k:gmatch("%w+") do
    keywords_[s] = true
  end
end

local symbols = p("==")
do
  local ops = "!= = < > + - * / !"
  for s in ops:gmatch("%p+") do
    symbols = symbols + p(s)
  end
end

local lexer = util.class()

function lexer:constructor(file, source)
  self.source = source
  self.file = file
  self.old_pos = false -- "old" position (used to capture substrings)
  self.pos = 1 -- current absolute position in the source
  self.line = 1
  self.col = 1
end

function lexer:report_location()
  return location.new(self.file, self.line, self.col)
end

function lexer:trymatch(pat)
  local pattern
  if lpeg.type(pat) == "pattern" then
    pattern = pat
  elseif type(pat) == "string" then
    pattern = p(pat)
  else
    error("Invalid lexer pattern '"..tostring(pat).."'.")
  end

  local init = self.pos
  local _end = pattern:match(self.source, self.pos)

  if _end and _end > init then
    local matched = self.source:sub(init, _end - 1)
    local nl_count = 0
    local last_nl = nil
    for i = 1, #matched do
      if matched:sub(i, i):match("[\r\n]") then
        nl_count = nl_count + 1
        last_nl = i
      end
    end
    self.line = self.line + nl_count
    if nl_count > 0 then
      self.col = #matched - last_nl + 1
    else
      self.col = self.col + #matched
    end
    self.old_pos = init
    self.pos = _end
    return true
  else
    self.old_pos = false
    return false
  end
end

function lexer:capture()
  assert(self.old_pos)
  return string.sub(self.source, self.old_pos, self.pos-1)
end

function lexer:read_string(delm)
  local old_pos = self.pos
  local new_pos = self.pos
  while true do
    if self:trymatch(delm) then
      break
    elseif self:trymatch(string_content) then
      new_pos = self.pos - 1
    else
      return false, string.format("incomplete string.")
    end
  end
  return true, string.sub(self.source, old_pos, new_pos)
end

function lexer:next()
  if self:trymatch(space) then
    return self:next()
  elseif self:trymatch("//") then
    self:trymatch(comment)
    return "comment", self:capture()
  elseif self:trymatch(string_delm) then
    local delm = self:capture()
    local success, errmsg = self:read_string(delm)
    if not success then return false, errmsg end
    return "string", errmsg
  elseif self:trymatch(identifier) then
    local alnum = self:capture()
    if keywords_[alnum] then
      return alnum, alnum
    else
      return "identifier", alnum
    end
  elseif self:trymatch(digit) then
    local snum = self:capture()
    local num = tonumber(snum)
    if num ~= nil then
      return "number", num
    else
      return false, string.format("malformed number '%s'", snum)
    end
  elseif self:trymatch(symbols) then
    local symbol = self:capture()
    return symbol, symbol
  elseif self:trymatch(p(1)) then
    local sym = self:capture()
    return false, string.format("unexpected symbol near %s", sym)
  else
    return "EOF", "EOF"
  end
end

function lexer:lex()
  local type, loc, value
  while true do
    loc = location.new(self.file, self.line, self.col)
    type, value = self:next()
    if not type then
      return false, value
    elseif type == "comment" or type == "space" then
      -- ignore
    else
      return true, token.new(type, value, loc)
    end
  end
  return true, "" -- unreachable
end

return lexer