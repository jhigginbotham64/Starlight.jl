export SDL, sdl
export getSDLError
export to_ARGB, sdl_colors, clear

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

function draw()
  clear()
  map(draw, scn) # TODO investigate parallelization
  # CPP present
end

function handleMessage(s::SDL, m::TICK)
  @debug "SDL tick"
  try
    # TODO CPP events

    # draw the scene
    draw()
  catch
    handleException()
  end

end

to_ARGB(c) = c
to_ARGB(c::ARGB) = c
to_ARGB(c::Colorant) = ARGB(c)

clear() = fill(sdl.bgrd)

sdl_colors(c::Colorant) = sdl_colors(convert(ARGB{Colors.FixedPointNumbers.Normed{UInt8,8}}, c))
sdl_colors(c::ARGB) = Int.(reinterpret.((red(c), green(c), blue(c), alpha(c))))

# CPP fill (color)
function Base.fill(c::Colorant)
  
end

# CPP init
function awake!(s::SDL)

  draw()

  return true
end

# CPP quit
function shutdown!(s::SDL)  

  return false
end