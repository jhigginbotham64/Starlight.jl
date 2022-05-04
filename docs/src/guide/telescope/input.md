# Input

Starlight's event bus makes designing an input system trivial. All that's required is a tick handler with some basic processing and users are free to define handlers for any event type supported by SDL. Understanding that `Input` is a subsystem that follows the same pattern as the others, its entire source code is almost exactly the following:

```julia
mutable struct Input end

function awake!(i::Input)
  listenFor(i, TICK)
end

function shutdown!(i::Input)
  unlistenFrom(i, TICK)
end

function handleMessage!(i::Input, m::TICK)
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
```

Note the direct use of the [SDL2 wrapper](https://github.com/JuliaMultimedia/SimpleDirectMediaLayer.jl). Starlight initializes SDL via Telescope, but if you want implement your own subsystems that use SDL directly or through a different wrapper or however, you're free to do so, Starlight's default input system will at least still work (although you will need to provide replacements for several structs and other subsystems).

You are encouraged to read SDL's documentation for [events](https://wiki.libsdl.org/SDL_Event) in order to understand how Starlight's input system works. Essentially, you `listenFor`/`unlistenFrom` and `handleMessage!` for SDL's event types as exposed through the wrapper, and Starlight will handle translating from the raw `SDL_Event` for you.

The Pong example code contains several input handlers that you can reference if things are still unclear.