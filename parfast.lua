#!/bin/lua

counter = 0
function enum(reset)
  if reset == true then counter = 0 end
  local val = counter
  counter = counter + 1
  return val
end

local function parfast_assert(expr, errmsg)
  if not expr then
    print(errmsg)
    os.exit(1)
  end
end

Tokentype = {
  Number   = enum(true),
  Ident    = enum(),
  Word     = enum(),
  Operator = enum(),
  String   = enum()
}

Reserved = {
  PUSH_INT = enum(true),
  PUSH_STR = enum(),
  PUTS     = enum(),
  ADD      = enum(),
  SUB      = enum(),
  IF       = enum(),
  END      = enum(),
  EQU      = enum(),
  NEQ      = enum(),
  LT       = enum(),
  GT       = enum(),
  DUP      = enum(),
  SWAP     = enum(),
  WHILE    = enum(),
  DO       = enum(),
  ELSE     = enum(),
  MBUF     = enum(),
  LOAD     = enum(),
  STORE    = enum(),
  DROP     = enum(),
  MACRO    = enum(),
  INCLUDE  = enum(),
  MUL      = enum(),
  DIV      = enum(),
  ENDM     = enum(),
  ROT      = enum(),
  RST      = enum(),
  RLD      = enum(),
  EXTERN   = enum(),
  CALL     = enum(),
  ELSEIF   = enum(),
  THEN     = enum(),
  SYSCALL0 = enum(),
  SYSCALL1 = enum(),
  SYSCALL4 = enum(),
  SYSCALL2 = enum(),
  SYSCALL6 = enum(),
  SYSCALL3 = enum(),
  SYSCALL5 = enum(),
  MEM      = enum(),
  MOD      = enum()
}
-- if you allocate, it will grow
local buffer_offset = 0
local max_buffer_cap = 0

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
  ["mem"]      = Reserved.MEM
}

local function pushint(val)
  return { Reserved.PUSH_INT, val }
end
local function pushstr(val)
  return { Reserved.PUSH_STR, val }
end
local function puts()
  return { Reserved.PUTS }
end
local function add()
  return { Reserved.ADD }
end
local function sub()
  return { Reserved.SUB }
end
local function mul()
  return { Reserved.MUL }
end
local function div()
  return { Reserved.DIV }
end
local function mod()
  return { Reserved.MOD }
end
local function _if()
  return { Reserved.IF }
end
local function _end()
  return { Reserved.END }
end
local function equ()
  return { Reserved.EQU }
end
local function neq()
  return { Reserved.NEQ }
end
local function lt()
  return { Reserved.LT }
end
local function gt()
  return { Reserved.GT }
end
local function dup()
  return { Reserved.DUP }
end
local function swp()
  return { Reserved.SWAP }
end
local function _while()
  return { Reserved.WHILE }
end
local function _do()
  return { Reserved.DO }
end
local function _else()
  return { Reserved.ELSE }
end
local function st()
  return { Reserved.STORE }
end
local function ld()
  return { Reserved.LOAD }
end
local function mbuf()
  return { Reserved.MBUF }
end
local function drop()
  return { Reserved.DROP }
end
local function rot()
  return { Reserved.ROT }
end
local function rst()
  return { Reserved.RST }
end
local function rld()
  return { Reserved.RLD }
end
local function extern(extern_fn)
  return { Reserved.EXTERN, extern_fn }
end
local function call_extern(extern_fn, nargs)
  return { Reserved.CALL, extern_fn , nargs}
end
local function _elseif()
  return { Reserved.ELSEIF }
end
local function _then()
  return { Reserved.THEN }
end
local function syscall0()
  return { Reserved.SYSCALL0 }
end
local function syscall1()
  return { Reserved.SYSCALL1 }
end
local function syscall2()
  return { Reserved.SYSCALL2 }
end
local function syscall3()
  return { Reserved.SYSCALL3 }
end
local function syscall4()
  return { Reserved.SYSCALL4 }
end
local function syscall5()
  return { Reserved.SYSCALL5 }
end
local function syscall6()
  return { Reserved.SYSCALL6 }
end
local function mem(size)
  return { Reserved.MEM, size }
end

