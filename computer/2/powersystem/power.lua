require "solar.lua"

-- Configuration: Put anything you'd like to 
-- monitor in this.

local sides = {
  "right"
} 

-- Beginning of Code. Do not read past here.

local solar_systems = {}

-- Initialize system from sides in config
for side in sides do
  solar_systems[side] = SolarSystem(side)
end

while true do 
  -- 6.0 and 17.00
  local current_time = os.time()
  local has_daylight = current_time >= 6 && current_time <= 17
  local ticks_till_morning = 
  for side, system in pairs(solar_systems) do
    local charge = system.get_percent_charged()
    
  end
  os.sleep(15)
end 
