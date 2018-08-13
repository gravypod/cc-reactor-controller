-- Config

-- Side to watch 
local sides = {"left", "right"}

-- Modem Location
local modem = "bottom"

-- Computer Controlle Name 
local name = "power_3"

broadcast_network = "power_info"
control_network = "power_control"

-- End of config
local rate_monitors = {}

function starts_with(needle, haystack)
  if #needle > #haystack then
    return false
  end
  return needle == haystack:sub(1, #needle)
end

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
  self.update_samples = function ()
    self.poll_block()
    if table.getn(samples) > 2 then
      table.remove(samples, 1)
    end
    table.insert(samples, self.power.current)
  end
  self.update = function ()
    self.update_samples()
    if redstone.getOutput(side) and self.power.current == 0 then
      self.output(false)
    end
    self.broadcast()
  end
  
  self.output = function (signal)
    if signal then
      print("Turning on " .. self.name)
    else
      print("Turning off " .. self.name)
    end
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
  local sleep_time = 10
  if starts_with("storage", name) then
    os.sleep(sleep_time)
  else
    sender, message, distance, proto = rednet.receive(control_network, sleep_time)
    if message then
      print("Got update")
      local commands = textutils.unserialise(message)
      handle_update(rate_monitors, commands)
    end
  end
  for name, monitor in pairs(rate_monitors) do
    monitor.update()
  end 
end
