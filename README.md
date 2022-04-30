# Starlight.jl

Julia is a [greedy language](https://julialang.org/blog/2012/02/why-we-created-julia/), surrounded by a community of greedy people, who deserve greedy frameworks to make their greedy applications.

With a focus on flexibility and code quality, Starlight aims to be such a framework. It includes a suite of components and integrations that make it particuarly well-suited for video games, so it is not a stretch to call it a "game engine". However, Starlight is most fundamentally a scripting layer for [SDL](http://www.libsdl.org/), [Vulkan](https://www.vulkan.org/), and [Bullet](https://pybullet.org/wordpress/) (via the [Telescope](https://github.com/jhigginbotham64/Telescope) backend), meaning it can be used for any application that needs high-performance rendering and physics. Furthermore, there are plans to allow selective enabling of different subsystems, meaning it could be used for GUI apps or pure physics simulation or anything else you can imagine.

### Installation

In your Julia environment, you can simply

```julia
julia> ] add Starlight
```

### Basic Usage

Starlight projects are simply Julia projects, no special structure or anything, so you simply declare that you are

```julia
julia> using Starlight
```

Before you write any code that hooks into the library, you must create an App:

```julia
julia> a = App()
```

This gets you an internal clock, message bus, entity component system, rendering, physics, input, and sound, although it doesn't do anything with them yet. To open a window and start running the initialized subsystems, you can call

```julia
julia> awake!(a)
```

To close everything down, call

```julia
julia> shutdown!(a)
```

If running in a script you will need to keep the Julia process alive, so instead of `awake!(a)` you can use

```julia
julia> run!(a)
```

...which, as shown, works in the REPL as well.

Before you try doing anything interesting with the library, it is recommended that you read the docs (coming soon!).

### Contact

You are invited to join us on [Discord](https://discord.gg/jUwaymK2as).

