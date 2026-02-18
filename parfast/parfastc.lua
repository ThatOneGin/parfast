-- The parfast compiler

local compiler = require("parfast.compiler")
local util = require("parfast.util")
local header = require("parfast.header")
local parfastc = {}

local outputs = {}

local function getsource(filename)
  local f, errmsg = io.open(filename, "r")
  if f == nil or errmsg ~= nil then
    util.abort("Error", "Couldn't open file: %s: ", filename, errmsg)
    os.exit(1)
  end
  return f:read("a")
end

local function writetofile(chunk, filename)
  local f, errmsg = io.open(filename, "w")
  if f == nil or errmsg ~= nil then
    util.abort("Error", "Couldn't open file: %s: ", filename, errmsg)
    os.exit(1)
  end
  return f:write(chunk)
end

local function compile(filename)
  local src = getsource(filename)
  local c = compiler.new()
  local out = c:dostring(src)
  outputs[#outputs+1] = out
end

local function delete_file_ext(name)
  return name:match("(.-)%..-")
end

function parfastc.main()
  outputs[#outputs+1] = header
  for i = 1, #arg do
    compile(arg[i])
  end
  if #arg == 1 then
    writetofile(table.concat(outputs, "\n"), delete_file_ext(arg[1]) .. ".s")
  else
    writetofile(table.concat(outputs, "\n"), "out.s")
  end
  return 0
end

return parfastc