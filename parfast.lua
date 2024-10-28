counter = 0
function enum(reset)
	if reset == true then counter = 0 end
	local val = counter
	counter = counter + 1
	return val
end

Tokentype = {
	Number = enum(true),
	Ident = enum(),
	Word = enum(),
	Operator = enum()
}

Reserved = {
	PUSH = enum(true),
	PUTS = enum(),
	ADD = enum(),
	SUB = enum(),
	IF = enum(),
	END = enum(),
	EQU = enum(),
	NEQ = enum(),
	LT = enum(),
	GT = enum(),
	DUP = enum(),
	SWAP = enum(),
	WHILE = enum(),
	DO = enum(),
	ELSE = enum()
}

local strreserved = {
	["puts"] = Reserved.PUTS,
	["+"] = Reserved.ADD,
	["-"] = Reserved.SUB,
	["if"] = Reserved.IF,
	["end"] = Reserved.END,
	["dup"] = Reserved.DUP,
	["swap"] = Reserved.SWAP,
	["while"] = Reserved.WHILE,
	["do"] = Reserved.DO,
	["else"] = Reserved.ELSE
}

local function push(val)
	return { Reserved.PUSH, val }
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
	return {Reserved.ELSE}
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
		end
	end

	return tokens
end

function parse(tokens)
	local program = {}

	local function shift()
		return table.remove(tokens, 1)
	end

	while #tokens > 0 do
		if tokens[1].value == "puts" then
			assert(#program > 0, string.format("Cannot write as the stack may be empty. At %d:%d", tokens[1].line, tokens[1].col))
			shift()
			table.insert(program, puts())
		elseif tokens[1].value == "+" then
			assert(#program > 1, string.format("Cannot make arithmetic(+) as the stack may be empty. At %d:%d", tokens[1].line, tokens[1].col))
			shift()
			table.insert(program, add())
		elseif tokens[1].value == "-" then
			assert(#program > 1, string.format("Cannot make arithmetic(-) as the stack may be empty. At %d:%d", tokens[1].line, tokens[1].col))
			shift()
			table.insert(program, sub())
		elseif tokens[1].value == "if" then
			assert(#program > 2, string.format("Expected condition before `if` initial block. At %d:%d", tokens[1].line, tokens[1].col))
			shift()
			table.insert(program, _if())
		elseif tokens[1].value == "end" then
			shift()
			table.insert(program, _end())
		elseif tokens[1].value == "==" then
			assert(#program > 1, string.format("Cannot make boolean operation(==) as the stack is empty. At %d:%d", tokens[1].line, tokens[1].col))
			shift()
			table.insert(program, equ())
		elseif tokens[1].value == "!=" then
			assert(#program > 1, string.format("Cannot make boolean operation(!=) as the stack is empty. At %d:%d", tokens[1].line, tokens[1].col))
			shift()
			table.insert(program, neq())
		elseif tokens[1].value == ">" then
			assert(#program > 1, string.format("Cannot make boolean operation(>) as the stack is empty. At %d:%d", tokens[1].line, tokens[1].col))
			shift()
			table.insert(program, gt())
		elseif tokens[1].value == "<" then
			assert(#program > 1, string.format("Cannot make boolean operation(<) as the stack is empty. At %d:%d", tokens[1].line, tokens[1].col))
			shift()
			table.insert(program, lt())
		elseif tokens[1].value == "dup" then
			assert(#program > 0, string.format("Cannot duplicate the top of the stack as it is empty. At %d:%d", tokens[1].line, tokens[1].col))
			shift()
			table.insert(program, dup())
		elseif tokens[1].value == "swap" then
			assert(#program > 1, string.format("Cannot swap the top of the stack as it is empty. At %d:%d", tokens[1].line, tokens[1].col))
			shift()
			table.insert(program, swp())
		elseif tokens[1].value == "while" then
			shift()
			table.insert(program, _while())
		elseif tokens[1].value == "do" then
			assert(#program > 2, string.format("Expected condition before `do` initial block. At %d:%d", tokens[1].line, tokens[1].col))
			shift()
			table.insert(program, _do())
		elseif tokens[1].value == "else" then
			shift()
			table.insert(program, _else())
		else
			assert(#tokens > 1, string.format("Warn: the result of the push operation at eof will be considered as dead code.\n\tAt location %d:%d", tokens[1].line, tokens[1].col))
			local val = shift().value
			table.insert(program, push(val))
		end
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
			program[if_location] = {Reserved.IF, i + 1}
			table.insert(ref_stack, i)
		elseif opr[1] == Reserved.DO then
			local while_ref = table.remove(ref_stack)
			program[i] = { Reserved.DO, while_ref }
			table.insert(ref_stack, i)
		end
	end

	return program
end

function compile(ir, outname)
	local output = io.open(outname..".asm", "w+")
	if not output or output == nil then
		return nil
	end

	output:write(
		"puts:\n\tmov	 r9, -3689348814741910323\n\tsub     rsp, 40\n\tmov  BYTE [rsp+31], 10\n\tlea  rcx, [rsp+30]\n")
	output:write(
		".L2:\n\tmov  rax, rdi\n\tlea  r8, [rsp+32]\n\tmul  r9\n\tmov  rax, rdi\n\tsub  r8, rcx\n\tshr  rdx, 3\n\tlea  rsi, [rdx+rdx*4]\n\tadd  rsi, rsi\n\tsub  rax, rsi\n\tadd  eax, 48\n\tmov  BYTE [rcx], al\n\tmov  rax, rdi\n\tmov  rdi, rdx\n\tmov  rdx, rcx\n\tsub  rcx, 1\n\tcmp  rax, 9\n\tja   .L2\n\tlea  rax, [rsp+32]\n\tmov  edi, 1\n\tsub  rdx, rax\n\tlea  rsi, [rsp+32+rdx]\n\tmov  rdx, r8\n\tmov  rax, 1\n\tsyscall\n\tadd  rsp, 40\n\tret\n")

	output:write("section .text\n\tglobal _start\n\n_start:\n")

	for i, op in pairs(ir) do
		output:write(string.format("op_%d:\n", i))

		if op[1] == Reserved.PUSH then
			output:write(string.format("\tpush %d\n", op[2]))
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
			output:write("\tmov rcx, 0\n\tmov rdx, 1\n\tpop rax\n\tpop rbx\n\tcmp rax, rbx\n\tcmove rcx, rdx\n\tpush rcx\n")
		elseif op[1] == Reserved.NEQ then
			output:write("\tmov rcx, 1\n\tmov rdx, 0\n\tpop rax\n\tpop rbx\n\tcmp rax, rbx\n\tcmove rcx, rdx\n\tpush rcx\n")
		elseif op[1] == Reserved.GT then
			output:write("\tmov rcx, 0\n\tmov rdx, 1\n\tpop rbx\n\tpop rax\n\tcmp rax, rbx\n\tcmovg rcx, rdx\n\tpush rcx\n")
		elseif op[1] == Reserved.LT then
			output:write("\tmov rcx, 0\n\tmov rdx, 1\n\tpop rbx\n\tpop rax\n\tcmp rax, rbx\n\tcmovg rcx, rdx\n\tpush rcx\n")
		elseif op[1] == Reserved.SWAP then
			output:write("\tpop rax\n\tpop rbx\n\tpush rax\n\tpush rbx\n")
		elseif op[1] == Reserved.WHILE then
			output:write("\t; while\n")
		elseif op[1] == Reserved.DO then
			output:write(string.format("\tpop rax\n\ttest rax, rax\n\tjz op_%d\n", op[2]))
		elseif op[1] == Reserved.ELSE then
			output:write(string.format("\tjmp op_%d\n", op[2]))
		else
       print("\27[31;4mError\27[0m:\n\tOperand not recognized")
       os.exit(1)
		end
	end

	output:write(string.format("op_%d:\n", #ir + 1))
	output:write("\tmov rax, 60\n\tmov rdi, 0\n\tsyscall")
	output:close()
end

local function getfilename(filepath)
  return filepath:sub(1, -9)
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
	compile(get_references(ir), outname)
  os.execute("nasm -f elf64 "..outname..".asm")
	os.execute(string.format("ld -o %s %s", outname, outname..".o"))

	print("commands: \n\t[nasm -f elf64 a.asm]\n\t[ld -o a.out a.o]")
end

main()
