export Input

mutable struct Input <: System end

function handleMessage!(i::Input, m::TICK)
  @debug "Input tick"
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
end

function awake!(i::Input)
  @debug "Input awake!"
  listenFor(i, TICK)
end

function shutdown!(i::Input)
  @debug "Input shutdown!"
  unlistenFrom(i, TICK)
end
