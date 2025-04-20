local parfast_assert = require("src.utils").parfast_assert
local lexl = require("src.lex")
local parser = require("src.parser")
local parse = parser.parse
local check_unhandled_data = require("src.checker")
local compile_defs = require("src.codegen")

-- Extension should be .parfast
local function remove_file_extension(filepath)
  return string.gsub(filepath, "%.([^\\/%.]-)%.?$", "")
end

---@type number|nil
local fasm_mem_cap = 640000
local function parse_args()
  local i = 1
  local flags = {}

  while i <= #arg do
    local flag_or_file = arg[i]

    if flag_or_file:sub(1, 1) == "-" then
      flags[flag_or_file] = true
      if flag_or_file == "-m" then
        flag_or_file = arg[i + 1]
        i = i + 1
        fasm_mem_cap = tonumber(flag_or_file)
        parfast_assert(fasm_mem_cap, "Expected -m argument to be a number.")
      end
    else
      flags["-file"] = flag_or_file
    end
    i = i + 1
  end

  return flags
end

local function print_help()
  print("Usage: parfast <input.parfast> -com/-run/-c/-help\n")
  print("\t\"-com\" Compile and link generated files with Nasm or Gas.")
  print("\t\"-c\" Compile generated file with no linking step.")
  print("\t\"-unsafe\" enable unsafe mode. (no type checking provided in asm blocks)")
  print("\t\"-m\" Customize memory limit for fasm.")
  print("\ndisable warning flags: \n\t\"-Wunused-data\" Disable default type checking and unused data in stack.")
  print("\nOther options: \n\t\"-silent\" Disable messages of what is being passed to shell, for example: nasm or ld.")
  print("\t\"-use-fasm\" Use the Fasm Assembler instead of Nasm.")
end

function main()
  parfast_assert(#arg > 0,
    " not enough arguments. \n\tUsage: parfast <input.parfast> -com/-run/-c/-help")
  local flags = parse_args()
  if flags["-help"] then
    print_help()
    os.exit(0)
  end

  parfast_assert(flags["-com"] or flags["-run"] or flags["-c"],
    " missing flag to compile or run file. \n\tUsage: parfast <input.parfast> -com/-run/-c/-help")
  parfast_assert(flags["-file"] ~= nil, " No input file provided.")
  local input, errmsg = io.open(flags["-file"], "r")

  if not input or input == nil then
    parfast_assert(false, string.format("Couldn't open input file: %s", errmsg))
    os.exit(1)
  end

  local tokens = lexl(input:read("a"))
  local ir = parse(tokens)
  local outname = remove_file_extension(flags["-file"])
  local parsed_ir = get_references(ir)

  if flags["-unsafe"] then
    compile_defs.switch_mode()
  end
  if flags["-com"] then
    if flags["-use-fasm"] then
      compile_defs.compile_linux_x86_64_fasm(parsed_ir, outname)

      if not flags["-Wunused-data"] then
        check_unhandled_data(parsed_ir)
      end

      os.execute(string.format("fasm -m %d %s.asm", fasm_mem_cap, outname))
    else
      compile_defs.compile_linux_x86_64_nasm(parsed_ir, outname)

      os.execute("nasm -f elf64 " .. outname .. ".asm")
      if not flags["-Wunused-data"] then
        check_unhandled_data(parsed_ir)
      end
      os.execute(string.format("ld -o %s %s.o", outname, outname))
    end
  end
  if flags["-c"] then
    compile_defs.compile_linux_x86_64_nasm(parsed_ir, outname)

    os.execute("nasm -f elf64 " .. outname .. ".asm")
    if not flags["-Wunused-data"] and not flags["-unsafe"] then
      check_unhandled_data(parsed_ir)
    end
  end
  if not flags["-silent"] and not flags["-run"] then
    if not flags["-use-fasm"] then
      print("[1/2] nasm -f elf64 " .. flags["-file"])
      print(string.format("[2/2] ld -o %s %s.o", outname, outname))
    elseif flags["-use-fasm"] then
      print("[1/1] fasm -m " .. fasm_mem_cap .. " " .. flags["-file"])
    end
  end
end

main()
