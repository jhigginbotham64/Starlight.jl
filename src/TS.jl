export TS
export to_ARGB, getSDLError, sdl_colors, vulkan_colors, clear

mutable struct TS end

function draw()
  TS_VkBeginDrawPass() # clears screen automatically

  map(draw, scn()) # TODO investigate parallelization

  TS_VkEndDrawPass(vulkan_colors(App().bgrd)...)
end

function handleMessage!(t::TS, m::TICK)
  Log.@debug "TS tick"
  try
    draw()
  catch
    handleException()
  end
end

"""
error, forwarded from SDL to Julia

# Fieds
message: message as string. If empty, signals that no error occurred
"""
mutable struct SDLError <: Exception
    message::String
end
Base.showerror()

"""
`hasSDLErrorOccurred() -> Bool`
"""
hasSDLErrorOccurred() = isempty(unsafe_string(TS_SDLGetError())) # TODO: is this correct?

"""
`forwardSDLError() -> Nothing`

forward potential SDL errors to the starlight error handler
"""
function forwardSDLError() ::Nothing

    if !hasSDLErrorOccurred()
        return
    end

    error_maybe = SDLError(unsafe_string(TS_SDLGetError()))
    try
        throw(error_maybe)
    catch
        handleException()
    end
    return nothing
end

to_ARGB(c) = c
to_ARGB(c::ARGB) = c
to_ARGB(c::Colorant) = ARGB(c)

sdl_colors(c::Colorant) = sdl_colors(convert(ARGB{Colors.FixedPointNumbers.Normed{UInt8,8}}, c))
sdl_colors(c::ARGB) = Int.(reinterpret.((red(c), green(c), blue(c), alpha(c))))

vulkan_colors(c::Colorant) = Cfloat.(sdl_colors(c) ./ 255)

clear() = fill(App().bgrd)

function Base.fill(c::Colorant)
  TS_VkCmdClearColorImage(vulkan_colors(c)...)
end

function awake!(t::TS)
  Log.@debug "TS awake!"
  TS_Init("Hello SDL!", App().wdth, App().hght)
  draw()
  listenFor(t, TICK)
end

function shutdown!(t::TS) 
  Log.@debug "TS shutdown!"
  unlistenFrom(t, TICK)
  TS_Quit()
end