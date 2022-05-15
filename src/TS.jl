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

getSDLError() = unsafe_string(TS_SDLGetError())

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