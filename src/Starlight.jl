"""
Main module for Starlight.jl - a greedy framework for greedy developers.

  # Reexports

  - Base: ReentrantLock, lock, unlock
  - FileIO: load
  - Pkg.Artifacts
  - LazyArtifacts
  - DataStructures: Queue, enqueue!, dequeue!
  - DataFrames
  - Colors
  - SimpleDirectMediaLayer
  - SimpleDirectMediaLayer.LibSDL2
  - Telescope
"""
module Starlight

using Reexport
@reexport using Base: ReentrantLock, lock, unlock
@reexport using FileIO: load
@reexport using Pkg.Artifacts
@reexport using LazyArtifacts
@reexport using DataStructures: Queue, enqueue!, dequeue!
@reexport using DataFrames
@reexport using Colors
@reexport using SimpleDirectMediaLayer
@reexport using SimpleDirectMediaLayer.LibSDL2
@reexport using Telescope

include("Logging.jl")

export handleMessage!, sendMessage, listenFor, unlistenFrom, handleException, dispatchMessage
export App, awake!, shutdown!, system!, run!, on, off
export clk, ecs, inp, ts, phys, scn
export listeners, messages, listener_lock
export systemAwakeOrder, systemShutdownOrder

"""
    const listeners = Dict{DataType, Set{Any}}()

Internal dictionary that pairs event types with their listeners.
"""
const listeners = Dict{DataType, Set{Any}}()

"""
    const messages = Channel(Inf)

Internal Channel used to hold messages.
"""
const messages = Channel(Inf)

"""
    const listener_lock = ReentrantLock()

Internal lock used to synchronize access to the listeners dictionary.
"""
const listener_lock = ReentrantLock()

"""
```julia
handleMessage!(l, m) = nothing
```

Invoked on listener l when message m is received.

Currently there are three ways this function can be invoked for a given listener and message:
  - automatically by the message dispatcher, when the listener has been registered with listenFor and the message is of the corresponding type
  - automatically by the Physics subsystem on two colliding objects with message type TS_CollisionEvent
  - manually by user code (discouraged)

By default does (literally) nothing, but methods can be added for any type combination.
"""
handleMessage!(l, m) = nothing

"""
```julia
function sendMessage(m)
  if haskey(listeners, typeof(m))
    put!(messages, m)
  end
end
```
Add a message to the message queue if the message's type has any listeners. Otherwise drop.

The preferred way to send events/messages in Starlight.
"""
function sendMessage(m)
  # drop if no one's listening
  if haskey(listeners, typeof(m))
    put!(messages, m)
  end
end

"""
```julia
function listenFor(e::Any, d::DataType)
  lock(listener_lock)
  if !haskey(listeners, d) listeners[d] = Set{Any}() end
  push!(listeners[d], e)
  unlock(listener_lock)
end
```

Add a listener e for messages of type d. l's handleMessage! method will be invoked when messages of type d are received.
"""
function listenFor(e::Any, d::DataType)
  lock(listener_lock)
  if !haskey(listeners, d) listeners[d] = Set{Any}() end
  push!(listeners[d], e)
  unlock(listener_lock)
end

"""
```julia
function unlistenFrom(e::Any, d::DataType)
  lock(listener_lock)
  if haskey(listeners, d) delete!(listeners[d], e) end
  unlock(listener_lock)
end
```
Stop listener e from receiving messages of type d.
"""
function unlistenFrom(e::Any, d::DataType)
  lock(listener_lock)
  if haskey(listeners, d) delete!(listeners[d], e) end
  unlock(listener_lock)
end

"""
`handleException() -> Nothing`

Print a stacktrace and exit safely.
"""
function handleException() ::Nothing

    exception_stack = current_exceptions(backtrace=true)
    if isempty(exception_stack)
        return
    end

    exception = first(first(exception_stack)) # sic

    # non-fatal exceptions go here, currently all exceptions are fatal
    non_fatal_exception_types = Type[]
    if typeof(exception) in non_fatal_exception_types
        Log.@warning "a non-fatal exception occurred: " * string(exception)
        return
    end

    Log.@error "an exception occurred: " * string(exception)
    Log.@error "aborting..."
    shutdown!(App())
    throw(exception_stack)
    return nothing
end

"""
```julia
function dispatchMessage(arg)
  try
    m = take!(messages) # NOTE messages are fully processed in the order they are received
    d = typeof(m)
    if haskey(listeners, d)
      # Threads.@threads doesn't work on raw sets
      # because it needs to use indexing to split
      # up memory, i work around it this way
      Threads.@threads for l in Vector([listeners[d]...])
        handleMessage!(l, m)
      end
    end
  catch
    handleException()
  end
end
```

Take a single message from the event queue and invoke handleMessage! for all listeners in parallel. 

If there are no listeners for the message type (i.e. they were removed after the message was sent), drop.

Normally runs in an infinite loop in a background Task started by awake!(::App).

!!! danger

    This function is called internally by Starlight and documented here
    for completeness. Do not invoke it yourself unless you know what you
    are doing.
"""
function dispatchMessage(arg)
  Log.@debug "dispatchMessage"
  try
    m = take!(messages) # NOTE messages are fully processed in the order they are received
    d = typeof(m)
    Log.@debug "dequeued message $(m) of type $(d)"
    if haskey(listeners, d)
      # Threads.@threads doesn't work on raw sets
      # because it needs to use indexing to split
      # up memory, i work around it this way
      Threads.@threads for l in Vector([listeners[d]...])
        handleMessage!(l, m)
      end
    end
  catch
    handleException()
  end
