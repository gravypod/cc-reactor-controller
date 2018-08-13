-- Find he modem automatically
write("Detecting modem")
for a, b for pairs(rs.getSides()) do 
  write(".")
  if peripheral.getType(b) == "modem" then
    print()
    print("Modem Found on side " .. b)
    redne.open(b)
  end
end

local monitoring = {}

-- Function to see if a string starts with another.
function starts_with(needle, haystack)
  if #needle > #haystack then
    return false
  end
  return needle == haystack:sub(1, #needle)
end

--- Test Code for method
-- print("AAA starts_with A: " .. textutils.serialise(starts_with("A", "AAA")))

function PowerManager()
  local this = {}
  this.monitoring = {}
  this.get_sum_of = function(type, stat) 
    local number = 0 
    for name, info in pairs(this.monitoring) do
      if starts_with(type, name) then
        number = number + info[stat]
      end
    end
    return number
  end
  this.control_states = function()
    print("Sending Status Update")
    local storage_current = this.get_sum_of("storage", "current")
    local storage_max = this.get_sum_of("storage", "max")
    local storage_discharge_rate = this.get_sum_of("storage", "rate")
    local min_percent_charge = 1
    -- If the battey is being drained or it
    -- is under 50% capacity start to pull
    -- from any generator over 50% charged.
    if storage_discharge_rate < 0 or storage_current / storage_max < .5 then
      min_percent_charge = .50
    end
    local status_update = {}
    for name, info in pairs(this.monitoring) do 
      local percent_full = info.current / info.max
      if not starts_with("storage", name) and percent_full > min_percent_charge then
        print("Enabling " .. name)
        -- local set = {"name" = name, "status" = true}
        table.insert(status_update, {name=name, status=true})
      end
    end
    local update = textutils.serialise(status_update)
    rednet.broadcast(update, "power_command")
  end
  this.handle = function(update)
    print("Recived update from " .. update.name)
    this.monitoring[update.name] = update
    if starts_with("storage", update.name) then
      print("Found storage update")
      this.control_states()
    end
  end
  
  this.update = function() 
    local sender, message, distance, proto = rednet.receive("power_info")
    if message then
      local info = textutils.unserialise(message)
      this.handle(info)
    else
      print("Got null packet")
    end
  end
  
  return this 
  
end

local power_manager = PowerManager()

while true do
  power_manager.update()
end

