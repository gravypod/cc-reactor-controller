local update_tracker = {}

function has_missed_updates(name)
  local last_update = update_tracker[name]
  if last_update then
    return os.clock() - last_update >= 15
  end
  return false
end

function get_box_color(name)
  if has_missed_updates(name) then
    return colors.red
  end
  return colors.blue
end

for a, b in pairs(rs.getSides()) do
  if peripheral.getType(b) == "modem" then
    rednet.open(b)
  end
end

function get_keys(t)
  local keys = {}
  for k, v in pairs(t) do
    table.insert(keys, k)
  end
  table.sort(keys)
  return keys
end

function get_charge_color(percent_charge)
  local high = colors.green
  local medium = colors.yellow
  local low = colors.red
  if percent_charge <= 25 then
    return low
  end
  if percent_charge > 25 and percent_charge < 50 then
    return medium
  end
  if percent_charge >= 50 then
    return high
  end
end

function draw_resource_info(monitor, start_x, start_y, end_x, end_y, text, color, bg)
  monitor.setTextColor(color)
  monitor.setBackgroundColor(bg)
  local middle_width = ((end_x - start_x) / 2) - math.floor(#text / 2)
  local middle_height = (end_y - start_y) / 2
  
  local middle_x = start_x + middle_width
  local middle_y = start_y + middle_height
  
  monitor.setCursorPos(middle_x, middle_y)
  monitor.write(text)
end

function draw_resource(monitor, resource, charge, start_x, start_y, end_x, end_y)
  local box_color = get_box_color(resource.name)
  local bar_color = get_charge_color(charge)
  local bar_length = (charge * (end_x - start_x)) / 100
  local bar_end = start_x + bar_length

  paintutils.drawBox(start_x, start_y, end_x, end_y, box_color)
  paintutils.drawFilledBox(start_x + 1, start_y + 1, bar_end - 1, end_y - 1, bar_color)
  
  monitor.setTextColor(colors.white)
  monitor.setBackgroundColor(box_color)
  
  monitor.setCursorPos(start_x, start_y)
  monitor.write(resource.name .. " [" .. charge .. "%]")
  
  local color = colors.white
  local bg = colors.blue
  local text = "ERR"
  
  if resource.rate < 0 then
    text = "DISCHARGE"
  end
  
  if resource.rate > 0 then
    text = "CHARGING"
  end
  
  if resource.rate == 0 then
    text = "CHARGED"
  end
  
  if has_missed_updates(resource.name) then
    color = colors.red
    bg = colors.yellow
    text = "OFFLINE"
  end 
  
  draw_resource_info(monitor, start_x, start_y, end_x, end_y, text, color, bg)
  
end

function setup_display(monitor)
  monitor.setBackgroundColor(colors.black)
  monitor.setTextScale(.5)
  monitor.clear()
end

function draw(monitor, resources)
  setup_display(monitor)
  
  local width, height = monitor.getSize()
  
  local pad = 2
  
  local start_x = pad
  local start_y = pad
  
  local bar_w = 20
  local bar_h = 5
  
  local idx = 1
  local names = get_keys(resources)
  
  for start_y = pad, height - bar_h - pad , pad + bar_h do 
    for start_x = pad, width - bar_w - pad, pad + bar_w do
      
      local resource = resources[names[idx]]
      
      if resource == nil then
        return
      end
      
      local end_x = start_x + bar_w
      local end_y = start_y + bar_h
      local charge = math.floor((resource.current / resource.max) * 100)
      
      draw_resource(monitor, resource, charge, start_x, start_y, end_x, end_y)
      
      idx = idx + 1
    end
  end
end

local power_resources = {}
local monitor = peripheral.find("monitor", function (name, object) return object.isColour() end)

while true do 
  sender, message, proto = rednet.receive("power_info")
  update = textutils.unserialise(message)
  
  print("Got update from " .. update.name)
  power_resources[update.name] = update
  update_tracker[update.name] = os.clock()
  term.redirect(monitor)
  draw(monitor, power_resources)
  term.redirect(term.native())
  
end
