counter = 1
function enum(reset)
  if reset == true then counter = 1 end
  local val = counter
  counter = counter + 1
  return val
end

local function parfast_assert(expr, errmsg)
  if not expr then
    print("Error: " .. errmsg)
    os.exit(1)
  end
end

local function hex(str)
  local hex = {}
  for i = 1, #str do
    local byte = string.byte(str, i)
    table.insert(hex, "0x" .. string.format("%02X", byte))
  end
  return table.concat(hex, ",")
end

local function bool_to_number(value)
  return value and 1 or 0
end
