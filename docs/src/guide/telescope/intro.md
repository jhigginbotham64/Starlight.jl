# Intro

Here's the motivation behind [Telescope](https://github.com/jhigginbotham64/Telescope): we wanted to use [Vulkan](https://www.vulkan.org/) for rendering, but couldn't find a good way to create a rendering context using Julia alone. Not even with the (fantastic) [SDL2 wrapper](https://github.com/JuliaMultimedia/SimpleDirectMediaLayer.jl) (which Starlight still uses for input events).

We also wanted to use the [Bullet Physics SDK](https://pybullet.org/wordpress/) for physics and especially collision detection, but...no Julia bindings have been created yet.

So we opted to kill two birds with one stone: create our own C++ library to wrap the C/C++ libraries we wanted to use, expose a simple procedural/imperative API through a C header, and create (i.e. generate using [Clang.jl](https://github.com/JuliaInterop/Clang.jl)) a [simple Julia wrapper](https://github.com/jhigginbotham64/Telescope.jl). Many [Yggdrasil pull requests](https://github.com/JuliaPackaging/Yggdrasil/pulls?q=is%3Apr+author%3Ajhigginbotham64+) later, Telescope was available as a backend for Starlight.

Starlight's TS subsystem simplifies Telescope's usage by handling initialization, deinitialization, and the frame-by-frame drawing context, but that's really it. Its only job is to make sure that the APIs exposed by the [wrapper](https://github.com/jhigginbotham64/Telescope.jl) function as-advertised.

The most important parts of the TS subsystem go something like this:

```julia
function awake!(t::TS)
  TS_Init("Hello SDL!", App().wdth, App().hght)
  draw()
  listenFor(t, TICK)
end

function shutdown!(t::TS) 
  unlistenFrom(t, TICK)
  TS_Quit()
end

draw(e) = nothing

function draw()
  TS_VkBeginDrawPass()

  map(draw, scn())

  TS_VkEndDrawPass(vulkan_colors(App().bgrd)...)
end

function handleMessage!(t::TS, m::TICK)
  draw()
end
```

...where `wdth` and `hght` are attributes added to the `App` struct to specify window dimensions and `scn()` refers to a special `ECSIterator` doubling as a new "scene graph" subsystem, which returns entities in reverse-z order (i.e. back to front) for drawing, and functions beginning with `TS_` are calls to Telescope's Julia bindings.

Next we'll cover how to create entities in such a way that they get drawn on the screen using Telescope, using an example taken (yet again) from Starlight's own source code.

!!! note

    We apologize that Telescope does not yet have documentation 
    available. There are plans to fix this in the near future. 
    Starlight's docs will be updated with relevant links to the 
    Telescope docs as soon as that is possible.