export Rendering, rnd
export to_ARGB, sdl_colors, vulkan_colors, clear, clrclr


mutable struct Rendering <: System end

const rnd = Rendering()

clrclr = colorant"grey" # "clear color"

function draw()
  TS_VkBeginDrawPass()

  map(draw, scn) # TODO investigate parallelization

  TS_VkEndDrawPass(vulkan_colors(clrclr)...)
end

function handleMessage(t::Rendering, m::TICK)
  @debug "Rendering tick"
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

sdl_colors(c::Colorant) = sdl_colors(convert(ARGB{Colors.FixedPointNumbers.Normed{UInt8,8}}, c))
sdl_colors(c::ARGB) = Int.(reinterpret.((red(c), green(c), blue(c), alpha(c))))

vulkan_colors(c::Colorant) = Float32.(sdl_colors(c) ./ 255)

clear(c::Colorant=clrclr) = fill(c)

function Base.fill(c::Colorant)
  TS_VkCmdClearColorImage(vulkan_colors(c)...)
end

function awake!(t::Rendering)
  TS_Init("Hello SDL!", 400, 400)
  draw()
  listenFor(rnd, TICK)
  return true
end

function shutdown!(t::Rendering)  
  unlistenFrom(rnd, TICK)
  TS_Quit()
  return false
end