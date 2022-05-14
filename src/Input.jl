export input!

function input!(ecs::ECS)
  events = []
  event_ref = Ref{SDL_Event}()
  while Bool(SDL_PollEvent(event_ref))
    push!(events, event_ref[])
  end

  Threads.@threads for event ∈ events
    t = event.type
    if t ∈ [SDL_AUDIODEVICEADDED, SDL_AUDIODEVICEREMOVED]
      runcomponent!(ecs, :onadevice, event.adevice)
    elseif t == SDL_CONTROLLERAXISMOTION
      runcomponent!(ecs, :oncaxis, event.caxis)
    elseif t ∈ [SDL_CONTROLLERBUTTONDOWN, SDL_CONTROLLERBUTTONUP]
      runcomponent!(ecs, :oncbutton, event.cbutton)
    elseif t ∈ [SDL_CONTROLLERDEVICEADDED, SDL_CONTROLLERDEVICEREMOVED, SDL_CONTROLLERDEVICEREMAPPED]
      runcomponent!(ecs, :oncdevice, event.cdevice)
    elseif t ∈ [SDL_DOLLARGESTURE, SDL_DOLLARRECORD]
      runcomponent!(ecs, :ondgesture, event.dgesture)
    elseif t ∈ [SDL_DROPFILE, SDL_DROPTEXT, SDL_DROPBEGIN, SDL_DROPCOMPLETE]
      runcomponent!(ecs, :ondrop, event.drop)
    elseif t ∈ [SDL_FINGERMOTION, SDL_FINGERDOWN, SDL_FINGERUP]
      runcomponent!(ecs, :ontfinger, event.tfinger)
    elseif t ∈ [SDL_KEYDOWN, SDL_KEYUP]
      runcomponent!(ecs, :onkey, event.key)
    elseif t == SDL_JOYAXISMOTION
      runcomponent!(ecs, :onjaxis, event.jaxis)
    elseif t == SDL_JOYBALLMOTION
      runcomponent!(ecs, :onjball, event.jball)
    elseif t == SDL_JOYHATMOTION
      runcomponent!(ecs, :onjhat, event.jhat)
    elseif t ∈ [SDL_JOYBUTTONDOWN, SDL_JOYBUTTONUP]
      runcomponent!(ecs, :onjbutton, event.jbutton)
    elseif t ∈ [SDL_JOYDEVICEADDED, SDL_JOYDEVICEREMOVED]
      runcomponent!(ecs, :onjdevice, event.jdevice)
    elseif t == SDL_MOUSEMOTION
      runcomponent!(ecs, :onmotion, event.motion)
    elseif t ∈ [SDL_MOUSEBUTTONDOWN, SDL_MOUSEBUTTONUP]
      runcomponent!(ecs, :onbutton, event.button)
    elseif t == SDL_MOUSEWHEEL
      runcomponent!(ecs, :onwheel, event.wheel)
    elseif t == SDL_MULTIGESTURE
      runcomponent!(ecs, :onmgesture, event.mgesture)
    elseif t == SDL_QUIT
      runcomponent!(ecs, :onquit, event.quit)
    elseif t == SDL_SYSWMEVENT
      runcomponent!(ecs, :onsyswm, event.syswm)
    elseif t == SDL_TEXTEDITING
      runcomponent!(ecs, :onedit, event.edit)
    elseif t == SDL_TEXTINPUT
      runcomponent!(ecs, :ontext, event.text)
    elseif t == SDL_USEREVENT
      runcomponent!(ecs, :onuser, event.user)
    elseif t == SDL_WINDOWEVENT
      runcomponent!(ecs, :onwindow, event.window)
    else
      runcomponent!(ecs, :oncommon, event)
    end
  end
end