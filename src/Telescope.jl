export Telescope, ts
export to_ARGB, sdl_colors, vulkan_colors, clear, clrclr

# TODO use artifacts or some other solution
# with better portability than @__DIR__
@wrapmodule(joinpath(@__DIR__, "build", "lib", "libtelescope.so"))
function __init__()
  @initcxx
end

mutable struct Telescope <: System end

const ts = Telescope()

clrclr = colorant"grey" # "clear color"

function draw()
  TS_VkAcquireNextImage()
  TS_VkResetCommandBuffer()
  TS_VkBeginCommandBuffer()
  TS_VkBeginRenderPass(vulkan_colors(clrclr)...)

  map(draw, scn) # TODO investigate parallelization

  TS_VkEndRenderPass()
  TS_VkEndCommandBuffer()
  TS_VkQueueSubmit()
  TS_VkQueuePresent()
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

sdl_colors(c::Colorant) = sdl_colors(convert(ARGB{Colors.FixedPointNumbers.Normed{UInt8,8}}, c))
sdl_colors(c::ARGB) = Int.(reinterpret.((red(c), green(c), blue(c), alpha(c))))

vulkan_colors(c::Colorant) = Float32.(sdl_colors(c) ./ 255)

clear(c::Colorant=clrclr) = fill(c)

function Base.fill(c::Colorant)
  TS_VkCmdClearColorImage(vulkan_colors(c)...)
end

function awake!(t::Telescope)
  TS_Init("Hello SDL!", 400, 400)
  draw()
  listenFor(ts, TICK)
  return true
end

function shutdown!(t::Telescope)  
  unlistenFrom(ts, TICK)
  TS_Quit()
  return false
end