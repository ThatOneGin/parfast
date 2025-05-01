local kind_str = {
  "PUSH_INT",
  "PUSH_STR",  "PUTS",
  "ADD",       "SUB",
  "IF",        "END",
  "EQU",       "NEQ",
  "LT",        "GT",
  "DUP",       "SWAP",
  "WHILE",     "DO",
  "ELSE",      "MBUF",
  "LOAD",      "STORE",
  "DROP",      "MACRO",
  "INCLUDE",   "MUL",
  "DIV",       "ENDM",
  "ROT",       "RST",
  "RLD",       "EXTERN",
  "CALL",      "ELSEIF",
  "THEN",      "SYSCALL0",
  "SYSCALL1",  "SYSCALL4",
  "SYSCALL2",  "SYSCALL6",
  "SYSCALL3",  "SYSCALL5",
  "MEM",       "MOD",
  "ARGC",      "ARGV",
  "FN",        "FN_BODY",
  "RET",       "FN_CALL",
  "LOCAL_MEM", "ASM",
  "ENDBIND",   "IN",
  "PUSHBIND",  "WITH",
  "CAST_PTR",  "CAST_STR",
  "CAST_INT",  "CAST_BOOL"
}

local function escape_str(s)
  return s:gsub("\n", "\\n"):gsub("\t", "\\t"):gsub("\r", "\\r"):gsub("\027", "\\033")
end

function concat_ir_op(op)
  local s = "{"
  s = s .. kind_str[op[1]] .. " "
  for i = 2, #op do
    if type(op[i]) == "string" then
      s = s .. "\"" .. escape_str(op[i]) .. "\" "
    else
      s = s .. tostring(op[i]) .. " "
    end
  end
  return s:sub(1, -2) .. "}"
end
