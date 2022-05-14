export input!

function input!(ecs::ECS)
  events = []
  event_ref = Ref{SDL_Event}()
  while Bool(SDL_PollEvent(event_ref))
    push!(events, event_ref[])
  end

  Threads.@threads for event ∈ events
    ty = event.type
    if ty ∈ [SDL_AUDIODEVICEADDED, SDL_AUDIODEVICEREMOVED]
      runcomponent!(ecs, :onadevice, event.adevice)
    elseif ty == SDL_CONTROLLERAXISMOTION
      runcomponent!(ecs, :oncaxis, event.caxis)
    elseif ty ∈ [SDL_CONTROLLERBUTTONDOWN, SDL_CONTROLLERBUTTONUP]
      runcomponent!(ecs, :oncbutton, event.cbutton)
    elseif ty ∈ [SDL_CONTROLLERDEVICEADDED, SDL_CONTROLLERDEVICEREMOVED, SDL_CONTROLLERDEVICEREMAPPED]
      runcomponent!(ecs, :oncdevice, event.cdevice)
    elseif ty ∈ [SDL_DOLLARGESTURE, SDL_DOLLARRECORD]
      runcomponent!(ecs, :ondgesture, event.dgesture)
    elseif ty ∈ [SDL_DROPFILE, SDL_DROPTEXT, SDL_DROPBEGIN, SDL_DROPCOMPLETE]
      runcomponent!(ecs, :ondrop, event.drop)
    elseif ty ∈ [SDL_FINGERMOTION, SDL_FINGERDOWN, SDL_FINGERUP]
      runcomponent!(ecs, :ontfinger, event.tfinger)
    elseif ty ∈ [SDL_KEYDOWN, SDL_KEYUP]
      runcomponent!(ecs, :onkey, event.key)
    elseif ty == SDL_JOYAXISMOTION
      runcomponent!(ecs, :onjaxis, event.jaxis)
    elseif ty == SDL_JOYBALLMOTION
      runcomponent!(ecs, :onjball, event.jball)
    elseif ty == SDL_JOYHATMOTION
      runcomponent!(ecs, :onjhat, event.jhat)
    elseif ty ∈ [SDL_JOYBUTTONDOWN, SDL_JOYBUTTONUP]
      runcomponent!(ecs, :onjbutton, event.jbutton)
    elseif ty ∈ [SDL_JOYDEVICEADDED, SDL_JOYDEVICEREMOVED]
      runcomponent!(ecs, :onjdevice, event.jdevice)
    elseif ty == SDL_MOUSEMOTION
      runcomponent!(ecs, :onmotion, event.motion)
    elseif ty ∈ [SDL_MOUSEBUTTONDOWN, SDL_MOUSEBUTTONUP]
      runcomponent!(ecs, :onbutton, event.button)
    elseif ty == SDL_MOUSEWHEEL
      runcomponent!(ecs, :onwheel, event.wheel)
    elseif ty == SDL_MULTIGESTURE
      runcomponent!(ecs, :onmgesture, event.mgesture)
    elseif ty == SDL_QUIT
      runcomponent!(ecs, :onquit, event.quit)
    elseif ty == SDL_SYSWMEVENT
      runcomponent!(ecs, :onsyswm, event.syswm)
    elseif ty == SDL_TEXTEDITING
      runcomponent!(ecs, :onedit, event.edit)
    elseif ty == SDL_TEXTINPUT
      runcomponent!(ecs, :ontext, event.text)
    elseif ty == SDL_USEREVENT
      runcomponent!(ecs, :onuser, event.user)
    elseif ty == SDL_WINDOWEVENT
      runcomponent!(ecs, :onwindow, event.window)
    else
      runcomponent!(ecs, :oncommon, event)
    end
  end
end