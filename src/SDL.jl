export SDL, sdl

mutable struct SDL <: Starlight.System
  function SDL()
    # populate fields from config (make sure to add them to definition first)
    return new()
  end
end

const sdl = SDL()

listenFor(sdl, Starlight.TICK)

function handleMessage(s::SDL, m::Starlight.TICK)
  @debug "SDL tick"
  try
    event_ref = Ref{SDL_Event}()
    while Bool(SDL_PollEvent(event_ref))
      evt = event_ref[]
      @debug "SDL sending message $(evt) with type $(evt.type)"
      sendMessage(evt)
    end
  catch e
    rethrow()
  end
end

function getSDLError()
  x = SDL_GetError()
  return unsafe_string(x)
end

function awake!(s::SDL)
  SDL_GL_SetAttribute(SDL_GL_MULTISAMPLEBUFFERS, 4)
  SDL_GL_SetAttribute(SDL_GL_MULTISAMPLESAMPLES, 4)
  r = SDL_Init(UInt32(SDL_INIT_VIDEO | SDL_INIT_JOYSTICK | SDL_INIT_HAPTIC | SDL_INIT_GAMECONTROLLER | SDL_INIT_EVENTS))
  if r != 0
    error("unable to initialize SDL: $(getSDLError())")
  end

  TTF_Init()

  return true
end

function shutdown!(s::SDL)  
  TTF_Quit()
  SDL_Quit()

  return false
end