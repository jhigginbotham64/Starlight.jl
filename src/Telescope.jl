export Telescope, ts
export to_ARGB, sdl_colors, clear
export TS_DrawPoint, TS_DrawRect, TS_DrawText, TS_Fill, TS_Init, TS_Present
export TS_DrawLine, TS_DrawSprite, TS_GetSDLError, TS_PlaySound, TS_Quit

# TODO use artifacts or some other solution
# with better portability than @__DIR__
@wrapmodule(joinpath(@__DIR__, "build", "lib", "libtelescope.so"))
function __init__()
  @initcxx
end

mutable struct Telescope <: System end

const ts = Telescope()

listenFor(ts, TICK)

function draw()
  clear()
  map(draw, scn) # TODO investigate parallelization
  TS_Present()
end

function handleMessage(t::Telescope, m::TICK)
  @debug "Telescope tick"
  try
    # TODO CPP events

    draw()
  catch
    handleException()
  end

end

to_ARGB(c) = c
to_ARGB(c::ARGB) = c
to_ARGB(c::Colorant) = ARGB(c)

clear() = fill(colorant"gray")

sdl_colors(c::Colorant) = sdl_colors(convert(ARGB{Colors.FixedPointNumbers.Normed{UInt8,8}}, c))
sdl_colors(c::ARGB) = Int.(reinterpret.((red(c), green(c), blue(c), alpha(c))))

function Base.fill(c::Colorant)
  TS_Fill(sdl_colors(c)...)
end

function awake!(t::Telescope)
  TS_Init("Hello SDL!", 400, 400)
  draw()
  return true
end

function shutdown!(t::Telescope)  
  TS_Quit()
  return false
end