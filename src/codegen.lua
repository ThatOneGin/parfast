local safe_mode = true

local function switch_mode()
  safe_mode = not safe_mode
end

local function compile_linux_x86_64_nasm(ir, outname)
  local register_args_table = { "rdi", "rsi", "rdx", "rcx", "r8", "r9" }

  local output = io.open(outname .. ".asm", "w+")
  if not output or output == nil then
    return nil
  end
  output:write("BITS 64\n")
  output:write(
    "puts:\n\tmov	 r9, -3689348814741910323\n\tsub  rsp, 40\n\tmov  BYTE [rsp+31], 10\n\tlea  rcx, [rsp+30]\n")
  output:write(
    ".L2:\n\tmov  rax, rdi\n\tlea  r8, [rsp+32]\n\tmul  r9\n\tmov  rax, rdi\n\tsub  r8, rcx\n\tshr  rdx, 3\n\tlea  rsi, [rdx+rdx*4]\n\tadd  rsi, rsi\n\tsub  rax, rsi\n\tadd  eax, 48\n\tmov  BYTE [rcx], al\n\tmov  rax, rdi\n\tmov  rdi, rdx\n\tmov  rdx, rcx\n\tsub  rcx, 1\n\tcmp  rax, 9\n\tja   .L2\n\tlea  rax, [rsp+32]\n\tmov  edi, 1\n\tsub  rdx, rax\n\tlea  rsi, [rsp+32+rdx]\n\tmov  rdx, r8\n\tmov  rax, 1\n\tsyscall\n\tadd  rsp, 40\n\tret\n")

  -- output:write(
  --   "section .text\n\tglobal _start\n\n_start:\n\tmov [args], rsp\n\tmov rax, stack_end\n\tmov [ret_stack], rax\n")

  local strings = {}
  local extern_fns = {}
  for i, op in pairs(ir) do
    if op[1] ~= Reserved.FN_BODY then
      output:write(string.format("op_%d:\n", i))
    end

    if op[1] == Reserved.PUSH_INT then
      output:write(string.format("\tpush %d\n", op[2]))
    elseif op[1] == Reserved.PUSH_STR then
      table.insert(strings, op[2])
      output:write(string.format("\tpush %d\n\tpush string_%d\n", string.len(op[2]), #strings))
    elseif op[1] == Reserved.CALL then
      if op[3] > 0 then
        parfast_assert(op[3] <= #register_args_table, "Extern call argument overflow.")
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
      parfast_assert(#op == 2, outname .. ".parfast:" .. i ..
        " Bug at crossreferencing step.")
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
      parfast_assert(#op == 2, outname .. ".parfast:" .. i ..
        " Bug at crossreferencing step.")
      output:write(string.format("\tpop rax\n\ttest rax, rax\n\tjz op_%d\n", op[2]))
    elseif op[1] == Reserved.ELSE then
      parfast_assert(#op == 2, outname .. ".parfast:" .. i ..
        " Bug at crossreferencing step.")
      output:write(string.format("\tjmp op_%d\n", op[2]))
    elseif op[1] == Reserved.LOAD then
      output:write("\tpop rax\n\txor rbx, rbx\n\tmov bl, [rax]\n\tpush rbx\n")
    elseif op[1] == Reserved.STORE then
      output:write("\tpop rbx\n\tpop rax\n\tmov [rax], bl\n")
    elseif op[1] == Reserved.DROP then
      output:write("\tpop rax\n")
    elseif op[1] == Reserved.ROT then
      output:write("\tpop rax\n\tpop rbx\n\tpop rcx\n\tpush rbx\n\tpush rax\n\tpush rcx\n")
    elseif op[1] == Reserved.RST then
      output:write("\tpop rax\n\tpop rbx\n\tmov [rax], rbx\n")
    elseif op[1] == Reserved.RLD then
      output:write("\tpop rax\n\txor rbx, rbx\n\tmov rbx, [rax]\n\tpush rbx\n")
    elseif op[1] == Reserved.THEN then
      parfast_assert(#op == 2, outname .. ".parfast:" .. i ..
        " Bug at crossreferencing step.")
      output:write(string.format("\tpop rax\n\ttest rax, rax\n\tjz op_%d\n", op[2]))
    elseif op[1] == Reserved.ELSEIF then
      parfast_assert(#op == 2, outname .. ".parfast:" .. i ..
        " Bug at crossreferencing step.")
      output:write(string.format("\tjmp op_%d\n", op[2]))
    elseif op[1] == Reserved.SYSCALL0 then
      output:write("\tpop rax\n\tsyscall\n\tpush rax\n")
    elseif op[1] == Reserved.SYSCALL1 then
      output:write("\tpop rax\n\tpop rdi\n\tsyscall\n\tpush rax\n")
    elseif op[1] == Reserved.SYSCALL2 then
      output:write("\tpop rax\n\tpop rdi\n\tpop rsi\n\tsyscall\n\tpush rax\n")
    elseif op[1] == Reserved.SYSCALL3 then
      output:write("\tpop rax\n\tpop rdi\n\tpop rsi\n\tpop rdx\n\tsyscall\n\tpush rax\n")
    elseif op[1] == Reserved.SYSCALL4 then
      output:write("\tpop rax\n\tpop rdi\n\tpop rsi\n\tpop rdx\n\tpop r10\n\tsyscall\n\tpush rax\n")
    elseif op[1] == Reserved.SYSCALL5 then
      output:write("\tpop rax\n\tpop rdi\n\tpop rsi\n\tpop rdx\n\tpop r10\n\tpop r8\n\tsyscall\n\tpush rax\n")
    elseif op[1] == Reserved.SYSCALL6 then
      output:write("\tpop rax\n\tpop rdi\n\tpop rsi\n\tpop rdx\n\tpop r10\n\tpop r8\n\tpop r9\n\tsyscall\n\tpush rax\n")
    elseif op[1] == Reserved.MEM then
      output:write(string.format("\tmov rax, mbuf\n\tadd rax, %d\n\tpush rax\n", op[2]))
    elseif op[1] == Reserved.MOD then
      output:write("\tpop rax\n\tpop rbx\n\txor rdx, rdx\n\tdiv rbx\n\tpush rax\n\tpush rdx\n")
    elseif op[1] == Reserved.ARGC then
      output:write("\tmov rax, [args]\n\tmov rax, [rax]\n\tpush rax\n")
    elseif op[1] == Reserved.ARGV then
      output:write("\tmov rax, [args]\n\tadd rax, 8\n\tpush rax\n")
    elseif op[1] == Reserved.FN then
      parfast_assert(#op == 2, outname .. ".parfast:" .. i ..
        " Bug at crossreferencing step.")
      output:write(string.format("\tjmp op_%d\n", op[2]))
    elseif op[1] == Reserved.FN_BODY then
      parfast_assert(#op == 3, outname .. ".parfast:" .. i ..
      " Bug at crossreferencing step.")
      output:write(string.format("%s:\nop_%d:\n", op[3], i))
      output:write(string.format("\tsub rsp, %d\n\tmov [ret_stack], rsp\n\tmov rsp, rax\n", op[2]))
    elseif op[1] == Reserved.RET then
      output:write(string.format("\tmov rax, rsp\n\tmov rsp, [ret_stack]\n\tadd rsp, %d\n\tret\n", op[2]))
    elseif op[1] == Reserved.FN_CALL then
      output:write(string.format(
        "\tmov rax, rsp\n\tmov rsp, [ret_stack]\n\tcall op_%d\n\tmov [ret_stack], rsp\n\tmov rsp, rax\n", op[2]))
    elseif op[1] == Reserved.LOCAL_MEM then
      output:write(string.format("\tmov rax, [ret_stack]\n\tadd rax, %d\n\tpush rax\n", op[2]))
    elseif op[1] == Reserved.ASM then
      parfast_assert(safe_mode == false, "Cannot use inline assembly in 'safe' mode. Please recompile with -unsafe flag.")
      output:write(string.format("\t%s\n", op[2]))
    elseif op[1] == Reserved.IN then
      output:write(string.format("\tmov rax, [ret_stack]\n\tsub rax, %d\n\tmov [ret_stack], rax\n", op[2]))

      for i = op[2] / 8, 1, -1 do
        output:write(string.format("\tpop rbx\n\tmov [rax+%d], rbx\n", i * 8 - 8))
      end
    elseif op[1] == Reserved.PUSHBIND then
      output:write(string.format("\tmov rax, [ret_stack]\n\tadd rax, %d\n\tpush QWORD [rax]\n", op[2]))
    elseif op[1] == Reserved.ENDBIND then
      output:write(string.format("\tmov rax, [ret_stack]\n\tadd rax, %d\n\tmov [ret_stack], rax\n", op[2]))
    elseif op[1] == Reserved.CAST_BOOL then
      output:write("\t; cast_intrinsic bool\n")
    elseif op[1] == Reserved.CAST_INT then
      output:write("\t; cast_intrinsic int\n")
    elseif op[1] == Reserved.CAST_STR then
      output:write("\t; cast_intrinsic str\n")
    elseif op[1] == Reserved.CAST_PTR then
      output:write("\t; cast_intrinsic ptr\n")
    else
      parfast_assert(false, string.format(
        "\n\tOperand not recognized or shouldn't be reachable.", op[1]))
    end
  end

  output:write(
    "section .text\n\tglobal _start\n\n_start:\n\tmov [args], rsp\n\tmov rax, stack_end\n\tmov [ret_stack], rax\n")
    output:write(
      string.format(
        "\tmov rax, rsp\n\tmov rsp, [ret_stack]\n\tcall main\n\tmov [ret_stack], rsp\n\tmov rsp, rax\n"))

  output:write(string.format("op_%d:\n", #ir + 1))
  output:write("\tmov rax, 60\n\tmov rdi, 0\n\tsyscall\n")

  output:write("section .bss\n\targs: resq 1\n\tmbuf: resb " ..
    max_buffer_cap .. "\n\tret_stack: resq 1026\n\tstack_end: resq 1\n")

  output:write("section .data\n")
  for i, str in pairs(strings) do
    output:write(string.format("string_%d: db %s\n", i, hex(str)))
  end
  output:close()
end

local function compile_linux_x86_64_fasm(ir, outname)
  local register_args_table = { "rdi", "rsi", "rdx", "rcx", "r8", "r9" }

  local output = io.open(outname .. ".asm", "w+")
  if not output or output == nil then
    return nil
  end
  output:write("format ELF64 executable 3\n")
  output:write(
    "puts:\n\tmov	 r9, -3689348814741910323\n\tsub  rsp, 40\n\tmov  BYTE [rsp+31], 10\n\tlea  rcx, [rsp+30]\n")
  output:write(
    ".L2:\n\tmov  rax, rdi\n\tlea  r8, [rsp+32]\n\tmul  r9\n\tmov  rax, rdi\n\tsub  r8, rcx\n\tshr  rdx, 3\n\tlea  rsi, [rdx+rdx*4]\n\tadd  rsi, rsi\n\tsub  rax, rsi\n\tadd  eax, 48\n\tmov  BYTE [rcx], al\n\tmov  rax, rdi\n\tmov  rdi, rdx\n\tmov  rdx, rcx\n\tsub  rcx, 1\n\tcmp  rax, 9\n\tja   .L2\n\tlea  rax, [rsp+32]\n\tmov  edi, 1\n\tsub  rdx, rax\n\tlea  rsi, [rsp+32+rdx]\n\tmov  rdx, r8\n\tmov  rax, 1\n\tsyscall\n\tadd  rsp, 40\n\tret\n")

  local strings = {}
  local extern_fns = {}
  for i, op in pairs(ir) do
    if op[1] ~= Reserved.FN_BODY then
      output:write(string.format("op_%d:\n", i))
    end

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
      parfast_assert(#op == 2, outname .. ".parfast:" .. i ..
        " Bug at crossreferencing step.")
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
      parfast_assert(#op == 2, outname .. ".parfast:" .. i ..
        " Bug at crossreferencing step.")
      output:write(string.format("\tpop rax\n\ttest rax, rax\n\tjz op_%d\n", op[2]))
    elseif op[1] == Reserved.ELSE then
      parfast_assert(#op == 2, outname .. ".parfast:" .. i ..
        " Bug at crossreferencing step.")
      output:write(string.format("\tjmp op_%d\n", op[2]))
    elseif op[1] == Reserved.LOAD then
      output:write("\tpop rax\n\txor rbx, rbx\n\tmov bl, [rax]\n\tpush rbx\n")
    elseif op[1] == Reserved.STORE then
      output:write("\tpop rbx\n\tpop rax\n\tmov [rax], bl\n")
    elseif op[1] == Reserved.DROP then
      output:write("\tpop rax\n")
    elseif op[1] == Reserved.ROT then
      output:write("\tpop rax\n\tpop rbx\n\tpop rcx\n\tpush rbx\n\tpush rax\n\tpush rcx\n")
    elseif op[1] == Reserved.RST then
      output:write("\tpop rax\n\tpop rbx\n\tmov [rax], rbx\n")
    elseif op[1] == Reserved.RLD then
      output:write("\tpop rax\n\txor rbx, rbx\n\tmov rbx, [rax]\n\tpush rbx\n")
    elseif op[1] == Reserved.THEN then
      parfast_assert(#op == 2, outname .. ".parfast:" .. i ..
        " Bug at crossreferencing step.")
      output:write(string.format("\tpop rax\n\ttest rax, rax\n\tjz op_%d\n", op[2]))
    elseif op[1] == Reserved.ELSEIF then
      parfast_assert(#op == 2, outname .. ".parfast:" .. i ..
        " Bug at crossreferencing step.")
      output:write(string.format("\tjmp op_%d\n", op[2]))
    elseif op[1] == Reserved.SYSCALL0 then
      output:write("\tpop rax\n\tsyscall\n\tpush rax\n")
    elseif op[1] == Reserved.SYSCALL1 then
      output:write("\tpop rax\n\tpop rdi\n\tsyscall\n\tpush rax\n")
    elseif op[1] == Reserved.SYSCALL2 then
      output:write("\tpop rax\n\tpop rdi\n\tpop rsi\n\tsyscall\n\tpush rax\n")
    elseif op[1] == Reserved.SYSCALL3 then
      output:write("\tpop rax\n\tpop rdi\n\tpop rsi\n\tpop rdx\n\tsyscall\n\tpush rax\n")
    elseif op[1] == Reserved.SYSCALL4 then
      output:write("\tpop rax\n\tpop rdi\n\tpop rsi\n\tpop rdx\n\tpop r10\n\tsyscall\n\tpush rax\n")
    elseif op[1] == Reserved.SYSCALL5 then
      output:write("\tpop rax\n\tpop rdi\n\tpop rsi\n\tpop rdx\n\tpop r10\n\tpop r8\n\tsyscall\n\tpush rax\n")
    elseif op[1] == Reserved.SYSCALL6 then
      output:write("\tpop rax\n\tpop rdi\n\tpop rsi\n\tpop rdx\n\tpop r10\n\tpop r8\n\tpop r9\n\tsyscall\n\tpush rax\n")
    elseif op[1] == Reserved.MEM then
      output:write(string.format("\tmov rax, mbuf\n\tadd rax, %d\n\tpush rax\n", op[2]))
    elseif op[1] == Reserved.MOD then
      output:write("\tpop rax\n\tpop rbx\n\txor rdx, rdx\n\tdiv rbx\n\tpush rax\n\tpush rdx\n")
    elseif op[1] == Reserved.ARGC then
      output:write("\tmov rax, [args]\n\tmov rax, [rax]\n\tpush rax\n")
    elseif op[1] == Reserved.ARGV then
      output:write("\tmov rax, [args]\n\tadd rax, 8\n\tpush rax\n")
    elseif op[1] == Reserved.FN then
      parfast_assert(#op == 2, outname .. ".parfast:" .. i ..
        " Bug at crossreferencing step.")
      output:write(string.format("\tjmp op_%d\n", op[2]))
    elseif op[1] == Reserved.FN_BODY then
      parfast_assert(#op == 3, outname .. ".parfast:" .. i ..
        " Bug at crossreferencing step.")
      output:write(string.format("%s:\nop_%d:\n", op[3], i))
      output:write(string.format("\tsub rsp, %d\n\tmov [ret_stack], rsp\n\tmov rsp, rax\n", op[2]))
    elseif op[1] == Reserved.RET then
      output:write(string.format("\tmov rax, rsp\n\tmov rsp, [ret_stack]\n\tadd rsp, %d\n\tret\n", op[2]))
    elseif op[1] == Reserved.FN_CALL then
      output:write(string.format(
        "\tmov rax, rsp\n\tmov rsp, [ret_stack]\n\tcall op_%d\n\tmov [ret_stack], rsp\n\tmov rsp, rax\n", op[2]))
    elseif op[1] == Reserved.LOCAL_MEM then
      output:write(string.format("\tmov rax, [ret_stack]\n\tadd rax, %d\n\tpush rax\n", op[2]))
    elseif op[1] == Reserved.ASM then
      parfast_assert(safe_mode == false, "Cannot use inline assembly in 'safe' mode. Please recompile with -unsafe flag.")
      output:write(string.format("\t%s\n", op[2]))
    elseif op[1] == Reserved.IN then
      output:write(string.format("\tmov rax, [ret_stack]\n\tsub rax, %d\n\tmov [ret_stack], rax\n", op[2]))

      for i = op[2] / 8, 1, -1 do
        output:write(string.format("\tpop rbx\n\tmov [rax+%d], rbx\n", i * 8 - 8))
      end
    elseif op[1] == Reserved.PUSHBIND then
      output:write(string.format("\tmov rax, [ret_stack]\n\tadd rax, %d\n\tpush QWORD [rax]\n", op[2]))
    elseif op[1] == Reserved.ENDBIND then
      output:write(string.format("\tmov rax, [ret_stack]\n\tadd rax, %d\n\tmov [ret_stack], rax\n", op[2]))
    elseif op[1] == Reserved.CAST_BOOL then
      output:write("; cast_intrinsic bool")
    elseif op[1] == Reserved.CAST_INT then
      output:write("; cast_intrinsic int")
    elseif op[1] == Reserved.CAST_STR then
      output:write("; cast_intrinsic str")
    elseif op[1] == Reserved.CAST_PTR then
      output:write("; cast_intrinsic ptr")
    else
      parfast_assert(false, string.format(
        "\n\tOperand not recognized or shouldn't be reachable.", op[1]))
    end
  end

  output:write(
    "segment readable executable\n\tentry _start\n\n_start:\n\tmov [args], rsp\n\tmov rax, stack_end\n\tmov [ret_stack], rax\n")

  output:write(
    string.format(
      "\tmov rax, rsp\n\tmov rsp, [ret_stack]\n\tcall main\n\tmov [ret_stack], rsp\n\tmov rsp, rax\n"))
  output:write(string.format("op_%d:\n", #ir + 1))
  output:write("\tmov rax, 60\n\tmov rdi, 0\n\tsyscall\n")

  output:write("segment readable writeable\n")
  output:write("\targs: rq 1\n\tmbuf: rb " ..
    max_buffer_cap .. "\n\tret_stack: rq 1026\n\tstack_end: rq 1\n")
  for i, str in pairs(strings) do
    output:write(string.format("string_%d: db %s\n", i, hex(str)))
  end
  output:close()
end
