#!/usr/bin/env lua

local defined_debug = false
local bin = "parfast"
local c = table.concat
local f = string.format

local function cmd(...)
  local code, _, _ = os.execute(table.concat({...}, " "))
  return code
end

local function run_rule(rule_buffer)
  for i, v in pairs(rule_buffer.rules) do
    print("Running rule '" .. i .. "': " .. v)
    local code = cmd(v)
    if not code then
      print("Error at rule " .. i .. " failed with code " .. (code and "0" or "1"))
      return false
    end
  end
end

local command_build
command_build = {
  files = {
    "./src/utils.lua",
    "./src/opdef.lua",
    "./src/lex.lua",
    "./src/parser.lua",
    "./src/codegen.lua",
    "./src/checker.lua",
    "./src/parfast.lua",
  }
}
command_build.rules = {
  f("cat %s > %s", c(command_build.files, " "), bin..".lua"),
  f("luac %s", bin..".lua"),
  f("sed '1 i\\#\\!\\/usr/bin/env lua' luac.out > %s", bin),
  f("chmod +x %s", bin),
  "rm luac.out",
} if not defined_debug then table.insert(command_build.rules, "rm parfast.lua") end

run_rule(command_build)