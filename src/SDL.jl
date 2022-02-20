export SDL, sdl
export getSDLError
export to_ARGB, sdl_colors, clear

mutable struct SDL <: System
  win # window
  rnd # renderer
  bgrd # background
  wdth # width
  hght # height
  ttl # title
  function SDL()
    return new(nothing, nothing, nothing, nothing, nothing, nothing)
  end
end

const sdl = SDL()

listenFor(sdl, TICK)

function draw()
  clear()
  map(draw, scn) # TODO investigate parallelization
  # CPP present
  SDL_RenderPresent(sdl.rnd)
end

function handleMessage(s::SDL, m::TICK)
  @debug "SDL tick"
  try
    # handle events
    # CPP poll events
    event_ref = Ref{SDL_Event}()
    while Bool(SDL_PollEvent(event_ref))
      evt = event_ref[]
      sendMessage(evt)
    end

    # draw the scene
    draw()
  catch
    handleException()
  end

end

# CPP remove
function getSDLError()
  x = SDL_GetError()
  return unsafe_string(x)
end

to_ARGB(c) = c
to_ARGB(c::ARGB) = c
to_ARGB(c::Colorant) = ARGB(c)

clear() = fill(sdl.bgrd)

sdl_colors(c::Colorant) = sdl_colors(convert(ARGB{Colors.FixedPointNumbers.Normed{UInt8,8}}, c))
sdl_colors(c::ARGB) = Int.(reinterpret.((red(c), green(c), blue(c), alpha(c))))

# CPP fill (color)
function Base.fill(c::Colorant)
  SDL_SetRenderDrawColor(
      sdl.rnd,
      sdl_colors(c)...,
  )
  SDL_RenderClear(sdl.rnd)
end

# CPP init
function awake!(s::SDL)
  SDL_GL_SetAttribute(SDL_GL_MULTISAMPLEBUFFERS, 4)
  SDL_GL_SetAttribute(SDL_GL_MULTISAMPLESAMPLES, 4)
  r = SDL_Init(SDL_INIT_EVERYTHING)
  if r != 0
    error("unable to initialize SDL: $(getSDLError())")
  end

  TTF_Init()

  mix_init_flags = MIX_INIT_FLAC|MIX_INIT_MP3|MIX_INIT_OGG
  inited = Mix_Init(Int32(mix_init_flags))
  if inited & mix_init_flags != mix_init_flags
      @warn "Failed to initialise audio mixer properly. All sounds may not play correctly\n$(getSDLError())"
  end

  device = Mix_OpenAudio(Int32(22050), UInt16(MIX_DEFAULT_FORMAT), Int32(2), Int32(1024) )
  if device != 0
      @warn "No audio device available, sounds and music will not play.\n$(getSDLError())"
      Mix_CloseAudio()
  end

  # other fields set inside App constructor
  sdl.win = SDL_CreateWindow(sdl.ttl,
    Int32(SDL_WINDOWPOS_CENTERED), Int32(SDL_WINDOWPOS_CENTERED), Int32(sdl.wdth), Int32(sdl.hght),
    UInt32(SDL_WINDOW_ALLOW_HIGHDPI|SDL_WINDOW_OPENGL|SDL_WINDOW_SHOWN));
  SDL_SetWindowMinimumSize(sdl.win, Int32(sdl.wdth), Int32(sdl.hght))
  sdl.rnd = SDL_CreateRenderer(sdl.win, Int32(-1), UInt32(SDL_RENDERER_ACCELERATED | SDL_RENDERER_PRESENTVSYNC))
  SDL_SetRenderDrawBlendMode(sdl.rnd, SDL_BLENDMODE_BLEND)

  draw()

  return true
end

# CPP quit
function shutdown!(s::SDL)  
  SDL_DelEventWatch(window_event_watcher_cfunc[], sdl.win);
  SDL_DestroyRenderer(sdl.rnd)
  SDL_DestroyWindow(sdl.win)

  Mix_HaltMusic()
  Mix_HaltChannel(Int32(-1))
  Mix_CloseAudio()

  TTF_Quit()
  Mix_Quit()
  SDL_Quit()

  return false
end