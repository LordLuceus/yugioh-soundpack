local bit = require("bit")
local class = require("pl.class")
local ppi = require("ppi")

class.SoundStack()

function SoundStack:_init(audio)

  self.audio = audio
  self.bass = audio.BASS()
  self.config = ppi.Load(world.GetVariable('Configuration'))
  self.sounds = {}
  self.overlap_time = 0.2 -- 10% of file length

end

-- adds a sound and plays it as soon as possible
function SoundStack:Add(sound, time)

  if type(sound) == 'string' then
    -- we got the filename only, so we need to create a new sound object
    sound = self.bass:StreamCreateFile(false, sound)
  end

  sound:SetAttribute(self.audio.CONST.attribute.volume, self.config.Get('settings', 'SoundVolume')/100)

  self:Cleanup()

  local remaining_time = self:GetRemainingTime()

  self.sounds[#(self.sounds)+1] = {sound = sound, time = time or sound.length - (sound.length * self.overlap_time)}

  if remaining_time == 0 then
    -- we need to add the start time of the sound
    self.sounds[#(self.sounds)].start_time = world.GetInfo(232)
    sound:Play()
  elseif #(self.sounds) == 2 then
    -- the previous sound was the only one, so we need another timer
    world.DoAfterSpecial(remaining_time, 'SoundStack:PlayNext()', sendto.script)
  end

end

function SoundStack:GetRemainingTime()

  local time = 0

  for i, snd in pairs(self.sounds) do

    if snd.start_time ~= nil then

      time = time + math.max(0, snd.time - (world.GetInfo(232) - snd.start_time))

    else

      time = time + snd.time

    end

  end

  return time

end

function SoundStack:Cleanup(all)

  all = all or false

  while #(self.sounds) > 0 do

    if self.sounds[1].sound:IsActive() == self.audio.CONST.active.stopped and self.sounds[1].start_time ~= nil or all == true then
      self.sounds[1].sound:Stop()
      self.sounds[1].sound:Free()
      table.remove(self.sounds, 1)
    else
      break
    end

  end

end

-- will automatically play the next sound to be played
function SoundStack:PlayNext()

  self:Cleanup()

  for i, snd in pairs(self.sounds) do
    if snd.sound:IsActive() == self.audio.CONST.active.stopped and snd.start_time == nil then
      snd.start_time = world.GetInfo(232)
      snd.sound:Play()
      if #(self.sounds) > i then
        world.DoAfterSpecial(snd.time, 'SoundStack:PlayNext()', sendto.script)
      end
      break
    end
  end

end

return SoundStack