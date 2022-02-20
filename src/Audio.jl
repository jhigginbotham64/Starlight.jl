export play_sound

# CPP play sound (sfile, loops, ticks)
function play_sound(sound_file, loops=0, ticks=-1)
  sample=Mix_LoadWAV_RW(SDL_RWFromFile(sound_file, "rb"), 1);
  if sample == C_NULL
      @warn "Could not load sound file: $sound_file\n$(getSDLError())"
      return
  end
  r = Mix_PlayChannelTimed(Int32(-1), sample, loops, ticks)
  if r == -1
      @warn "Unable to play sound $sound_file\n$(getSDLError())"
  end
end
