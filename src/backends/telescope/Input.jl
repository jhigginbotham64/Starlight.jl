export TS_Input!

function TS_Input!(ecs::Guard{ECS})
  while true
    events = []
    event_ref = Ref{SDL_Event}()
    while Bool(SDL_PollEvent(event_ref))
      push!(events, event_ref[])
    end
  
    Threads.@threads for event ∈ events
      t = event.type
      if t ∈ [SDL_AUDIODEVICEADDED, SDL_AUDIODEVICEREMOVED]
        @grd runcomponent!(ecs, :onadevice, event.adevice)
      elseif t == SDL_CONTROLLERAXISMOTION
        @grd runcomponent!(ecs, :oncaxis, event.caxis)
      elseif t ∈ [SDL_CONTROLLERBUTTONDOWN, SDL_CONTROLLERBUTTONUP]
        @grd runcomponent!(ecs, :oncbutton, event.cbutton)
      elseif t ∈ [SDL_CONTROLLERDEVICEADDED, SDL_CONTROLLERDEVICEREMOVED, SDL_CONTROLLERDEVICEREMAPPED]
        @grd runcomponent!(ecs, :oncdevice, event.cdevice)
      elseif t ∈ [SDL_DOLLARGESTURE, SDL_DOLLARRECORD]
        @grd runcomponent!(ecs, :ondgesture, event.dgesture)
      elseif t ∈ [SDL_DROPFILE, SDL_DROPTEXT, SDL_DROPBEGIN, SDL_DROPCOMPLETE]
        @grd runcomponent!(ecs, :ondrop, event.drop)
      elseif t ∈ [SDL_FINGERMOTION, SDL_FINGERDOWN, SDL_FINGERUP]
        @grd runcomponent!(ecs, :ontfinger, event.tfinger)
      elseif t ∈ [SDL_KEYDOWN, SDL_KEYUP]
        @grd runcomponent!(ecs, :onkey, event.key)
      elseif t == SDL_JOYAXISMOTION
        @grd runcomponent!(ecs, :onjaxis, event.jaxis)
      elseif t == SDL_JOYBALLMOTION
        @grd runcomponent!(ecs, :onjball, event.jball)
      elseif t == SDL_JOYHATMOTION
        @grd runcomponent!(ecs, :onjhat, event.jhat)
      elseif t ∈ [SDL_JOYBUTTONDOWN, SDL_JOYBUTTONUP]
        @grd runcomponent!(ecs, :onjbutton, event.jbutton)
      elseif t ∈ [SDL_JOYDEVICEADDED, SDL_JOYDEVICEREMOVED]
        @grd runcomponent!(ecs, :onjdevice, event.jdevice)
      elseif t == SDL_MOUSEMOTION
        @grd runcomponent!(ecs, :onmotion, event.motion)
      elseif t ∈ [SDL_MOUSEBUTTONDOWN, SDL_MOUSEBUTTONUP]
        @grd runcomponent!(ecs, :onbutton, event.button)
      elseif t == SDL_MOUSEWHEEL
        @grd runcomponent!(ecs, :onwheel, event.wheel)
      elseif t == SDL_MULTIGESTURE
        @grd runcomponent!(ecs, :onmgesture, event.mgesture)
      elseif t == SDL_QUIT
        @grd runcomponent!(ecs, :onquit, event.quit)
      elseif t == SDL_SYSWMEVENT
        @grd runcomponent!(ecs, :onsyswm, event.syswm)
      elseif t == SDL_TEXTEDITING
        @grd runcomponent!(ecs, :onedit, event.edit)
      elseif t == SDL_TEXTINPUT
        @grd runcomponent!(ecs, :ontext, event.text)
      elseif t == SDL_USEREVENT
        @grd runcomponent!(ecs, :onuser, event.user)
      elseif t == SDL_WINDOWEVENT
        @grd runcomponent!(ecs, :onwindow, event.window)
      else
        @grd runcomponent!(ecs, :oncommon, event)
      end
    end
  end
end
  