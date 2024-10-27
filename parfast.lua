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
	SWAP = enum()
}

local strreserved = {
	["puts"] = Reserved.PUTS,
	["+"] = Reserved.ADD,
	["-"] = Reserved.SUB,
	["if"] = Reserved.IF,
	["end"] = Reserved.END,
	["dup"] = Reserved.DUP,
	["swp"] = Reserved.SWAP
}

local function push(val, index)
	return { Reserved.PUSH, index, val}
end
local function puts(index)
	return { Reserved.PUTS, index}
end
local function add(index)
	return { Reserved.ADD, index}
end
local function sub(index)
	return { Reserved.SUB, index}
end
local function _if(index, endref)
	return { Reserved.IF, endref, index }
end
local function _end(index)
	return { Reserved.END, index}
end
local function equ(index)
	return { Reserved.EQU, index}
end
local function neq(index)
	return { Reserved.NEQ, index}
end
local function lt(index)
	return { Reserved.LT, index}
end
local function gt(index)
	return { Reserved.GT, index}
end
local function dup(index)
	return { Reserved.DUP, index}
end
local function swp(index)
	return { Reserved.SWAP, index}
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
	local stack = {}

	local function shift()
		return table.remove(tokens, 1)
	end

	local pc = 1
	while #tokens > 0 do
		if tokens[1].value == "puts" then
			shift()
			table.insert(program, puts(pc))
		elseif tokens[1].value == "+" then
			shift()
			table.insert(program, add(pc))
		elseif tokens[1].value == "-" then
			shift()
			table.insert(program, sub(pc))
		elseif tokens[1].value == "if" then
			shift()

			table.insert(stack, pc)
			table.insert(program, _if(pc))
		elseif tokens[1].value == "end" then
			shift()
			table.insert(program, _end(table.remove(stack)))
		elseif tokens[1].value == "==" then
			shift()
			table.insert(program, equ(pc))
		elseif tokens[1].value == "!=" then
			shift()
			table.insert(program, neq(pc))
		elseif tokens[1].value == ">" then
			shift()
			table.insert(program, gt(pc))
		elseif tokens[1].value == "<" then
			shift()
			table.insert(program, lt(pc))
		elseif tokens[1].value == "dup" then
			shift()
			table.insert(program, dup(pc))
		elseif tokens[1].value == "swp" then
			shift()
			table.insert(program, swp(pc))
		else
			local val = shift().value
			table.insert(program, push(val, pc))
		end
		pc = pc + 1
	end

	return program
end

function compile(ir)
	local output = io.open("a.asm", "w+")
	if not output or output == nil then
		return nil
	end

	output:write("puts:\n\tmov	 r9, -3689348814741910323\n\tsub     rsp, 40\n\tmov  BYTE [rsp+31], 10\n\tlea  rcx, [rsp+30]\n")
	output:write(".L2:\n\tmov  rax, rdi\n\tlea  r8, [rsp+32]\n\tmul  r9\n\tmov  rax, rdi\n\tsub  r8, rcx\n\tshr  rdx, 3\n\tlea  rsi, [rdx+rdx*4]\n\tadd  rsi, rsi\n\tsub  rax, rsi\n\tadd  eax, 48\n\tmov  BYTE [rcx], al\n\tmov  rax, rdi\n\tmov  rdi, rdx\n\tmov  rdx, rcx\n\tsub  rcx, 1\n\tcmp  rax, 9\n\tja   .L2\n\tlea  rax, [rsp+32]\n\tmov  edi, 1\n\tsub  rdx, rax\n\tlea  rsi, [rsp+32+rdx]\n\tmov  rdx, r8\n\tmov  rax, 1\n\tsyscall\n\tadd  rsp, 40\n\tret\n")

	output:write("section .text\n\tglobal _start\n\n_start:\n")

	for i, op in pairs(ir) do
		if op[1] == Reserved.PUSH then
			output:write(string.format("\tpush %d\n", op[3]))
		elseif op[1] == Reserved.ADD then
			output:write("\tpop rax\n\tpop rbx\n\tadd rax, rbx\n\tpush rax\n")
		elseif op[1] == Reserved.SUB then
			output:write("\tpop rax\n\tpop rbx\n\tsub rax, rbx\n\tpush rax\n")
		elseif op[1] == Reserved.PUTS then
			output:write("\tpop rdi\n\tcall puts\n")
		elseif op[1] == Reserved.IF then
			output:write(string.format("\tpop rax\n\ttest rax, rax\n\tjz end_%d\n", op[3]))
		elseif op[1] == Reserved.END then
			output:write(string.format("end_%d:\n", op[2]))
		elseif op[1] == Reserved.DUP then
			output:write("\tpop rax\n\tpush rax\n\tpush rax\n")
		elseif op[1] == Reserved.EQU then
			output:write("\tmov rcx, 0\n\tmov rdx, 1\n\tpop rax\n\tpop rbx\n\tcmp rax, rbx\n\tcmove rcx, rdx\n\tpush rcx\n")
		elseif op[1] == Reserved.NEQ then
			output:write("\tmov rcx, 1\n\tmov rdx, 0\n\tpop rax\n\tpop rbx\n\tcmp rax, rbx\n\tcmove rcx, rdx\n\tpush rcx\n")
		elseif op[1] == Reserved.GT then
			output:write("\tmov rcx, 0\n\tmov rdx, 1\n\tpop rbx\n\tpop rax\n\tcmp rax, rbx\n\tcmovg rcx, rdx\n\tpush rcx\n")
		elseif op[1] == Reserved.SWAP then
			output:write("\tpop rax\n\tpop rbx\n\tpush rax\n\tpush rbx\n")
		else
			print("Warn: unknown operands will be ignored.")
		end
	end

	output:write("\tmov rax, 60\n\tmov rdi, 0\n\tsyscall")
	output:close()
end

function main()
	local input = io.open(arg[1], "r")
	if not input or input == nil then
		print("Cannot open file, such no directory or lacks permission.")
		os.exit(1)
	end
	local tokens = lexl(input:read("a"))
	local ir = parse(tokens)
	compile(ir)
end

main()