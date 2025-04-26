local function pushint(val) return { Reserved.PUSH_INT, val } end
local function pushstr(val) return { Reserved.PUSH_STR, val } end
local function extern(extern_fn) return { Reserved.EXTERN, extern_fn } end
local function call_extern(extern_fn, nargs) return { Reserved.CALL, extern_fn, nargs } end
local function fn_call(ip, name) return { Reserved.FN_CALL, ip, name } end
local function mem(size) return { Reserved.MEM, size } end
local function asm(code) return { Reserved.ASM, code } end

local puts     = { Reserved.PUTS }
local add      = { Reserved.ADD }
local sub      = { Reserved.SUB }
local mul      = { Reserved.MUL }
local div      = { Reserved.DIV }
local mod      = { Reserved.MOD }
local _if      = { Reserved.IF }
local _end     = { Reserved.END }
local equ      = { Reserved.EQU }
local neq      = { Reserved.NEQ }
local lt       = { Reserved.LT }
local gt       = { Reserved.GT }
local dup      = { Reserved.DUP }
local swap     = { Reserved.SWAP }
local _while   = { Reserved.WHILE }
local _do      = { Reserved.DO }
local _else    = { Reserved.ELSE }
local store    = { Reserved.STORE }
local _load    = { Reserved.LOAD }
local mbuf     = { Reserved.MBUF }
local drop     = { Reserved.DROP }
local rot      = { Reserved.ROT }
local rst      = { Reserved.RST }
local rld      = { Reserved.RLD }
local _elseif  = { Reserved.ELSEIF }
local _then    = { Reserved.THEN }
local syscall0 = { Reserved.SYSCALL0 }
local syscall1 = { Reserved.SYSCALL1 }
local syscall2 = { Reserved.SYSCALL2 }
local syscall3 = { Reserved.SYSCALL3 }
local syscall4 = { Reserved.SYSCALL4 }
local syscall5 = { Reserved.SYSCALL5 }
local syscall6 = { Reserved.SYSCALL6 }
local argc     = { Reserved.ARGC }
local argv     = { Reserved.ARGV }
local fn       = { Reserved.FN }

