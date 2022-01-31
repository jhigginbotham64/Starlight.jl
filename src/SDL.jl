export SDL, sdl
export getSDLError, getWindowSize, window_paused
export draw, to_ARGB, sdl_colors, clear, clear_and_present

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

function clear_and_present()
  clear()
  SDL_RenderPresent(sdl.rnd)
end

draw(e::Entity) = nothing

function handleMessage(s::SDL, m::TICK)
  @debug "SDL tick"
  # handle events
  try
    event_ref = Ref{SDL_Event}()
    while Bool(SDL_PollEvent(event_ref))
      evt = event_ref[]
      sendMessage(evt)
    end
  catch e
    rethrow()
  end

  # draw the scene
  map(draw, scn) # TODO could parallelize if Scene implemented the Threads.@threads interface
  clear_and_present()

end

function getSDLError()
  x = SDL_GetError()
  return unsafe_string(x)
end

# Forward reference for @cfunction
function windowEventWatcher end
const window_event_watcher_cfunc = Ref(Ptr{Nothing}(0))

const window_paused = Threads.Atomic{UInt8}(0) # Whether or not the game should be running (if lost focus)

function makeWinRenderer(title::String, w::Int, h::Int)
    win = SDL_CreateWindow(title,
        Int32(SDL_WINDOWPOS_CENTERED), Int32(SDL_WINDOWPOS_CENTERED), Int32(w), Int32(h),
        UInt32(SDL_WINDOW_ALLOW_HIGHDPI|SDL_WINDOW_OPENGL|SDL_WINDOW_SHOWN));
        SDL_SetWindowMinimumSize(win, Int32(w), Int32(h))
    window_event_watcher_cfunc[] = @cfunction(windowEventWatcher, Cint, (Ptr{Nothing}, Ptr{SDL_Event}))
    SDL_AddEventWatch(window_event_watcher_cfunc[], win);

    renderer = SDL_CreateRenderer(win, Int32(-1), UInt32(SDL_RENDERER_ACCELERATED | SDL_RENDERER_PRESENTVSYNC))
    SDL_SetRenderDrawBlendMode(renderer, SDL_BLENDMODE_BLEND)
    return win,renderer
end

# This function handles all window events.
# We currently do no allow window resizes
function windowEventWatcher(data_ptr::Ptr{Cvoid}, event_ptr::Ptr{SDL_Event})::Cint
    ev = unsafe_load(event_ptr, 1)
    #ee = evt.type
    #t = UInt32(ee[4]) << 24 | UInt32(ee[3]) << 16 | UInt32(ee[2]) << 8 | ee[1]
    t = ev.type
    if (t == SDL_WindowEvent)
        event = unsafe_load( Ptr{SDL_WindowEvent}(pointer_from_objref(ev)) )
        winevent = event.event;  # confusing, but that's what the field is called.
        if (winevent == SDL_WINDOWEVENT_FOCUS_LOST || winevent == SDL_WINDOWEVENT_HIDDEN || winevent == SDL_WINDOWEVENT_MINIMIZED)
            # Stop game playing when out of focus
                window_paused[] = 1
            #end
        elseif (winevent == SDL_WINDOWEVENT_FOCUS_GAINED || winevent == SDL_WINDOWEVENT_SHOWN)
            window_paused[] = 0
        end
    end
    return 0
end

function getWindowSize()
    w,h,w_highDPI,h_highDPI = Int32[0],Int32[0],Int32[0],Int32[0]
    SDL_GetWindowSize(sdl.win, w, h)
    SDL_GL_GetDrawableSize(sdl.win, w_highDPI, h_highDPI)
    return w[],h[],w_highDPI[],h_highDPI[]
end

to_ARGB(c) = c
to_ARGB(c::ARGB) = c
to_ARGB(c::Colorant) = ARGB(c)

clear() = fill(sdl.bgrd)

sdl_colors(c::Colorant) = sdl_colors(convert(ARGB{Colors.FixedPointNumbers.Normed{UInt8,8}}, c))
sdl_colors(c::ARGB) = Int.(reinterpret.((red(c), green(c), blue(c), alpha(c))))

function Base.fill(c::Colorant)
  SDL_SetRenderDrawColor(
      sdl.rnd,
      sdl_colors(c)...,
  )
  SDL_RenderClear(sdl.rnd)
end

function Base.fill(sf::Ptr{SDL_Surface}) 
  texture = SDL_CreateTextureFromSurface(sdl.rnd, sf)
  SDL_RenderCopy(sdl.rnd, texture, C_NULL, C_NULL)
  SDL_DestroyTexture(texture)
end

function awake!(s::SDL)
  SDL_GL_SetAttribute(SDL_GL_MULTISAMPLEBUFFERS, 4)
  SDL_GL_SetAttribute(SDL_GL_MULTISAMPLESAMPLES, 4)
  r = SDL_Init(UInt32(SDL_INIT_VIDEO | SDL_INIT_JOYSTICK | SDL_INIT_HAPTIC | SDL_INIT_GAMECONTROLLER | SDL_INIT_EVENTS))
  if r != 0
    error("unable to initialize SDL: $(getSDLError())")
  end

  TTF_Init()

  # other fields set inside App constructor
  win, rnd = makeWinRenderer(sdl.ttl, sdl.wdth, sdl.hght)
  sdl.win = win
  sdl.rnd = rnd

  clear_and_present()

  return true
end

function shutdown!(s::SDL)  
  SDL_DelEventWatch(window_event_watcher_cfunc[], sdl.win);
  SDL_DestroyRenderer(sdl.rnd)
  SDL_DestroyWindow(sdl.win)

  TTF_Quit()
  SDL_Quit()

  return false
end