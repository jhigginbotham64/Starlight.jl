export draw!
export to_ARGB, sdl_colors, vulkan_colors

to_ARGB(c) = c
to_ARGB(c::ARGB) = c
to_ARGB(c::Colorant) = ARGB(c)

sdl_colors(c::Colorant) = sdl_colors(convert(ARGB{Colors.FixedPointNumbers.Normed{UInt8,8}}, c))
sdl_colors(c::ARGB) = Int.(reinterpret.((red(c), green(c), blue(c), alpha(c))))

vulkan_colors(c::Colorant) = Cfloat.(sdl_colors(c) ./ 255)

function Base.fill(c::Colorant)
  TS_VkCmdClearColorImage(vulkan_colors(c)...)
end

function draw!(ecs::ECS)
  TS_VkBeginDrawPass()

  runcomponent!(ecs, :draw)

  TS_VkEndDrawPass(vulkan_colors(colorant"black")...)
end