end

"""
```julia
awake!(a) = nothing
```

Arbitrary startup function.

By default does literally nothing, but methods can be added for any type.

The preferred way to call listenFor is from inside an awake! method.
"""
awake!(a) = nothing

"""
```julia
shutdown!(a) = nothing
```

Arbitrary shutdown function.

By default does literally nothing, but methods can be added for any type.

The preferred way to call unlistenFrom is from inside a shutdown! method.
"""
shutdown!(a) = nothing

include("Clock.jl")
include("ECS.jl")
include("TS.jl")
include("Entities.jl")
include("Input.jl")
include("Physics.jl")

"""
Struct for the "master App" singleton.

Constructor accepts keyword arguments for all fields except systems, and no positional arguments.

# Fields
  - systems::Dict{DataType, Any} Dictionary of subsystems by type
  - running::Bool Whether awake! has been called
  - wdth::Int Window width
  - hght::Int Window height
  - bgrd::Colorant Window default background color
"""
mutable struct App
  systems::Dict{DataType, Any}
  running::Bool
  wdth::Int
  hght::Int
  bgrd::Colorant
  function App(; wdth::Int=400, hght::Int=400, bgrd=colorant"grey")
    # singleton pattern from Tom Kwong's book
    global app
    global app_lock
    lock(app_lock)
    try 
      if !isassigned(app)
        a = new(Dict{DataType, Any}(), false, wdth, hght, bgrd)

        system!(a, Clock())
        system!(a, ECS())
        system!(a, Scene())
        system!(a, TS())
        system!(a, Input())
        system!(a, Physics())

        app[] = finalizer(shutdown!, a)

        # root pid is 0 (default) indicating "here and no further",
        # always needed, also it will technically parent of itself.
        # mutate at your own peril, but remember that a  user can 
        # define update!(r::Root, Δ::AbstractFloat) if they want
        instantiate!(Root())
      end

    catch e
      rethrow()
    finally
      unlock(app_lock)
      return app[]
    end
  end
end

const app = Ref{App}()
const app_lock = ReentrantLock()

# TODO: fix this, it feels hacky
"""
    clk() = App().systems[Clock]

Get the current Clock.
"""
clk() = App().systems[Clock]

"""
    scn() = App().systems[Scene]

Get the current Scene graph.
"""
scn() = App().systems[Scene]

"""
    ts() = App().systems[TS]

Get the current Telescope backend subsystem.
"""
ts() = App().systems[TS]

"""
    inp() = App().systems[Input]

Get the current Input manager.
"""
inp() = App().systems[Input]

"""
    ecs() = App().systems[ECS]

Get the current Entity Component System.
"""
ecs() = App().systems[ECS]

"""
    phys() = App().systems[Physics]

Get the current Physics manager.
"""
phys() = App().systems[Physics]

"""
    on(a::App) = a.running

Check whether awake! has been called.
"""
on(a::App) = a.running

"""
    off(a::App) = !a.running

Opposite of on.
"""
off(a::App) = !a.running

# TODO: fix this with an ordered dict or something

"""
```julia
systemAwakeOrder = () -> [clk(), ts(), inp(), phys(), ecs(), scn()]
```

The order in which App subsystems should be awoken in order to not produce bugs.
"""
systemAwakeOrder = () -> [clk(), ts(), inp(), phys(), ecs(), scn()]

"""
```julia
systemShutdownOrder = () -> [clk(), inp(), phys(), scn(), ecs(), ts()]
```

The order in which App subsystems should be shut down in order to not produce bugs.
"""
systemShutdownOrder = () -> [clk(), inp(), phys(), scn(), ecs(), ts()]

# TODO: need an elegant way to remove systems

"""
```julia
system!(a::App, s) = a.systems[typeof(s)] = s
```

Add something to an App's systems dictionary.
"""
system!(a::App, s) = a.systems[typeof(s)] = s

"""
```julia
function awake!(a::App)
  if !on(a)
    job!(clk(), dispatchMessage)
    map(awake!, systemAwakeOrder())
    a.running = true
  end
end
```

If not on, start the message dispatcher call awake! on all subsystems.

Note that if running from a script the app will still exit when Julia exits, it will never block. Figuring out whether/how to keep it alive is on the user. One method is to use run!, see below.
"""
function awake!(a::App)
  if !on(a)

    Log.init(Base.Filesystem.pwd() * "starlight.log") # log to file
    # Log.set_debug_enabled(true)

    job!(clk(), dispatchMessage) # this could be parallelized if not for mqueue_lock
    map(awake!, systemAwakeOrder())
    a.running = true
  end
end

"""
```julia
function shutdown!(a::App)
  if !off(a)
    map(shutdown!, systemShutdownOrder())
    a.running = false
  end
end
```

If not off, call shutdown! on all subsystems.
"""
function shutdown!(a::App)
  if !off(a)
    map(shutdown!, systemShutdownOrder())
    a.running = false
    Log.quit()
  end
end

"""
```julia
function run!(a::App)
  awake!(a)
  if !isinteractive()
    while on(a)
      yield()
    end
  end
end
```

Call awake! and keep alive until switched off.
"""
function run!(a::App)
  awake!(a)
  if !isinteractive()
    while on(a)
      yield()
    end
  end
end

end