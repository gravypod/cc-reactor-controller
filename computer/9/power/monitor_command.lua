rednet.open("bottom")
while true do 
  sender, message, proto = rednet.receive("power_control")
  print(sender)
  print(message)
  print(proto)
end
  