local function lexl(line)
  local tokens = {}
  local src = {}
  local ln = 1

  for i = 1, string.len(line) do
    table.insert(src, line:sub(i, i))
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
    return char and char == "\n"
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
      i = 0
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
      shift()
      table.insert(tokens, { type = Tokentype.Operator, value = "-", col = i, line = ln })
    elseif src[1] == "*" then
      shift()
      table.insert(tokens, { type = Tokentype.Operator, value = "*", col = i, line = ln })
    elseif src[1] == "%" then
      shift()
      table.insert(tokens, { type = Tokentype.Operator, value = "%", col = i, line = ln })
    elseif src[1] == "\"" then
      shift() -- opening "
      local str = ""

      while src[1] ~= "\"" and #src > 0 do
        str = str .. src[1]
        shift()
      end
      shift() -- closing "

      table.insert(tokens, { type = Tokentype.String, value = str:gsub("\\n", "\n"), col = i, line = ln })
    elseif src[1] == "'" then
      shift() -- opening "
      local str = ""

      while src[1] ~= "'" and #src > 0 do
        str = str .. src[1]
        shift()
      end
      shift() -- closing "

      table.insert(tokens, { type = Tokentype.String, value = str:gsub("\\n", "\n"), col = i, line = ln })
    else
      print("Cannot recognize char", src[1])
      os.exit(1)
    end
  end

  return tokens
end



local macros = {}
local paths = {}

local function expand_macro(macro_name)
  local expanded_tokens = {}
  local macro_tokens = macros[macro_name]
  for _, token in ipairs(macro_tokens) do
    if token.value == "macro" then
      local nested_macro_name = token.value
      local nested_expanded_tokens = expand_macro(nested_macro_name)
      for _, nested_token in ipairs(nested_expanded_tokens) do
        table.insert(expanded_tokens, nested_token)
      end
    else
      table.insert(expanded_tokens, token)
    end
  end
  return expanded_tokens
end

