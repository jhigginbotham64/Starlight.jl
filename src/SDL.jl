export SDL, sdl
export AudioDeviceEvent
export ControllerAxisEvent
export ControllerButtonEvent
export ControllerDeviceEvent
export DollarGestureEvent
export DropEvent
export TouchFingerEvent
export KeyBoardEvent
export JoyAxisEvent
export JoyBallEvent
export JoyHatEvent
export JoyButtonEvent
export JoyDeviceEvent
export MouseMotionEvent
export MouseButtonEvent
export MouseWheelEvent
export MultiGestureEvent
export QuitEvent
export SysWMEvent
export TextEditingEvent
export TextInputEvent
export UserEvent
export WindowEvent
export CommonEvent
export AUDIODEVICEADDED
export AUDIODEVICEREMOVED
export CONTROLLERAXISMOTION
export CONTROLLERBUTTONDOWN
export CONTROLLERBUTTONUP
export CONTROLLERDEVICEADDED
export CONTROLLERDEVICEREMOVED
export CONTROLLERDEVICEREMAPPED
export DOLLARGESTURE
export DOLLARRECORD
export DROPFILE
export DROPTEXT
export DROPBEGIN
export DROPCOMPLETE
export FINGERMOTION
export FINGERDOWN
export FINGERUP
export KEYDOWN
export KEYUP
export JOYAXISMOTION
export JOYBALLMOTION
export JOYHATMOTION
export JOYBUTTONDOWN
export JOYBUTTONUP
export JOYDEVICEADDED
export JOYDEVICEREMOVED
export MOUSEMOTION
export MOUSEBUTTONDOWN
export MOUSEBUTTONUP
export MOUSEWHEEL
export MULTIGESTURE
export QUIT
export SYSWMEVENT
export TEXTEDITING
export TEXTINPUT
export USEREVENT
export WINDOWEVENT

mutable struct SDL <: Starlight.System
  function SDL()
    # populate fields from config (make sure to add them to definition first)
    return new()
  end
end

const sdl = SDL()

listenFor(sdl, Starlight.TICK)

# aliases for SDL event stuff
const AudioDeviceEvent = SDL_AudioDeviceEvent
const ControllerAxisEvent = SDL_ControllerAxisEvent
const ControllerButtonEvent = SDL_ControllerButtonEvent
const ControllerDeviceEvent = SDL_ControllerDeviceEvent
const DollarGestureEvent = SDL_DollarGestureEvent
const DropEvent = SDL_DropEvent
const TouchFingerEvent = SDL_TouchFingerEvent
const KeyBoardEvent = SDL_KeyboardEvent
const JoyAxisEvent = SDL_JoyAxisEvent
const JoyBallEvent = SDL_JoyBallEvent
const JoyHatEvent = SDL_JoyHatEvent
const JoyButtonEvent = SDL_JoyButtonEvent
const JoyDeviceEvent = SDL_JoyDeviceEvent
const MouseMotionEvent = SDL_MouseMotionEvent
const MouseButtonEvent = SDL_MouseButtonEvent
const MouseWheelEvent = SDL_MouseWheelEvent
const MultiGestureEvent = SDL_MultiGestureEvent
const QuitEvent = SDL_QuitEvent
const SysWMEvent = SDL_SysWMEvent
const TextEditingEvent = SDL_TextEditingEvent
const TextInputEvent = SDL_TextInputEvent
const UserEvent = SDL_UserEvent
const WindowEvent = SDL_WindowEvent
const CommonEvent = SDL_CommonEvent
const AUDIODEVICEADDED = SDL_AUDIODEVICEADDED
const AUDIODEVICEREMOVED = SDL_AUDIODEVICEREMOVED
const CONTROLLERAXISMOTION = SDL_CONTROLLERAXISMOTION
const CONTROLLERBUTTONDOWN = SDL_CONTROLLERBUTTONDOWN
const CONTROLLERBUTTONUP = SDL_CONTROLLERBUTTONUP
const CONTROLLERDEVICEADDED = SDL_CONTROLLERDEVICEADDED
const CONTROLLERDEVICEREMOVED = SDL_CONTROLLERDEVICEREMOVED
const CONTROLLERDEVICEREMAPPED = SDL_CONTROLLERDEVICEREMAPPED
const DOLLARGESTURE = SDL_DOLLARGESTURE
const DOLLARRECORD = SDL_DOLLARRECORD
const DROPFILE = SDL_DROPFILE
const DROPTEXT = SDL_DROPTEXT
const DROPBEGIN = SDL_DROPBEGIN
const DROPCOMPLETE = SDL_DROPCOMPLETE
const FINGERMOTION = SDL_FINGERMOTION
const FINGERDOWN = SDL_FINGERDOWN
const FINGERUP = SDL_FINGERUP
const KEYDOWN = SDL_KEYDOWN
const KEYUP = SDL_KEYUP
const JOYAXISMOTION = SDL_JOYAXISMOTION
const JOYBALLMOTION = SDL_JOYBALLMOTION
const JOYHATMOTION = SDL_JOYHATMOTION
const JOYBUTTONDOWN = SDL_JOYBUTTONDOWN
const JOYBUTTONUP = SDL_JOYBUTTONUP
const JOYDEVICEADDED = SDL_JOYDEVICEADDED
const JOYDEVICEREMOVED = SDL_JOYDEVICEREMOVED
const MOUSEMOTION = SDL_MOUSEMOTION
const MOUSEBUTTONDOWN = SDL_MOUSEBUTTONDOWN
const MOUSEBUTTONUP = SDL_MOUSEBUTTONUP
const MOUSEWHEEL = SDL_MOUSEWHEEL
const MULTIGESTURE = SDL_MULTIGESTURE
const QUIT = SDL_QUIT
const SYSWMEVENT = SDL_SYSWMEVENT
const TEXTEDITING = SDL_TEXTEDITING
const TEXTINPUT = SDL_TEXTINPUT
const USEREVENT = SDL_USEREVENT
const WINDOWEVENT = SDL_WINDOWEVENT

function handleMessage(s::SDL, m::Starlight.TICK)
  @debug "SDL tick"
  try
    event_ref = Ref{SDL_Event}()
    while Bool(SDL_PollEvent(event_ref))
      evt = event_ref[]
      @debug "SDL sending message $(evt)"
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

function awake(s::SDL)
  SDL_GL_SetAttribute(SDL_GL_MULTISAMPLEBUFFERS, 4)
  SDL_GL_SetAttribute(SDL_GL_MULTISAMPLESAMPLES, 4)
  r = SDL_Init(UInt32(SDL_INIT_VIDEO | SDL_INIT_JOYSTICK | SDL_INIT_HAPTIC | SDL_INIT_GAMECONTROLLER | SDL_INIT_EVENTS))
  if r != 0
    error("unable to initialize SDL: $(getSDLError())")
  end

  TTF_Init()

  return true
end

function shutdown(s::SDL)  
  TTF_Quit()
  SDL_Quit()

  return false
end