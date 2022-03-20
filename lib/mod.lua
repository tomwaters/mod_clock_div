local mod = require 'core/mods'
local Divider = require 'mod_clock_div/lib/divider'
local dividers = {}
local current_divider = 1
local current_option = 1

mod.hook.register('system_post_startup', 'clock div startup', function()
  table.insert(dividers, Divider:new(1, 1))
  table.insert(dividers, Divider:new(2, 2))
  table.insert(dividers, Divider:new(3, 3))
  table.insert(dividers, Divider:new(4, 4))
  load_settings()
end)

mod.hook.register('script_pre_init', 'clock div init', function()
  for i = 1, #dividers do
    dividers[i]:start()
  end
end)


local m = {}
m.key = function(n, z)
  if n == 2 and z == 1 then
    -- return to the mod selection menu
    mod.menu.exit()
  end
end

m.enc = function(n, d)
  if n == 2 then
    current_option = util.clamp(current_option + d, 1, 5)
  elseif n == 3 then 
    if current_option == 1 then
      current_divider = util.clamp(current_divider + d, 1, #dividers)
    elseif current_option == 2 then
      if d < 0 and dividers[current_divider].running then
        dividers[current_divider]:stop()
      elseif d > 1 and not dividers[current_divider].running then
        dividers[current_divider]:start()
      end
    elseif current_option == 3 then
      dividers[current_divider].div = util.clamp(dividers[current_divider].div + d, 1, #dividers[current_divider].divisions)
    elseif current_option == 4 then
      local new_device = util.clamp(dividers[current_divider].midi_out_device_id + d, 1, 4)
      if new_device ~= dividers[current_divider].midi_out_device_id then
        dividers[current_divider]:set_midi_device(new_device)
      end
    elseif current_option == 5 then
      dividers[current_divider].midi_out_channel = util.clamp(dividers[current_divider].midi_out_channel + d, 1, 16)
    end
    save_settings()
  end
  mod.menu.redraw()
end

local disp_bright = 15
local disp_dim = 5
m.redraw = function()
  screen.clear()

  screen.move(110, 16)
  screen.font_size(22)
  screen.level(current_option == 1 and disp_bright or disp_dim)
  screen.text(current_divider)
  
  screen.font_size(8)
  screen.move(2, 28)
  screen.level(current_option == 2 and disp_bright or disp_dim)
  screen.text("ENABLED: "..(dividers[current_divider].running and "Y" or "N"))
  screen.move(2, 36)
  screen.level(current_option == 3 and disp_bright or disp_dim)
  screen.text("DIVISION: "..dividers[current_divider].divisions[dividers[current_divider].div])
  screen.move(2, 44)
  screen.level(current_option == 4 and disp_bright or disp_dim)
  screen.text("MIDI DEVICE: "..dividers[current_divider].midi_out_device_id)
  screen.move(2, 52)
  screen.level(current_option == 5 and disp_bright or disp_dim)
  screen.text("MIDI CHAN: "..dividers[current_divider].midi_out_channel)
  
  screen.update()
end

function save_settings()
  local filename = _path.data.."/mod_clock_div/settings"
  local fd = io.open(filename, "w+")
  if fd then
    io.output(fd)
    for i = 1, #dividers do
      io.write(string.format("\"%d.running\": %s\n", i, dividers[i].running and 1 or 0))
      io.write(string.format("\"%d.div\": %s\n", i, dividers[i].div))
      io.write(string.format("\"%d.midi_out_device_id\": %s\n", i, dividers[i].midi_out_device_id))
      io.write(string.format("\"%d.midi_out_channel\": %s\n", i, dividers[i].midi_out_channel))
    end
    
    io.close(fd)
  end
end

function load_settings()
  local filename = _path.data.."/mod_clock_div/settings"
  local fd = io.open(filename, "r")
  if fd then
    io.close(fd)
    for line in io.lines(filename) do
      local id, param, value = string.match(line, "\"(%d).(.*)\":(.*)")
      if param == "midi_out_device_id" then
        dividers[tonumber(id)]:set_midi_device(tonumber(value))
      else
        if param == "running" then
          value = value == 1
        else
          value = tonumber(value)
        end
        dividers[tonumber(id)][param] = value
      end
    end
  end
end

m.init = function() end -- on menu entry, ie, if you wanted to start timers
m.deinit = function() end -- on menu exit

-- register the mod menu
--
-- NOTE: `mod.this_name` is a convienence variable which will be set to the name
-- of the mod which is being loaded. in order for the menu to work it must be
-- registered with a name which matches the name of the mod in the dust folder.
--
mod.menu.register(mod.this_name, m)


--/clock.transport.start — called by transport start
--clock.transport.stop — called by transport stop