local memories = {}
function parse(tokens)
  local program = {}
  paths[arg[1]] = true

  local function shift()
    return table.remove(tokens, 1)
  end

  local function subset_eval(stack, tk)
    if tk.type == Tokentype.Number then
      table.insert(stack, tonumber(tk.value))
    elseif tk.value == "+" then
      local a = table.remove(stack)
      local b = table.remove(stack)
      table.insert(stack, b + a)
    elseif tk.value == "*" then
      local a = table.remove(stack)
      local b = table.remove(stack)
      table.insert(stack, b * a)
    else
      parfast_assert(false, "Unsupported tokentype "..tk.value)
    end
  end

  while #tokens > 0 do
    if tokens[1].value == "puts" then
      shift()
      table.insert(program, puts())
    elseif tokens[1].value == "+" then
      shift()
      table.insert(program, add())
    elseif tokens[1].value == "-" then
      shift()
      table.insert(program, sub())
    elseif tokens[1].value == "if" then
      shift()
      table.insert(program, _if())
    elseif tokens[1].value == "end" then
      shift()
      table.insert(program, _end())
    elseif tokens[1].value == "==" then
      shift()
      table.insert(program, equ())
    elseif tokens[1].value == "!=" then
      shift()
      table.insert(program, neq())
    elseif tokens[1].value == ">" then
      shift()
      table.insert(program, gt())
    elseif tokens[1].value == "<" then
      shift()
      table.insert(program, lt())
    elseif tokens[1].value == "dup" then
      shift()
      table.insert(program, dup())
    elseif tokens[1].value == "swap" then
      shift()
      table.insert(program, swp())
    elseif tokens[1].value == "while" then
      shift()
      table.insert(program, _while())
    elseif tokens[1].value == "do" then
      shift()
      table.insert(program, _do())
    elseif tokens[1].value == "else" then
      shift()
      table.insert(program, _else())
    elseif tokens[1].value == "st" then
      shift()
      table.insert(program, st())
    elseif tokens[1].value == "ld" then
      shift()
      table.insert(program, ld())
    elseif tokens[1].value == "rst" then
      shift()
      table.insert(program, rst())
    elseif tokens[1].value == "rld" then
      shift()
      table.insert(program, rld())
    elseif tokens[1].value == "mbuf" then
      shift()
      table.insert(program, mbuf())
    elseif tokens[1].value == "drop" then
      shift()
      table.insert(program, drop())
    elseif tokens[1].value == "extern" then
      shift()
      table.insert(program, extern(shift().value))
    elseif tokens[1].value == "call" then
      shift()
      local name = shift().value
      local nargs = shift().value
      assert(tonumber(nargs) ~= nil, "Number of args of a extern call must be a number.")
      table.insert(program, call_extern(name, tonumber(nargs)))
    elseif tokens[1].value == "syscall0" then
      shift()
      table.insert(program, syscall0())
    elseif tokens[1].value == "syscall1" then
      shift()
      table.insert(program, syscall1())
    elseif tokens[1].value == "syscall2" then
      shift()
      table.insert(program, syscall2())
    elseif tokens[1].value == "syscall3" then
      shift()
      table.insert(program, syscall3())
    elseif tokens[1].value == "syscall4" then
      shift()
      table.insert(program, syscall4())
    elseif tokens[1].value == "syscall5" then
      shift()
      table.insert(program, syscall5())
    elseif tokens[1].value == "syscall6" then
      shift()
      table.insert(program, syscall6())
    elseif tokens[1].value == "macro" then
      -- TODO: security mechanism for recursion and stacked macros
      shift()
      local name = shift().value
      local macro = {
        name = name,
        tokens = {}
      }

      while tokens[1].value ~= "endm" and #tokens > 1 do
        table.insert(macro.tokens, shift())
      end
      shift()
      macros[macro.name] = macro.tokens
    elseif tokens[1].value == "*" then
      shift()
      table.insert(program, mul())
    elseif tokens[1].value == "/" then
      shift()
      table.insert(program, div())
    elseif tokens[1].value == "rot" then
      shift()
      table.insert(program, rot())
    elseif macros[tokens[1].value] then
      local macro_name = shift().value
      local expanded_tokens = parse(expand_macro(macro_name))
      for _, token in ipairs(expanded_tokens) do
        table.insert(program, token)
      end
    elseif tokens[1].type == Tokentype.Number then
      local val = shift().value
      table.insert(program, pushint(val))
    elseif tokens[1].type == Tokentype.String then
      local val = shift().value
      table.insert(program, pushstr(val))
    elseif tokens[1].value == "include" then
      -- todo: security mechanism for recursion
      shift()
      local path = shift()
      if path.type ~= Tokentype.String then
        print("Expected string for filepath, got", path.type)
        os.exit(1)
      end
      if paths[path.value] then
        shift()
        goto continue
      else
        paths[path.value] = true
      end
      local file = io.open(path.value, "r")
      if not file or file == nil then
        print("Cannot include file, exiting")
        os.exit(1)
      end
      local i_tokens = parse(lexl(file:read("a")))
      for i = 1, #i_tokens do
        table.insert(program, i_tokens[i])
      end
      file:close()
    elseif tokens[1].value == "elseif" then
      shift()
      table.insert(program, _elseif())
    elseif tokens[1].value == "then" then
      shift()
      table.insert(program, _then())
    elseif tokens[1].value == "mem" then
      shift()
      local memory = shift()
      
      parfast_assert(memory.type == Tokentype.Ident, string.format("Expected memory name to be a word got '%s'. ", memory.value))
      parfast_assert(macros[memory.value] == nil, string.format("Trying to redefine a macro. '%s'", memory.value))
      parfast_assert(memories[memory.value] == nil, string.format("%d:%d Trying to redefine a memory region. '%s'", memory.line, memory.col, memory.value))
      
      local stack = {}

      while tokens[1].value ~= "end" do
        local op = shift()
        if op.type == Tokentype.Operator or op.type == Tokentype.Number then
          subset_eval(stack, op)
        elseif macros[op.value] ~= nil and op.type == Tokentype.Ident then
          local expanded_tokens = expand_macro(op.value)
          for i, v in pairs(expanded_tokens) do
            subset_eval(stack, v)
          end
        else
          parfast_assert(false, string.format("type not supported %s", op.value))
        end
      end
      shift()

      parfast_assert(#stack > 0, "Memory allocation expects one integer value. got "..#stack)
      local mem_to_grow = table.remove(stack)
      memories[memory.value] = buffer_offset
      max_buffer_cap = max_buffer_cap + mem_to_grow + buffer_offset
      buffer_offset = buffer_offset + mem_to_grow
    elseif memories[tokens[1].value] ~= nil then
      table.insert(program, mem(memories[tokens[1].value]))
      shift()
    elseif tokens[1].value == "%" then
      table.insert(program, mod())
      shift()
    else
      print(string.format("\027[31mERROR\027[0m:Unknown keyword %s", tokens[1].value))
      os.exit(1)
    end

    ::continue::
  end

  return program
end

local function get_references(program)
  ref_stack = {}

  for i = 1, #program do
    local opr = program[i]

    if opr[1] == Reserved.IF then
      table.insert(ref_stack, i)
    elseif opr[1] == Reserved.END then
      local end_block = table.remove(ref_stack)

      if program[end_block][1] == Reserved.IF or program[end_block][1] == Reserved.ELSE then
        program[end_block] = { program[end_block][1], i }
        program[i] = { Reserved.END, i + 1 }
      elseif program[end_block][1] == Reserved.DO then
        program[i] = { Reserved.END, program[end_block][2] }
        program[end_block] = { Reserved.DO, i + 1 }
      elseif program[end_block][1] == Reserved.THEN then
        local p_end = program[end_block][2]
        if program[p_end][1] == Reserved.ELSEIF then
          program[p_end][2] = i
          program[i][2] = i + 1
          program[end_block][2] = i + 1
        elseif program[p_end][1] == Reserved.IF then
          program[i][2] = i + 1
          program[end_block][2] = i + 1
        else
          print("'then' can only be used in if-elseif-else blocks")
          os.exit(1)
        end
      end
    elseif opr[1] == Reserved.WHILE then
      table.insert(ref_stack, i)
    elseif opr[1] == Reserved.ELSE then
      local if_location = table.remove(ref_stack)

      if program[if_location][1] ~= Reserved.THEN then
        print("'else' can only be used in if-elseif-then blocks.")
        os.exit(1)
      end
      local pre_if = program[if_location][2]

      if program[pre_if][1] == Reserved.IF then
        program[if_location][2] = i + 1
        table.insert(ref_stack, i)
      elseif program[pre_if][1] == Reserved.ELSEIF then
        program[pre_if][2] = i
        program[if_location][2] = i + 1
        table.insert(ref_stack, i)
      else
        print("'else' is not closing 'then' block preceded by if-elseif.")
        os.exit(1)
      end
    elseif opr[1] == Reserved.DO then
      local while_ref = table.remove(ref_stack)
      program[i] = { Reserved.DO, while_ref }
      table.insert(ref_stack, i)
    elseif opr[1] == Reserved.ELSEIF then
      local then_ip = table.remove(ref_stack)

      if program[then_ip][1] ~= Reserved.THEN then
        print("'elseif' can only close 'then' blocks.")
        os.exit(1)
      end
      local p_ip = program[then_ip][2]

      if program[p_ip][1] == Reserved.ELSEIF then
        program[then_ip][2] = i + 1
        program[p_ip][2] = i
        table.insert(ref_stack, i)
      elseif program[p_ip][1] == Reserved.IF then
        program[then_ip][2] = i + 1
        table.insert(ref_stack, i)
      else
        print("'elseif' can only close 'if-then' blocks.")
        os.exit(1)
      end
    elseif opr[1] == Reserved.THEN then
      local then_ref = table.remove(ref_stack)
      program[i][2] = then_ref
      table.insert(ref_stack, i)
    end
  end

  return program
end

local function hex(str)
  local hex = {}
  for i = 1, #str do
    local byte = string.byte(str, i)
    table.insert(hex, "0x" .. string.format("%02X", byte))
  end
  return table.concat(hex, ",")
end

local function bool_to_number(value)
  return value and 1 or 0
end

function run_program(ir)
  local stack = {}
  local memory_buffer = {}

  -- no need to do syscalls here as this interpretation is only for testing code.
  
  for i=1, #ir do
    local op = ir[i]

    if op[1] == Reserved.PUSH_INT then
      table.insert(stack, tonumber(op[2]))
    elseif op[1] == Reserved.ADD then
      local a = table.remove(stack)
      local b = table.remove(stack)

      table.insert(stack, a + b)
    elseif op[1] == Reserved.PUSH_STR then
      table.insert(stack, op[2])
    elseif op[1] == Reserved.SUB then
      local a = table.remove(stack)
      local b = table.remove(stack)

      table.insert(stack, b - a)
    elseif op[1] == Reserved.DIV then
      local a = table.remove(stack)
      local b = table.remove(stack)

      table.insert(stack, b / a)
    elseif op[1] == Reserved.MUL then
      local a = table.remove(stack)
      local b = table.remove(stack)

      table.insert(stack, b * a)
    elseif op[1] == Reserved.PUTS then
      print(table.remove(stack))
    elseif op[1] == Reserved.GT then
      local a = table.remove(stack)
      local b = table.remove(stack)

      table.insert(stack, bool_to_number(a > b))
    elseif op[1] == Reserved.LT then
      local a = table.remove(stack)
      local b = table.remove(stack)

      table.insert(stack, bool_to_number(b < a))
    elseif op[1] == Reserved.DUP then
      local a = table.remove(stack)
      table.insert(stack, a)
      table.insert(stack, a)
    elseif op[1] == Reserved.DROP then
      table.remove(stack)
    elseif op[1] == Reserved.EQU then
      local a = table.remove(stack)
      local b = table.remove(stack)

      table.insert(stack, bool_to_number(a == b))
    elseif op[1] == Reserved.NEQ then
      local a = table.remove(stack)
      local b = table.remove(stack)

      table.insert(stack, bool_to_number(a ~= b))
    elseif op[1] == Reserved.SWAP then
      local a = table.remove(stack)
      local b = table.remove(stack)
      table.insert(stack, a)
      table.insert(stack, b)
    elseif op[1] == Reserved.ROT then
      local a = table.remove(stack)
      local b = table.remove(stack)
      local c = table.remove(stack)
      table.insert(stack, b)
      table.insert(stack, a)
      table.insert(stack, c)
    elseif op[1] == Reserved.IF then
      local cd = table.remove(stack)
      if cd == 0 then
        i = op[2]
      end
    elseif op[1] == Reserved.ELSE then
      i = op[2]
    elseif op[1] == Reserved.END then
      i = op[2]
    elseif op[1] == Reserved.WHILE then
    elseif op[1] == Reserved.DO then
      if table.remove(stack) == 0 then
        i = op[2]
      end
    end
  end
end

function compile_linux_x86_64(ir, outname)
  local register_args_table = {"rdi", "rsi", "rdx", "rcx", "r8", "r9"}

  local output = io.open(outname .. ".asm", "w+")
  if not output or output == nil then
    return nil
  end
  output:write("BITS 64\n")
  output:write(
    "puts:\n\tmov	 r9, -3689348814741910323\n\tsub     rsp, 40\n\tmov  BYTE [rsp+31], 10\n\tlea  rcx, [rsp+30]\n")
  output:write(
    ".L2:\n\tmov  rax, rdi\n\tlea  r8, [rsp+32]\n\tmul  r9\n\tmov  rax, rdi\n\tsub  r8, rcx\n\tshr  rdx, 3\n\tlea  rsi, [rdx+rdx*4]\n\tadd  rsi, rsi\n\tsub  rax, rsi\n\tadd  eax, 48\n\tmov  BYTE [rcx], al\n\tmov  rax, rdi\n\tmov  rdi, rdx\n\tmov  rdx, rcx\n\tsub  rcx, 1\n\tcmp  rax, 9\n\tja   .L2\n\tlea  rax, [rsp+32]\n\tmov  edi, 1\n\tsub  rdx, rax\n\tlea  rsi, [rsp+32+rdx]\n\tmov  rdx, r8\n\tmov  rax, 1\n\tsyscall\n\tadd  rsp, 40\n\tret\n")

  output:write("section .bss\n\tmbuf: resb " .. max_buffer_cap .. "\n")
  output:write("section .text\n\tglobal _start\n\n_start:\n")

  local strings = {}
  local extern_fns = {}
  for i, op in pairs(ir) do
    output:write(string.format("op_%d:\n", i))

    if op[1] == Reserved.PUSH_INT then
      output:write(string.format("\tpush %d\n", op[2]))
    elseif op[1] == Reserved.PUSH_STR then
      table.insert(strings, op[2])
      output:write(string.format("\tpush %d\n\tpush string_%d\n", string.len(op[2]), #strings))
    elseif op[1] == Reserved.CALL then
      if op[3] > 0 then
        assert(op[3] <= #register_args_table)
        for i = 1, op[3] do
          output:write(string.format("\tpop %s\n", register_args_table[i]))
        end
      end
      output:write(string.format("\tcall %s\n", extern_fns[op[2]]))
    elseif op[1] == Reserved.EXTERN then
      output:write(string.format("\textern %s\n", op[2]))
      extern_fns[op[2]] = op[2]
    elseif op[1] == Reserved.ADD then
      output:write("\tpop rax\n\tpop rbx\n\tadd rax, rbx\n\tpush rax\n")
    elseif op[1] == Reserved.SUB then
      output:write("\tpop rax\n\tpop rbx\n\tsub rbx, rax\n\tpush rbx\n")
    elseif op[1] == Reserved.MUL then
       output:write("\tpop rax\n\tpop rbx\n\tmul rbx\n\tpush rax\n")
    elseif op[1] == Reserved.DIV then
       output:write("\tpop rax\n\tpop rbx\n\tdiv rbx\n\tpush rax\n")
    elseif op[1] == Reserved.PUTS then
      output:write("\tpop rdi\n\tcall puts\n")
    elseif op[1] == Reserved.IF then
      output:write("\t; if\n")
    elseif op[1] == Reserved.END then
      if i + 1 ~= op[2] or i ~= op[2] then
        output:write(string.format("\tjmp op_%d\n", op[2]))
      end
    elseif op[1] == Reserved.DUP then
      output:write("\tpop rax\n\tpush rax\n\tpush rax\n")
    elseif op[1] == Reserved.EQU then
      output:write("\tmov rcx, 0\n\tmov rdx, 1\n\tpop rax\n\tpop rbx\n\tcmp rax, rbx\n\tcmove rcx, rdx\n\tpush rcx\n")
    elseif op[1] == Reserved.NEQ then
      output:write(
        "\tmov rcx, 1\n\tmov rdx, 0\n\tpop rax\n\tpop rbx\n\tcmp rax, rbx\n\tcmove rcx, rdx\n\tpush rcx\n")
    elseif op[1] == Reserved.GT then
      output:write(
        "\tmov rcx, 0\n\tmov rdx, 1\n\tpop rbx\n\tpop rax\n\tcmp rax, rbx\n\tcmovg rcx, rdx\n\tpush rcx\n")
    elseif op[1] == Reserved.LT then
      output:write(
        "\tmov rcx, 0\n\tmov rdx, 1\n\tpop rbx\n\tpop rax\n\tcmp rax, rbx\n\tcmovl rcx, rdx\n\tpush rcx\n")
    elseif op[1] == Reserved.SWAP then
      output:write("\tpop rax\n\tpop rbx\n\tpush rax\n\tpush rbx\n")
    elseif op[1] == Reserved.WHILE then
      output:write("\t; while\n")
    elseif op[1] == Reserved.DO then
      output:write(string.format("\tpop rax\n\ttest rax, rax\n\tjz op_%d\n", op[2]))
    elseif op[1] == Reserved.ELSE then
      output:write(string.format("\tjmp op_%d\n", op[2]))
    elseif op[1] == Reserved.MBUF then
      output:write("\tpush mbuf\n")
    elseif op[1] == Reserved.LOAD then
      output:write("\tpop rax\n\tpop rbx\n\tmov [rax], rbx\n")
    elseif op[1] == Reserved.STORE then
      output:write("\tpop rbx\n\tpop rax\n\tmov [rax], rbx\n")
    elseif op[1] == Reserved.DROP then
      output:write("\tpop rax\n")
    elseif op[1] == Reserved.ROT then
      output:write("\tpop rax\n\tpop rbx\n\tpop rcx\n\tpush rbx\n\tpush rax\n\tpush rcx\n")
    elseif op[1] == Reserved.RST then
      output:write("\tpop rax\n\tpop rbx\n\tmov [rax], rbx\n")
    elseif op[1] == Reserved.SYSWRITE then
      output:write("\tpop rax\n\tpop rdi\n\tpop rsi\n\tpop rdx\n\tsyscall\n")
    elseif op[1] == Reserved.SYSEXIT then
      output:write("\tmov rax, 60\n\tpop rdi\n\tsyscall\n")
    elseif op[1] == Reserved.RLD then
      output:write("\tpop rax\n\txor rbx, rbx\n\tmov rbx, [rax]\n\tpush rbx\n")
    elseif op[1] == Reserved.THEN then
      output:write(string.format("\tpop rax\n\ttest rax, rax\n\tjz op_%d\n", op[2]))
    elseif op[1] == Reserved.ELSEIF then
      output:write(string.format("\tjmp op_%d\n", op[2]))
    elseif op[1] == Reserved.SYSCALL0 then
      output:write("\tpop rax\nsyscall\npush rax\n")
    elseif op[1] == Reserved.SYSCALL1 then
      output:write("\tpop rax\npop rdi\nsyscall\npush rax\n")
    elseif op[1] == Reserved.SYSCALL2 then
      output:write("\tpop rax\npop rdi\npop rsi\nsyscall\npush rax\n")
    elseif op[1] == Reserved.SYSCALL3 then
      output:write("\tpop rax\npop rdi\npop rsi\npop rdx\nsyscall\npush rax\n")
    elseif op[1] == Reserved.SYSCALL4 then
      output:write("\tpop rax\npop rdi\npop rsi\npop rdx\npop rcx\nsyscall\npush rax\n")
    elseif op[1] == Reserved.SYSCALL5 then
      output:write("\tpop rax\npop rdi\npop rsi\npop rdx\npop rcx\npop r8\nsyscall\npush rax\n")
    elseif op[1] == Reserved.SYSCALL6 then
      output:write("\tpop rax\npop rdi\npop rsi\npop rdx\npop rcx\npop r8\npop r9\nsyscall\npush rax\n")
    elseif op[1] == Reserved.MEM then
      output:write(string.format("\tmov rax, mbuf\n\tadd rax, %d\n\tpush rax\n", op[2]))
    elseif op[1] == Reserved.MOD then
      output:write("\tpop rax\n\tpop rbx\n\txor rdx, rdx\n\tdiv rbx\n\tpush rax\n\tpush rdx\n")
    else
      print("\27[31;4mError\27[0m:\n\tOperand not recognized or shouldn't be reachable.", op[1])
      os.exit(1)
    end
  end

  output:write(string.format("op_%d:\n", #ir + 1))
  output:write("\tmov rax, 60\n\tmov rdi, 0\n\tsyscall\n")
  --unfortunately i need to write data section here because of strings
  output:write("section .data\n")
  for i, str in pairs(strings) do
    output:write(string.format("string_%d: db %s\n", i, hex(str)))
  end
  output:close()
end

-- Extension should be .parfast
local function remove_file_extension(filepath)
  local sfilepath = string.gsub(filepath, "%.([^\\/%.]-)%.?$", "")
  return sfilepath
end

local function parse_args()
  local i = 1
  local flags = {}

  while i <= #arg do
    local flag_or_file = arg[i]

    if flag_or_file:sub(1, 1) == "-" then
      flags[flag_or_file] = true
    else
      flags["-file"] = flag_or_file
    end
    i = i + 1
  end

  return flags
end

function main()
  parfast_assert(#arg > 0, "Usage: parfast <input.parfast> -com/-run/-obj\n\n\t\027[31mERROR\027[0m: not enough arguments.")
  local flags = parse_args()
  parfast_assert(flags["-file"] ~= nil, "\027[31mERROR\027[0m: No input file provided.")
  local input = io.open(flags["-file"], "r")

  if not input or input == nil then
    print("Cannot open file, such no directory or lacks permission.")
    os.exit(1)
  end

  local tokens = lexl(input:read("a"))
  local ir = parse(tokens)
  local outname = remove_file_extension(flags["-file"])

  if flags["-com"] then
    compile_linux_x86_64(get_references(ir), outname)
    os.execute("nasm -f elf64 "..outname..".asm")
    os.execute(string.format("ld -o %s %s.o", outname, outname))
  end
  if flags["-run"] then
    run_program(get_references(ir))
    os.exit(0)
  end
  if flags["-obj"] then
    os.execute("nasm -f elf64 "..flags["-file"])
  end
  if not flags["-silent"] then
    print("\027[33m[1/2]\027[0m nasm -f elf64 \027[32m"..flags["-file"].."\027[0m")
    print(string.format("\027[32m[2/2]\027[0m ld -o \027[32m%s\027[0m %s.o", outname, outname))
  end
end

main()
