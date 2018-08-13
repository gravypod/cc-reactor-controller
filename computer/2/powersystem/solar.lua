function SolarSystem(direction)

  local generator = peripheral.wrap(direction)
  local max_energy_storage = generator.getMaxEnergyStored()
  local self = {}
  
  function self.get_percent_charged()
    local current_energy_stored = generator.getEnergyStored()
    return current_energy_stored / max_energy_stored
  end
  
  function self.is_on()
    return redstone.getOutput(direction)
  end
  
  function self.set_state(state)
    redstone.setOutput(direction, state)
  end
  
  return self
end 
