# Starlight.jl

Julia is a [greedy language](https://julialang.org/blog/2012/02/why-we-created-julia/), surrounded by a community of greedy people, who deserve greedy frameworks to make their greedy applications.

With a focus on flexibility and code quality, Starlight aims to be such a framework. It includes a suite of components and integrations that make it particuarly well-suited for video games, so it is not a stretch to call it a "game engine". However, Starlight is most fundamentally a scripting layer for [SDL](http://www.libsdl.org/), [Vulkan](https://www.vulkan.org/), and [Bullet](https://pybullet.org/wordpress/) (via the [Telescope](https://github.com/jhigginbotham64/Telescope) backend), meaning it can be used for any application that needs high-performance rendering and physics. Furthermore, there are plans to allow selective enabling of different subsystems, meaning it could be used for GUI apps or pure physics simulation or anything else you can imagine.

### Installation

In your Julia environment, you can simply

```julia-repl
julia> ] add Starlight
```

### Basic Usage

Starlight projects are simply Julia projects, no special structure or anything, so you simply declare that you are

```julia
julia> using Starlight
```

To take advantage of the magic of Starlight you must first create an App:

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

Before you try doing anything interesting with the library, it is recommended that you read the docs.

### Contributing

We welcome issues, pull requests, everything. If there's a feature or use case we don't support and you don't have time to implement it yourself, create an issue. If you do have time, create a pull request. There's a ton of work to be done and only one active contributor. Anything you have to offer will be appreciated. Authors of pull requests will also get a special mention and a description of the work they did further down here in the README.

The maintainer is willing to personally mentor anyone who wants to either contribute or to learn Starlight for their own use cases. Contact information below. Please reach out.

#### Bounties

Some issues may have monetary rewards attached to them. Pull requests addressing these issues will be scrutinized more thoroughly than others. Get in touch with the maintainer to discuss payment arrangements. 

##### No advance payments will be made under any circumstances

### Contact

You are invited to join us on [Discord](https://discord.gg/jUwaymK2as).

The maintainer is also reachable by [email](mailto:jhigginbotham64@gmail.com) and typically answers within 24 hours.