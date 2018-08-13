-- Config

-- Side to watch 
local sides = {"left", "right"}

-- Modem Location
local modem = "bottom"

-- Computer Controlle Name 
local name = "power_1"

broadcast_network = "power_info"
control_network = "power_control"

-- End of config
local rate_monitors = {}

function has_key(t, key)
  for k, v in pairs(t) do
    if k == key then
      return true
    end
  end
  return false
end

function handle_update(rate_monitors, commands)
  for i, update in ipairs(commands) do
    if has_key(rate_monitors, update.name) then
      local monitor = rate_monitors[update.name]
      monitor.output(update.status)
    end
  end
end 

function RateMonitor(side, name)
  local self = {}

  local samples = {}
  local block = peripheral.wrap(side)
  
  self.name = name .. "_" .. side
  
  self.power = {}
  self.power.max = 0
  self.power.current = 0
  
  self.poll_block = function()
    self.power.max = block.getMaxEnergyStored()
    self.power.current = block.getEnergyStored()
  end
  
  self.get_rate = function() 
    
    local num_samples = table.getn(samples)
    local diff_sum = 0

    if num_samples < 2 then
      return diff_sum
    end

    for i = 2, num_samples do
      local diff = samples[i] - samples[i - 1]
      diff_sum = diff + diff_sum
    end
    
    return diff_sum / num_samples 
  end
  
  self.broadcast = function ()
    local info = {}
    
    info.rate = self.get_rate()
    info.name = self.name
    
    for k, v in pairs(self.power) do 
      info[k] = v 
    end
    
    local update = textutils.serialise(info)
    print("Sending " .. update)
    rednet.broadcast(update, broadcast_network)
  end
  self.update = function ()
    self.poll_block()
    if table.getn(samples) > 2 then
      table.remove(samples, 1)
    end
    table.insert(samples, self.power.current)
    self.broadcast()
  end
  
  self.output = function (signal)
    if signal then
      print("Turning on " .. self.name)
    else
      print("Turning off " .. self.name)
    end
    -- print("Outputting " .. (if signal then "on" else "off") .. " for " .. self.name)
    print(side)
    print(signal)
    redstone.setOutput(side, signal)
  end
  
  return self
end 

for i, side in ipairs(sides) do
  local monitor = RateMonitor(side, name)
  rate_monitors[monitor.name] = monitor
end

rednet.open(modem)

while true do
  sender, message, distance, proto = rednet.receive(control_network, 10)
  if message then
    print("Got update")
    local commands = textutils.unserialise(message)
    handle_update(rate_monitors, commands)
  end
  for name, monitor in pairs(rate_monitors) do
    monitor.update()
  end 
end