local buffer_offset = 0
local max_buffer_cap = 0
local be_offset = 0
local macros = {}
local paths = {}
local memories = {}
local functions = {}
local bes = {}

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
      parfast_assert(false, string.format("%d:%d Unsupported tokentype %s", tk.line, tk.col, tk.value))
    end
  end

  local ip = 1
  local is_fn_declaration = false

  local is_if_stmt = false
  local is_else_stmt = false
  local is_while_stmt = false
  local is_elseif_stmt = false
  local is_be_stmt = false

  local fn_declaration_name = ""
  while #tokens > 0 do
    ip = #program + 1
    if tokens[1].value == "puts" then
      shift()
      table.insert(program, puts)
    elseif tokens[1].value == "+" then
      shift()
      table.insert(program, add)
    elseif tokens[1].value == "-" then
      shift()
      table.insert(program, sub)
    elseif tokens[1].value == "if" then
      is_if_stmt = true
      shift()
      table.insert(program, _if)
    elseif tokens[1].value == "end" then
      shift()
      table.insert(program, _end)

      if is_else_stmt then
        is_else_stmt = false
      elseif is_while_stmt then
        is_while_stmt = false
      elseif is_if_stmt then
        is_if_stmt = false
      elseif is_elseif_stmt then
        is_elseif_stmt = false
      elseif is_be_stmt then
        is_be_stmt = false
        be_offset = 0
        bes = {}
      else
        is_fn_declaration = false
        fn_declaration_name = ""
      end
    elseif tokens[1].value == "==" then
      shift()
      table.insert(program, equ)
    elseif tokens[1].value == "!=" then
      shift()
      table.insert(program, neq)
    elseif tokens[1].value == ">" then
      shift()
      table.insert(program, gt)
    elseif tokens[1].value == "<" then
      shift()
      table.insert(program, lt)
    elseif tokens[1].value == "dup" then
      shift()
      table.insert(program, dup)
    elseif tokens[1].value == "swap" then
      shift()
      table.insert(program, swap)
    elseif tokens[1].value == "while" then
      is_while_stmt = true
      shift()
      table.insert(program, _while)
    elseif tokens[1].value == "do" then
      shift()
      table.insert(program, _do)
    elseif tokens[1].value == "else" then
      is_else_stmt = true
      shift()
      table.insert(program, _else)
    elseif tokens[1].value == "st" then
      shift()
      table.insert(program, store)
    elseif tokens[1].value == "ld" then
      shift()
      table.insert(program, _load)
    elseif tokens[1].value == "rst" then
      shift()
      table.insert(program, rst)
    elseif tokens[1].value == "rld" then
      shift()
      table.insert(program, rld)
    elseif tokens[1].value == "mbuf" then
      shift()
      table.insert(program, mbuf)
    elseif tokens[1].value == "drop" then
      shift()
      table.insert(program, drop)
    elseif tokens[1].value == "extern" then
      shift()
      table.insert(program, extern(shift().value))
    elseif tokens[1].value == "call" then
      local report = shift()
      local name = shift().value
      local nargs = shift().value
      assert(tonumber(nargs) ~= nil,
        string.format("%d:%d Number of args of a extern call must be a number.", report.line, report.col))
      table.insert(program, call_extern(name, tonumber(nargs)))
    elseif tokens[1].value == "syscall0" then
      shift()
      table.insert(program, syscall0)
    elseif tokens[1].value == "syscall1" then
      shift()
      table.insert(program, syscall1)
    elseif tokens[1].value == "syscall2" then
      shift()
      table.insert(program, syscall2)
    elseif tokens[1].value == "syscall3" then
      shift()
      table.insert(program, syscall3)
    elseif tokens[1].value == "syscall4" then
      shift()
      table.insert(program, syscall4)
    elseif tokens[1].value == "syscall5" then
      shift()
      table.insert(program, syscall5)
    elseif tokens[1].value == "syscall6" then
      shift()
      table.insert(program, syscall6)
    elseif tokens[1].value == "macro" then
      local lncol = { tokens[1].line, tokens[1].col }
      shift()
      local name = shift()

      parfast_assert(name ~= nil, string.format(
        "%d:%d Expected token of type Identifier, but got EOF", lncol[1], lncol[2]))

      parfast_assert(name.type == Tokentype.Ident,
        string.format("%d:%d Expected macro name to be a word.", name.line, name.col))
      parfast_assert(macros[name.value] == nil,
        string.format("%d:%d Trying to redefine a macro. '%s'", lncol[1], lncol[2], name.value))

      local macro = {
        name = name.value,
        tokens = {}
      }

      parfast_assert(#tokens > 0,
        string.format("%d:%d Expected macro body, but got EOF", lncol[1], lncol[2]))

      while tokens[1].value ~= "endm" and #tokens > 0 do
        table.insert(macro.tokens, shift())
      end
      parfast_assert(tokens[1].value == "endm",
        string.format("%d:%d Expected `endm` to close macro definition", lncol[1], lncol[2]))
      shift()
      macros[macro.name] = macro.tokens
    elseif tokens[1].value == "*" then
      shift()
      table.insert(program, mul)
    elseif tokens[1].value == "/" then
      shift()
      table.insert(program, div)
    elseif tokens[1].value == "rot" then
      shift()
      table.insert(program, rot)
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
      local includepos = { tokens[1].line, tokens[1].col }
      shift()
      local path = shift()

      parfast_assert(path ~= nil, string.format("%d:%d Expected token of type string, but got EOF",
        includepos[1], includepos[2]))
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
      is_elseif_stmt = true
      shift()
      table.insert(program, _elseif)
    elseif tokens[1].value == "then" then
      shift()
      table.insert(program, _then)
    elseif tokens[1].value == "mem" then
      local lncol = { tokens[1].line, tokens[1].col }
      shift()
      local memory = shift()

      parfast_assert(memory ~= nil,
        string.format("%d:%d Expected region name, but got EOF", lncol[1], lncol[2]))
      parfast_assert(memory.type == Tokentype.Ident,
        string.format("%d:%d Expected memory name to be a word got '%s'. ", memory.line, memory.col, memory.value))
      parfast_assert(macros[memory.value] == nil,
        string.format("%d:%d Trying to redefine a macro. '%s'", memory.line, memory.col, memory.value))
      parfast_assert(memories[memory.value] == nil,
        string.format("%d:%d Trying to redefine a memory region. '%s'", memory.line, memory.col, memory.value))

      local stack = {}

      parfast_assert(#tokens > 0,
        string.format("%d:%d Expected region body, but got EOF", lncol[1], lncol[2]))

      while #tokens > 0 and tokens[1].value ~= "end" do
        local op = shift()
        if op.type == Tokentype.Operator or op.type == Tokentype.Number then
          subset_eval(stack, op)
        elseif macros[op.value] ~= nil and op.type == Tokentype.Ident then
          local expanded_tokens = expand_macro(op.value)
          for i, v in pairs(expanded_tokens) do
            subset_eval(stack, v)
          end
        else
          parfast_assert(false, string.format("%d:%d type/operation not supported '%s'", op.line, op.col, op.value))
        end
      end

      parfast_assert(#tokens > 0,
        string.format("%d:%d Expected `end` to close region definition, but got EOF", lncol[1], lncol[2]))
      parfast_assert(tokens[1].value == "end",
        string.format("%d:%d Expected `end` to close region definition, but got EOF", lncol[1], lncol[2]))
      shift()
      parfast_assert(#stack > 0, "Memory allocation expects one integer value. got " .. #stack)
      if not is_fn_declaration then
        local mem_to_grow = table.remove(stack)
        memories[memory.value] = buffer_offset
        max_buffer_cap = max_buffer_cap + mem_to_grow + buffer_offset
        buffer_offset = buffer_offset + mem_to_grow
      else
        local mem_to_grow = table.remove(stack)
        functions[fn_declaration_name][2][memory.value] = functions[fn_declaration_name][4]
        functions[fn_declaration_name][3] = functions[fn_declaration_name][3] + mem_to_grow +
            functions[fn_declaration_name][4]
        functions[fn_declaration_name][4] = functions[fn_declaration_name][4] + mem_to_grow
      end
    elseif memories[tokens[1].value] ~= nil then
      table.insert(program, mem(memories[tokens[1].value]))
      shift()
    elseif is_fn_declaration and functions[fn_declaration_name][2][tokens[1].value] ~= nil then
      shift()
      table.insert(program, { Reserved.LOCAL_MEM, functions[fn_declaration_name][4] })
    elseif tokens[1].value == "%" then
      table.insert(program, mod)
      shift()
    elseif tokens[1].value == "argc" then
      shift()
      table.insert(program, argc)
    elseif tokens[1].value == "argv" then
      shift()
      table.insert(program, argv)
    elseif tokens[1].value == "fn" then
      if is_fn_declaration then
        parfast_assert(false,
          string.format("%d:%d Nested function declaration is not allowed.", tokens[1].line, tokens[1].col))
      end
      is_fn_declaration = true

      local lncol = { tokens[1].line, tokens[1].col }
      local types = {}
      shift()

      parfast_assert(#tokens > 0,
        string.format("%d:%d Expected function name.", lncol[1], lncol[2]))
      local name = shift()
      parfast_assert(name.type == Tokentype.Ident,
        string.format("%d:%d Expected function name to be a word.", lncol[1], lncol[2]))

      table.insert(program, fn)
      table.insert(program, { Reserved.FN_BODY, nil, name.value})

      while #tokens > 0 and tokens[1].value ~= "with" do
        table.insert(types, shift().value)
      end
      local with = shift()
      parfast_assert(with ~= nil, "Expected `with` keyword to end function declaration.")

      functions[name.value] = { ip + 1, {}, 0, 0, types }
      fn_declaration_name = name.value
    elseif functions[tokens[1].value] ~= nil then
      table.insert(program, fn_call(functions[tokens[1].value][1], tokens[1].value))
      shift()
    elseif tokens[1].value == "asm" then
      shift()
      local code = shift()
      parfast_assert(code.type == Tokentype.String, "Expected asm code to be a string.")
      table.insert(program, asm(code.value))
    elseif tokens[1].value == "bind" then
      shift()

      local be_count = 0
      while tokens[1].value ~= "in" do
        bes[tokens[1].value] = be_offset
        be_offset = be_offset + 8 -- sizeof uintptr_t
        shift()
        be_count = be_count + 1
      end
      parfast_assert(tokens[1].value == "in", "Missing `in` keyword in be-stmt")
      shift()
      table.insert(program, { Reserved.IN, be_offset, be_count })
    elseif bes[tokens[1].value] ~= nil then
      table.insert(program, { Reserved.PUSHBIND, bes[tokens[1].value] })
      shift()
    elseif tokens[1].value == "castptr" then
      shift()
      table.insert(program, { Reserved.CAST_PTR })
    elseif tokens[1].value == "castint" then
      shift()
      table.insert(program, { Reserved.CAST_INT })
    elseif tokens[1].value == "castbool" then
      shift()
      table.insert(program, { Reserved.CAST_BOOL })
    elseif tokens[1].value == "caststr" then
      shift()
      table.insert(program, { Reserved.CAST_STR })
    else
      parfast_assert(false, string.format("Unknown keyword %s", tokens[1].value))
    end

    ::continue::
  end

  return program
end

function get_references(program)
  local ref_stack = {}
  local call_stack = {}

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
          parfast_assert(false, "'then' can only be used in if-elseif-else blocks")
        end
      elseif program[end_block][1] == Reserved.FN_BODY then
        program[end_block][2] = i + 1
        end_block = table.remove(ref_stack)
        program[end_block][2] = i + 1
        program[i] = { Reserved.RET, i + 1 }
      elseif program[end_block][1] == Reserved.IN then
        program[i] = { Reserved.ENDBIND, program[end_block][2] }
      end
    elseif opr[1] == Reserved.WHILE then
      table.insert(ref_stack, i)
    elseif opr[1] == Reserved.ELSE then
      local if_location = table.remove(ref_stack)

      if program[if_location][1] ~= Reserved.THEN then
        parfast_assert(false, "'else' can only be used in if-elseif-then blocks.")
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
        parfast_assert(false, "'else' is not closing 'then' block preceded by if-elseif.")
      end
    elseif opr[1] == Reserved.DO then
      local while_ref = table.remove(ref_stack)
      program[i] = { Reserved.DO, while_ref }
      table.insert(ref_stack, i)
    elseif opr[1] == Reserved.ELSEIF then
      local then_ip = table.remove(ref_stack)

      if program[then_ip][1] ~= Reserved.THEN then
        parfast_assert(false, "'elseif' can only close 'then' blocks.")
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
        parfast_assert(false, "'elseif' can only close 'if-then' blocks.")
      end
    elseif opr[1] == Reserved.THEN then
      local then_ref = table.remove(ref_stack)
      program[i][2] = then_ref
      table.insert(ref_stack, i)
    elseif opr[1] == Reserved.FN or opr[1] == Reserved.FN_BODY then
      table.insert(ref_stack, i)
    elseif opr[1] == Reserved.FN_CALL then
      if #call_stack > 0 then
        local ret_ip = table.remove(call_stack)
        if program[ret_ip][1] == Reserved.RET then
          program[ret_ip][2] = i + 1
        end
      end
    elseif opr[1] == Reserved.RET then
      table.insert(call_stack, i)
    elseif opr[1] == Reserved.IN then
      table.insert(ref_stack, i)
    end
  end

  return program
end
