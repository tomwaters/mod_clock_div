Divider = {}
Divider.__index = Divider

function Divider:new(div, chan)
  local o = {
    divisions = {0.25, 0.5, 1, 2, 4, 8, 16},
    div = div,
    running = false,
    
    midi_out_device = midi.connect(1),
    midi_out_channel = chan,
    active_notes = {},

    notes_off_metro = metro.init()
  }
  o.notes_off_metro.event = function() o:all_notes_off() end

  setmetatable(o, Divider)
  
  return o
end

function Divider:start()
  self.running = true
  clock.run(Divider.step, self)
end

function Divider:stop()
  self.running = false
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
    
    local n = 60
    self.midi_out_device:note_on(n, 127, self.midi_out_channel)
    table.insert(self.active_notes, n)
    
    self.notes_off_metro:start(0.01, 1)
  end
end

return Divider