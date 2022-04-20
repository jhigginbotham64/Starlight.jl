export TS, ts
export to_ARGB, getSDLError, sdl_colors, vulkan_colors, clear, clrclr


mutable struct TS <: System end

const ts = TS()

function draw()
  TS_VkBeginDrawPass()

  map(draw, scn) # TODO investigate parallelization

  TS_VkEndDrawPass(vulkan_colors(app[].bgrd)...)
end

function handleMessage(t::TS, m::TICK)
  @debug "TS tick"
  try
    evt_ref = Ref{SDL_Event}()
    while Bool(SDL_PollEvent(evt_ref))
      evt = evt_ref[]
      ty = evt.type
      if ty ∈ [SDL_AUDIODEVICEADDED, SDL_AUDIODEVICEREMOVED]
        sendMessage(evt.adevice)
      elseif ty == SDL_CONTROLLERAXISMOTION
        sendMessage(evt.caxis)
      elseif ty ∈ [SDL_CONTROLLERBUTTONDOWN, SDL_CONTROLLERBUTTONUP]
        sendMessage(evt.cbutton)
      elseif ty ∈ [SDL_CONTROLLERDEVICEADDED, SDL_CONTROLLERDEVICEREMOVED, SDL_CONTROLLERDEVICEREMAPPED]
        sendMessage(evt.cdevice)
      elseif ty ∈ [SDL_DOLLARGESTURE, SDL_DOLLARRECORD]
        sendMessage(evt.dgesture)
      elseif ty ∈ [SDL_DROPFILE, SDL_DROPTEXT, SDL_DROPBEGIN, SDL_DROPCOMPLETE]
        sendMessage(evt.drop)
      elseif ty ∈ [SDL_FINGERMOTION, SDL_FINGERDOWN, SDL_FINGERUP]
        sendMessage(evt.tfinger)
      elseif ty ∈ [SDL_KEYDOWN, SDL_KEYUP]
        sendMessage(evt.key)
      elseif ty == SDL_JOYAXISMOTION
        sendMessage(evt.jaxis)
      elseif ty == SDL_JOYBALLMOTION
        sendMessage(evt.jball)
      elseif ty == SDL_JOYHATMOTION
        sendMessage(evt.jhat)
      elseif ty ∈ [SDL_JOYBUTTONDOWN, SDL_JOYBUTTONUP]
        sendMessage(evt.jbutton)
      elseif ty ∈ [SDL_JOYDEVICEADDED, SDL_JOYDEVICEREMOVED]
        sendMessage(evt.jdevice)
      elseif ty == SDL_MOUSEMOTION
        sendMessage(evt.motion)
      elseif ty ∈ [SDL_MOUSEBUTTONDOWN, SDL_MOUSEBUTTONUP]
        sendMessage(evt.button)
      elseif ty == SDL_MOUSEWHEEL
        sendMessage(evt.wheel)
      elseif ty == SDL_MULTIGESTURE
        sendMessage(evt.mgesture)
      elseif ty == SDL_QUIT
        sendMessage(evt.quit)
      elseif ty == SDL_SYSWMEVENT
        sendMessage(evt.syswm)
      elseif ty == SDL_TEXTEDITING
        sendMessage(evt.edit)
      elseif ty == SDL_TEXTINPUT
        sendMessage(evt.text)
      elseif ty == SDL_USEREVENT
        sendMessage(evt.user)
      elseif ty == SDL_WINDOWEVENT
        sendMessage(evt.window)
      else
        sendMessage(evt)
      end
    end

    draw()
  catch
    handleException()
  end

end

getSDLError() = unsafe_string(TS_SDLGetError())

to_ARGB(c) = c
to_ARGB(c::ARGB) = c
to_ARGB(c::Colorant) = ARGB(c)

sdl_colors(c::Colorant) = sdl_colors(convert(ARGB{Colors.FixedPointNumbers.Normed{UInt8,8}}, c))
sdl_colors(c::ARGB) = Int.(reinterpret.((red(c), green(c), blue(c), alpha(c))))

vulkan_colors(c::Colorant) = Float32.(sdl_colors(c) ./ 255)

clear() = fill(app[].bgrd)

function Base.fill(c::Colorant)
  TS_VkCmdClearColorImage(vulkan_colors(c)...)
end

function awake!(t::TS)
  TS_Init("Hello SDL!", app[].wdth, app[].hght)
  draw()
  listenFor(ts, TICK)
  return true
end

function shutdown!(t::TS)  
  unlistenFrom(ts, TICK)
  TS_Quit()
  return false
end