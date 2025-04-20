local Reserved = require("src.opdef")
local utils = require("src.utils")
local parfast_assert = utils.parfast_assert

Tokentype = {
  Number   = enum(true),
  Ident    = enum(),
  Word     = enum(),
  Operator = enum(),
  String   = enum()
}

local strreserved = {
  ["puts"]     = Reserved.PUTS,
  ["+"]        = Reserved.ADD,
  ["-"]        = Reserved.SUB,
  ["if"]       = Reserved.IF,
  ["end"]      = Reserved.END,
  ["dup"]      = Reserved.DUP,
  ["swap"]     = Reserved.SWAP,
  ["while"]    = Reserved.WHILE,
  ["do"]       = Reserved.DO,
  ["else"]     = Reserved.ELSE,
  ["mbuf"]     = Reserved.MBUF,
  ["st"]       = Reserved.STORE,
  ["ld"]       = Reserved.LOAD,
  ["drop"]     = Reserved.DROP,
  ["macro"]    = Reserved.MACRO,
  ["include"]  = Reserved.INCLUDE,
  ["endm"]     = Reserved.ENDM,
  ["*"]        = Reserved.MUL,
  ["/"]        = Reserved.DIV,
  ["rot"]      = Reserved.ROT,
  ["rst"]      = Reserved.RST,
  ["rld"]      = Reserved.RLD,
  ["extern"]   = Reserved.EXTERN,
  ["call"]     = Reserved.CALL,
  ["elseif"]   = Reserved.ELSEIF,
  ["then"]     = Reserved.THEN,
  ["syscall0"] = Reserved.SYSCALL0,
  ["syscall1"] = Reserved.SYSCALL1,
  ["syscall2"] = Reserved.SYSCALL2,
  ["syscall3"] = Reserved.SYSCALL3,
  ["syscall4"] = Reserved.SYSCALL4,
  ["syscall5"] = Reserved.SYSCALL5,
  ["syscall6"] = Reserved.SYSCALL6,
  ["mem"]      = Reserved.MEM,
  ["argc"]     = Reserved.ARGC,
  ["arv"]      = Reserved.ARGV,
  ["fn"]       = Reserved.FN,
  ["asm"]      = Reserved.ASM,
  ["bind"]     = Reserved.BIND
}

local function lexl(line)
  local tokens = {}
  local src = {}
  local ln = 1

  for i = 1, string.len(line) do
    table.insert(src, line:sub(i, i))
  end

  local function unescape_str(str)
    return str:gsub("\\n", "\n"):gsub("\\t", "\t"):gsub("\\r", "\r"):gsub("\\033", "\027")
  end

  i = 1
  local function shift()
    i = i + 1
    return table.remove(src, 1)
  end

  local function isalpha(char)
    return char and char:match("%a") ~= nil
  end
  local function isdigit(char)
    return char and char:match("%d") ~= nil
  end
  local function isspace(char)
    return char and char == " " or char and char == "\t"
  end
  local function isnewline(char)
    return char and char == "\n" or char and char == "\r"
  end

  while #src > 0 do
    if isalpha(src[1]) then
      local identifier = ""
      local col = i

      while isalpha(src[1]) or src[1] == "_" or src[1] == "-" or isdigit(src[1]) do
        identifier = identifier .. src[1]
        shift()
      end

      if strreserved[identifier] == nil then
        table.insert(tokens, { type = Tokentype.Ident, value = identifier, col = col, line = ln })
      else
        table.insert(tokens, { type = Tokentype.Word, value = identifier, col = col, line = ln })
      end
    elseif isdigit(src[1]) then
      local digit = ""

      local col = i
      while isdigit(src[1]) do
        digit = digit .. tostring(src[1])
        shift()
      end

      table.insert(tokens, { type = Tokentype.Number, value = digit, col = col, line = ln })
    elseif isspace(src[1]) then
      shift()
    elseif isnewline(src[1]) then
      shift()
      ln = ln + 1
      i = 1
    elseif src[1] == "<" then
      table.insert(tokens, { type = Tokentype.Operator, value = "<", col = i, line = ln })
      shift()
    elseif src[1] == "=" then
      if src[2] == "=" then
        table.insert(tokens, { type = Tokentype.Operator, value = "==", col = i, line = ln })
        shift()
        shift()
      else
        table.insert(tokens, { type = Tokentype.Operator, value = "=", col = i, line = ln })
        shift()
      end
    elseif src[1] == ">" then
      table.insert(tokens, { type = Tokentype.Operator, value = ">", col = i, line = ln })
      shift()
    elseif src[1] == "<" then
      table.insert(tokens, { type = Tokentype.Operator, value = "<", col = i, line = ln })
      shift()
    elseif src[1] == "!" then
      if src[2] == "=" then
        table.insert(tokens, { type = Tokentype.Operator, value = "!=", col = i, line = ln })
        shift()
        shift()
      else
        table.insert(tokens, { type = Tokentype.Operator, value = "!", col = i, line = ln })
        shift()
      end
    elseif src[1] == "/" then
      shift()
      if src[1] == "/" then
        while src[1] ~= "\n" and #src > 0 do
          shift()
        end
      end
    elseif src[1] == "+" then
      shift()
      table.insert(tokens, { type = Tokentype.Operator, value = "+", col = i, line = ln })
    elseif src[1] == "-" then
      if not isdigit(src[2]) then
        shift()
        table.insert(tokens, { type = Tokentype.Operator, value = "-", col = i, line = ln })
      else
        shift()
        local digit = "-"

        local col = i
        while isdigit(src[1]) and #src > 0 do
          digit = digit .. tostring(src[1])
          shift()
        end

        table.insert(tokens, { type = Tokentype.Number, value = digit, col = col, line = ln })
      end
    elseif src[1] == "*" then
      shift()
      table.insert(tokens, { type = Tokentype.Operator, value = "*", col = i, line = ln })
    elseif src[1] == "%" then
      shift()
      table.insert(tokens, { type = Tokentype.Operator, value = "%", col = i, line = ln })
    elseif src[1] == "\"" then
      shift() -- opening "
      local str = ""

      while src[1] ~= "\"" and #src > 0 and src[1] ~= "\n" do
        str = str .. src[1]
        shift()
      end
      if src[1] ~= "\"" then
        parfast_assert(false, "Expected '\"' at same line")
      end
      shift() -- closing "

      table.insert(tokens, { type = Tokentype.String, value = unescape_str(str), col = i, line = ln })
    elseif src[1] == "'" then
      shift() -- opening '
      local str = ""

      while src[1] ~= "'" and #src > 0 and src[1] ~= "\n" do
        str = str .. src[1]
        shift()
      end
      if src[1] ~= "'" then
        parfast_assert(false, "Expected \"'\" at same line")
      end
      shift() -- closing '

      table.insert(tokens, { type = Tokentype.String, value = unescape_str(str), col = i, line = ln })
    elseif src[1] == "|" then
      shift() -- opening |
      local str = ""

      while src[1] ~= "|" and #src > 0 do
        str = str .. src[1]
        shift()
      end
      shift() -- closing |

      table.insert(tokens, { type = Tokentype.String, value = unescape_str(str), col = i, line = ln })
    else
      parfast_assert(false, string.format("Cannot recognize char", src[1]))
    end
  end

  return tokens
end

return lexl