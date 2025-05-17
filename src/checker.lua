local function check_unhandled_data(program)
  local types = { str = enum(true), ptr = enum(), int = enum(), bool = enum() }
  local stack = {}
  local call_stack = {}

  local function type_as_string(typ)
    if typ == types.str then
      return "str"
    elseif typ == types.ptr then
      return "ptr"
    elseif typ == types.int then
      return "int"
    elseif typ == types.bool then
      return "bool"
    end
  end

  local function stack_start_match(types, start)
    if #stack < #types then
      parfast_assert(false, string.format("Expected %d arguments but got %d.", #types, #stack))
    end
    for i = start, #types do
      if type_as_string(stack[i]) ~= types[i] then
        parfast_assert(false, string.format("Type mismatch %s vs %s.", type_as_string(stack[i]), types[i]))
      end
    end
  end

  local function push(typ)
    table.insert(stack, typ)
  end

  local function pop()
    if #stack > 0 then
      return table.remove(stack)
    else
      parfast_assert(false, "Stack underflow.")
    end
  end

  local max_recursion_loop = 2000
  local current_recursion_loop = 0
  local main_ip = functions["main"]
  parfast_assert(main_ip ~= nil, "Undefined reference to main.")

  table.insert(call_stack, main_ip[1])
  local i = main_ip[1]
  while i < #program do
    if i >= #program then
      break
    end

    if program[i][1] == Reserved.PUSH_INT then
      push(types.int)
    elseif program[i][1] == Reserved.PUSH_STR then
      push(types.int)
      push(types.str)
    elseif program[i][1] == Reserved.MEM or program[i][1] == Reserved.MBUF or program[i][1] == Reserved.ARGV then
      push(types.ptr)
    elseif program[i][1] == Reserved.ADD or program[i][1] == Reserved.SUB or program[i][1] == Reserved.MUL or program[i][1] == Reserved.DIV or program[i][1] == Reserved.MOD then
      local a = pop()
      local b = pop()
      if a == types.ptr and b == types.int then
        parfast_assert(program[i][1] == Reserved.ADD or program[i][1] == Reserved.SUB,
          "Invalid arithmetic hands.")
        push(types.ptr)
      elseif a == types.int and b == types.ptr then
        parfast_assert(program[i][1] == Reserved.ADD or program[i][1] == Reserved.SUB,
          "Invalid arithmetic hands.")
        push(types.ptr)
      elseif a == types.str or b == types.str then
        parfast_assert(false, "Invalid operands to binary (str and str)")
      else
        push(types.int)
      end
    elseif program[i][1] == Reserved.DUP then
      local a = pop()
      push(a)
      push(a)
    elseif program[i][1] == Reserved.SWAP then
      local a = pop()
      local b = pop()
      push(a)
      push(b)
    elseif program[i][1] == Reserved.ROT then
      local a = pop()
      local b = pop()
      local c = pop()
      push(b)
      push(a)
      push(c)
    elseif program[i][1] == Reserved.PUTS then
      pop()
    elseif program[i][1] == Reserved.NEQ or program[i][1] == Reserved.EQ then
      pop()
      pop()
      push(types.bool)
    elseif program[i][1] == Reserved.DO or program[i][1] == Reserved.THEN or program[i][1] == Reserved.DROP then
      pop()
    elseif program[i][1] == Reserved.GT or program[i][1] == Reserved.LT then
      pop()
      pop()
      push(types.bool)
    elseif program[i][1] == Reserved.ARGC then
      push(types.int)
    elseif program[i][1] == Reserved.RST or program[i][1] == Reserved.STORE then
      pop()
      pop()
    elseif program[i][1] == Reserved.RLD or program[i][1] == Reserved.LOAD then
      pop()
      push(types.int)
    elseif program[i][1] == Reserved.SYSCALL0 then
      pop()
      push(types.int)
    elseif program[i][1] == Reserved.SYSCALL1 then
      parfast_assert(#stack >= 2, "Not enough arguments for syscall. " .. #stack)
      for _ = 1, 2 do
        pop()
      end
      push(types.int)
    elseif program[i][1] == Reserved.SYSCALL2 then
      parfast_assert(#stack >= 3, "Not enough arguments for syscall. " .. #stack)
      for _ = 1, 3 do
        pop()
      end
      push(types.int)
    elseif program[i][1] == Reserved.SYSCALL3 then
      parfast_assert(#stack >= 4, "Not enough arguments for syscall. " .. #stack)
      for _ = 1, 4 do
        pop()
      end
      push(types.int)
    elseif program[i][1] == Reserved.SYSCALL4 then
      parfast_assert(#stack >= 5, "Not enough arguments for syscall. " .. #stack)
      for _ = 1, 5 do
        pop()
      end
      push(types.int)
    elseif program[i][1] == Reserved.SYSCALL5 then
      parfast_assert(#stack >= 6, "Not enough arguments for syscall. " .. #stack)
      for _ = 1, 6 do
        pop()
      end
      push(types.int)
    elseif program[i][1] == Reserved.SYSCALL6 then
      parfast_assert(#stack >= 7, "Not enough arguments for syscall. " .. #stack)
      for _ = 1, 7 do
        pop()
      end
      push(types.int)
    elseif program[i][1] == Reserved.FN then
      i = program[i][2]
    elseif program[i][1] == Reserved.RET then
      parfast_assert(#call_stack > 0, "Unreachable state at type checking.")
      local ret_ip = tonumber(table.remove(call_stack))
      parfast_assert(ret_ip ~= nil, "Unreachable state at type checking.")
      i = ret_ip - 1
    elseif program[i][1] == Reserved.FN_CALL then
      -- this checks if the program has encountered a recursion
      -- because this function don't check context, only types.
      if current_recursion_loop >= max_recursion_loop then
        i = i + 1
        current_recursion_loop = 0
        goto continue
      else
        current_recursion_loop = current_recursion_loop + 1
      end

      table.insert(call_stack, i + 1)
      local fn = functions[program[i][3]]
      parfast_assert(fn ~= nil, "Attempt to call undefined function.")

      if #stack < #fn[5] then
        parfast_assert(false,
          string.format("Not enough arguments for function call, expected %d arguments but got %d.", #fn[5], #stack))
      end

      stack_start_match(fn[5], #stack - #fn[5] + 1)
      i = program[i][2]
    elseif program[i][1] == Reserved.IN then
      for _ = 1, program[i][3] do
        pop()
      end
    elseif program[i][1] == Reserved.LOCAL_MEM then
      push(types.ptr)
    elseif program[i][1] == Reserved.CAST_INT then
      pop()
      push(types.int)
    elseif program[i][1] == Reserved.CAST_STR then
      pop()
      push(types.str)
    elseif program[i][1] == Reserved.CAST_PTR then
      pop()
      push(types.ptr)
    elseif program[i][1] == Reserved.CAST_BOOL then
      pop()
      push(types.bool)
    elseif program[i][1] == Reserved.PUSHBIND then
      push(types.ptr) -- should be a pointer
    end
    ::continue::
    i = i + 1
  end

  if #stack == 1 then
    print(string.format("Warn: Unused data in stack, please drop it. Type: %s",
      type_as_string(stack[1])))
  elseif #stack > 1 then
    print("Warn: Unused data in stack, please drop them. Types: ")
    for i = 1, #stack do
      io.write(i .. ": " .. type_as_string(stack[i]) .. " ")
    end
    print("\n")
  end
end
