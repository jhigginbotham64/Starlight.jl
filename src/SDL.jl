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
  
end

function awake(s::SDL)

  return true
end

function shutdown(s::SDL)

  return false
end