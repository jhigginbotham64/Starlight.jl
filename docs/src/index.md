# Starlight.jl

Welcome to the documentation for Starlight.jl, a greedy application framework for [greedy developers](https://julialang.org/blog/2012/02/why-we-created-julia/). Its primary use case is video games, but the power of Julia, [SDL2](http://www.libsdl.org/), [Vulkan](https://www.vulkan.org/), and the [Bullet Physics SDK](https://pybullet.org/wordpress/) can be leveraged to make just about anything you want.

Features of Starlight's "core" include:

- Coroutines
- Event handling
- App lifecycle management
- [DataFrames](https://dataframes.juliadata.org/stable/)-based entity component system

Features of the default backend, [Telescope](https://github.com/jhigginbotham64/Telescope), include:

- [SDL2](http://www.libsdl.org/) integration for windowing, audio, fonts, input, and networking
- [Vulkan](https://www.vulkan.org/) rendering
- [Bullet Physics SDK](https://pybullet.org/wordpress/) integration

## Guide

### Walkthrough

```@contents
Pages = [
  "guide/walkthrough/intro.md",
  "guide/walkthrough/getting-started.md",
  "guide/walkthrough/app-lifecycle.md",
  "guide/walkthrough/message-passing.md",
  "guide/walkthrough/clock.md",
  "guide/walkthrough/ecs.md"
]
```

### Telescope

```@contents
Pages = [
  "guide/telescope/intro.md",
  "guide/telescope/rendering.md",
  "guide/telescope/input.md",
  "guide/telescope/physics.md"
]
```

## Examples

```@contents
Pages = [
  "examples/pong.md"
]
```

## API

```@contents
Pages = [
  "api.md"
]
Depth = 3
```