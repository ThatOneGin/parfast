counter = 0
function enum(reset)
  if reset == true then counter = 0 end
  local val = counter
  counter = counter + 1
  return val
end

Tokentype = {
  Number   = enum(true),
  Ident    = enum(),
  Word     = enum(),
  Operator = enum(),
  String   = enum
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
  SYSWRITE = enum(),
  SYSEXIT  = enum(),
  MUL      = enum(),
  DIV      = enum()
}

local max_buffer_cap = 124000

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
  ["syswrite"] = Reserved.SYSWRITE,
  ["sysexit"]  = Reserved.SYSEXIT,
  ["include"]  = Reserved.INCLUDE,
  ["*"]        = Reserved.MUL,
  ["/"]        = Reserved.DIV
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
local function syswrite()
  return { Reserved.SYSWRITE }
end
local function sysexit()
  return { Reserved.SYSEXIT }
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

      while isalpha(src[1]) do
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
        digit = digit .. src[1]
        shift()
      end

      table.insert(tokens, { type = Tokentype.Number, value = digit, col = col, line = ln })
    elseif isspace(src[1]) then
      shift()
    elseif isnewline(src[1]) then
      shift()
      ln = ln + 1
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
    end
  end

  return tokens
end

local macros = {}
local paths = {}
function parse(tokens)
  local program = {}
  paths[arg[1]] = true

  local function shift()
    return table.remove(tokens, 1)
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
    elseif tokens[1].value == "mbuf" then
      shift()
      table.insert(program, mbuf())
    elseif tokens[1].value == "drop" then
      shift()
      table.insert(program, drop())
    elseif tokens[1].value == "macro" then
      -- TODO: security mechanism for recursion and stacked macros
      shift()
      local name = shift().value
      local macro = {
        name = name,
        tokens = {}
      }

      while tokens[1].value ~= "end" and #tokens > 1 do
        table.insert(macro.tokens, shift())
      end
      shift()
      macros[macro.name] = macro.tokens
    elseif tokens[1].value == "syswrite" then
      shift()
      table.insert(program, syswrite())
    elseif tokens[1].value == "sysexit" then
      shift()
      table.insert(program, sysexit())
    elseif tokens[1].type == Tokentype.Ident then
      local name = shift().value
      assert(macros[name] ~= nil, "Cannot find macro or keyword named `" .. name .. "`")

      local macrovalue = parse(macros[name])

      for i = 1, #macrovalue do
        table.insert(program, macrovalue[i])
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
      end
    elseif opr[1] == Reserved.WHILE then
      table.insert(ref_stack, i)
    elseif opr[1] == Reserved.ELSE then
      local if_location = table.remove(ref_stack)

      if program[if_location][1] ~= Reserved.IF then
        print("Else is not being used in an if statement.")
        os.exit(1)
      end
      program[if_location] = { Reserved.IF, i + 1 }
      table.insert(ref_stack, i)
    elseif opr[1] == Reserved.DO then
      local while_ref = table.remove(ref_stack)
      program[i] = { Reserved.DO, while_ref }
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

function compile_linux_x86_64(ir, outname)
  local output = io.open(outname .. ".asm", "w+")
  if not output or output == nil then
    return nil
  end

  output:write(
    "puts:\n\tmov	 r9, -3689348814741910323\n\tsub     rsp, 40\n\tmov  BYTE [rsp+31], 10\n\tlea  rcx, [rsp+30]\n")
  output:write(
    ".L2:\n\tmov  rax, rdi\n\tlea  r8, [rsp+32]\n\tmul  r9\n\tmov  rax, rdi\n\tsub  r8, rcx\n\tshr  rdx, 3\n\tlea  rsi, [rdx+rdx*4]\n\tadd  rsi, rsi\n\tsub  rax, rsi\n\tadd  eax, 48\n\tmov  BYTE [rcx], al\n\tmov  rax, rdi\n\tmov  rdi, rdx\n\tmov  rdx, rcx\n\tsub  rcx, 1\n\tcmp  rax, 9\n\tja   .L2\n\tlea  rax, [rsp+32]\n\tmov  edi, 1\n\tsub  rdx, rax\n\tlea  rsi, [rsp+32+rdx]\n\tmov  rdx, r8\n\tmov  rax, 1\n\tsyscall\n\tadd  rsp, 40\n\tret\n")

  output:write("section .bss\n\tmbuf: resb " .. max_buffer_cap .. "\n")
  output:write("section .text\n\tglobal _start\n\n_start:\n")

  local strings = {}
  for i, op in pairs(ir) do
    output:write(string.format("op_%d:\n", i))

    if op[1] == Reserved.PUSH_INT then
      output:write(string.format("\tpush %d\n", op[2]))
    elseif op[1] == Reserved.PUSH_STR then
       table.insert(strings, op[2])
      output:write(string.format("\tpush %d\n\tpush string_%d\n", string.len(op[2]), #strings))
    elseif op[1] == Reserved.ADD then
      output:write("\tpop rax\n\tpop rbx\n\tadd rax, rbx\n\tpush rax\n")
    elseif op[1] == Reserved.SUB then
      output:write("\tpop rax\n\tpop rbx\n\tsub rbx, rax\n\tpush rbx\n")
    elseif op[1] == Reserved.PUTS then
      output:write("\tpop rdi\n\tcall puts\n")
    elseif op[1] == Reserved.IF then
      output:write(string.format("\tpop rax\n\ttest rax, rax\n\tjz op_%d\n", op[2]))
    elseif op[1] == Reserved.END then
      if i + 1 ~= op[2] or i ~= op[2] then
        output:write(string.format("\tjmp op_%d\n", op[2]))
      end
    elseif op[1] == Reserved.DUP then
      output:write("\tpop rax\n\tpush rax\n\tpush rax\n")
    elseif op[1] == Reserved.EQU then
      output:write(
        "\tmov rcx, 0\n\tmov rdx, 1\n\tpop rax\n\tpop rbx\n\tcmp rax, rbx\n\tcmove rcx, rdx\n\tpush rcx\n")
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
      output:write("\tpop rax\n\txor rbx, rbx\n\tmov bl, [rax]\n\tpush rbx\n")
    elseif op[1] == Reserved.STORE then
      output:write("\tpop rbx\n\tpop rax\n\tmov [rax], bl\n")
    elseif op[1] == Reserved.DROP then
      output:write("\tpop rax\n")
    elseif op[1] == Reserved.SYSWRITE then
      output:write("\tpop rax\n\tpop rdi\n\tpop rsi\n\tpop rdx\n\tsyscall\n")
    elseif op[1] == Reserved.SYSEXIT then
      output:write("\tmov rax, 60\n\tpop rdi\n\tsyscall\n")
    else
      print("\27[31;4mError\27[0m:\n\tOperand not recognized or shouldn't be reachable.")
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
local function getfilename(filepath)
  local sfilepath = string.gsub(filepath, ".parfast", "")
  return sfilepath
end

function main()
  local input = io.open(arg[1], "r")
  if not input or input == nil then
    print("Cannot open file, such no directory or lacks permission.")
    os.exit(1)
  end
  local tokens = lexl(input:read("a"))
  local ir = parse(tokens)
  local outname = getfilename(arg[1])
  compile_linux_x86_64(get_references(ir), outname)
  os.execute("nasm -f elf64 " .. outname .. ".asm")
  os.execute(string.format("ld -o %s %s", outname, outname .. ".o"))

  print(string.format("Commands: \n\t[nasm -f elf64 %s.asm]\n\t[ld -o %s %s.o]", outname, outname, outname))
end

main()
