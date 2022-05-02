# Getting Started

Starlight aims to offload as much work as possible onto the underlying libraries while still giving you, the developer, fine-grained control over your application's behavior: it provides useful abstraction, but gets out of the way when you need it to. The reason it can do this is its microkernel architecture, which models all subsystems as running independently of each other while exchanging data through a message bus. What exactly this means and how it works will be explained shortly. To give you an idea what to expect, let's review some content from the README. 

To get started with Starlight, first add it to your project:

```julia-repl
julia> ] add Starlight
```

You can then declare that you are

```julia-repl
julia> using Starlight
```

From there, in order to initialize the various subsystems, you must create an `App`:

```julia-repl
julia> a = App()
```

To kick everything off and open a window, you can call

```julia-repl
julia> awake!(a)
```

To shut everything down, you (fittingly) call

```julia-repl
julia> shutdown!(a)
```

Starlight scripts should use `run!` instead of `awake!` to keep the Julia process alive. A minimal Starlight script could look something like the following:

```julia
using Starlight

a = App()

run!(a)
```

Doing that in a shell session with debug output enabled gives you an idea of just how much is going on behind the blank window that gets created:

```
jhigginbotham64:Starlight (main) $ JULIA_DEBUG=Starlight julia -e 'using Starlight; a = App(); run!(a)'
┌ Debug: Clock awake!
└ @ Starlight ~/.julia/dev/Starlight/src/Clock.jl:66
┌ Debug: TS awake!
└ @ Starlight ~/.julia/dev/Starlight/src/TS.jl:41
┌ Debug: dispatchMessage
└ @ Starlight ~/.julia/dev/Starlight/src/Starlight.jl:57
┌ Debug: Input awake!
└ @ Starlight ~/.julia/dev/Starlight/src/Input.jl:64
┌ Debug: tick
└ @ Starlight ~/.julia/dev/Starlight/src/Clock.jl:44
┌ Debug: Physics awake!
└ @ Starlight ~/.julia/dev/Starlight/src/Physics.jl:64
┌ Debug: dequeued message TICK(1.99813325) of type TICK
└ @ Starlight ~/.julia/dev/Starlight/src/Starlight.jl:61
┌ Debug: ECS awake!
└ @ Starlight ~/.julia/dev/Starlight/src/ECS.jl:198
┌ Debug: tick
└ @ Starlight ~/.julia/dev/Starlight/src/Clock.jl:44
┌ Debug: Scene awake!
└ @ Starlight ~/.julia/dev/Starlight/src/ECS.jl:289
┌ Debug: TS tick
└ @ Starlight ~/.julia/dev/Starlight/src/TS.jl:15
┌ Debug: Input tick
└ @ Starlight ~/.julia/dev/Starlight/src/Input.jl:6
┌ Debug: tick
└ @ Starlight ~/.julia/dev/Starlight/src/Clock.jl:44
┌ Debug: Physics tick
└ @ Starlight ~/.julia/dev/Starlight/src/Physics.jl:45
┌ Debug: dispatchMessage
└ @ Starlight ~/.julia/dev/Starlight/src/Starlight.jl:57
┌ Debug: dequeued message TICK(0.191819018) of type TICK
└ @ Starlight ~/.julia/dev/Starlight/src/Starlight.jl:61
```

There are several things to notice here. First and most importantly is that all subsystems (including the clock) communicate using the same event bus (you'll soon see that they even define methods for the same functions). Second is that pretty much nothing happens until `awake!` is called on the `App`. Finally, there is a clock synchronizing everything. 

We're going to dwell on each of these points in turn before diving into the more specialized individual subsystems.