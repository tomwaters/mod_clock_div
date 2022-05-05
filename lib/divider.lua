Divider = {}
Divider.__index = Divider

function Divider:new(div, chan)
  local o = {
    divisions = {0.25, 0.5, 1.5, 1, 2, 4, 6, 8, 16},
    div = div,
    running = false,
    chance = 1.0,
    
    midi_out_device_id = 1,
    midi_out_channel = chan,
    active_notes = {}
  }
  o.midi_out_device = midi.connect(o.midi_out_device_id)
  
  setmetatable(o, Divider)
  
  return o
end

function Divider:start()
  self.notes_off_metro = metro.init()
  self.notes_off_metro.event = function() self:all_notes_off() end
  
  self.running = true
  clock.run(Divider.step, self)
end

function Divider:stop()
  self.notes_off_metro:stop()
  self.running = false
end

function Divider:set_midi_device(device_id)
  self.midi_out_device_id = device_id
  self.midi_out_device = midi.connect(device_id)
end

function Divider:all_notes_off()
  for _, a in pairs(self.active_notes) do
    self.midi_out_device:note_off(a, nil, self.midi_out_channel)
  end
  self.active_notes = {}
end

function Divider:step()
  while self.running do
    clock.sync(self.divisions[self.div])
    self:all_notes_off()
    
    if math.random() < self.chance then
      local n = 60
      self.midi_out_device:note_on(n, 127, self.midi_out_channel)
      table.insert(self.active_notes, n)
    
      self.notes_off_metro:start(0.01, 1)
    end
  end
end

return Divider