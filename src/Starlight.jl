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

export handleMessage, sendMessage, listenFor, unlistenFrom, handleException, dispatchMessage
export System, App, awake!, shutdown!, run!, system!, on, off
export app, clk, ecs, inp, ts, phys, scn

const listeners = Dict{DataType, Set{Any}}()
const messages = Channel(Inf)

const listener_lock = ReentrantLock()

handleMessage(l, m) = nothing

function sendMessage(m)
  # drop if no one's listening
  if haskey(listeners, typeof(m))
    put!(messages, m)
  end
end

function listenFor(e::Any, d::DataType)
  lock(listener_lock)
  if !haskey(listeners, d) listeners[d] = Set{Any}() end
  push!(listeners[d], e)
  unlock(listener_lock)
end

function unlistenFrom(e::Any, d::DataType)
  lock(listener_lock)
  if haskey(listeners, d) delete!(listeners[d], e) end
  unlock(listener_lock)
end

function handleException()
  for s in stacktrace(catch_backtrace())
    println(s)
  end
  rethrow()
end

# uses single argument to support
# being called as a job by a Clock,
# see Clock.jl for that interface
function dispatchMessage(arg)
  try
    m = take!(messages) # NOTE messages are fully processed in the order they are received
    d = typeof(m)
    @debug "dequeued message $(m) of type $(d)"
    if haskey(listeners, d)
      # Threads.@threads doesn't work on raw sets
      # because it needs to use indexing to split
      # up memory, i work around it this way
      Threads.@threads for l in Vector([listeners[d]...])
        handleMessage(l, m)
      end
    end
  catch
    handleException()
  end
end

abstract type System end

# these functions are supposed to return
# whether a value indicating whether the 
# system is still running or not, except
# for App where it returns a vector of
# booleans indicating whether each system
# is still running
awake!(s::System) = true
shutdown!(s::System) = false

# order is determined by which systems
# need to be awakened before which
include("Clock.jl")
include("ECS.jl")
include("Telescope.jl")
include("Entities.jl")
include("Audio.jl")
include("Input.jl")
include("Physics.jl")

mutable struct App <: System
  systems::Dict{DataType, System}
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
        a = new(Dict{DataType, System}(), false, wdth, hght, bgrd)

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
        # define update!(r::Root, Δ) if they want
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

clk() = app[].systems[Clock]
scn() = app[].systems[Scene]
ts() = app[].systems[TS]
inp() = app[].systems[Input]
ecs() = app[].systems[ECS]
phys() = app[].systems[Physics]

on(a::App) = a.running
off(a::App) = !a.running

system!(a::App, s::System) = a.systems[typeof(s)] = s
# note that if running from a script the app will
# still exit when julia exits, it will never block.
# figuring out whether/how to keep it alive is
# on the user. see run! below for one method.
function awake!(a::App)
  if !on(a)
    job!(a.systems[Clock], dispatchMessage) # this could be parallelized if not for mqueue_lock
    map(awake!, values(a.systems))
    a.running = true
  end
end

function shutdown!(a::App)
  if !off(a)
    map(shutdown!, values(a.systems))
    a.running = false
  end
  return a.running
end

function run!(a::App)
  listenFor(a, SDL_QuitEvent)
  awake!(a)
  if !isinteractive()
    while on(a)
      yield()
    end
  end
end

function handleMessage(a::App, q::SDL_QuitEvent)
  shutdown!(a)
end

end