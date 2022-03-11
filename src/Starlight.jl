module Starlight

using Reexport
@reexport using Base: ReentrantLock, lock, unlock
@reexport using FileIO: load
@reexport using Pkg.Artifacts
@reexport using LazyArtifacts
@reexport using DataStructures: Queue, enqueue!, dequeue!
@reexport using DataFrames
@reexport using Colors
@reexport using Telescope

export handleMessage, sendMessage, listenFor, unlistenFrom, handleException, dispatchMessage
export System, App, awake!, shutdown!, system!, on, off, cat
export app

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


include("Clock.jl")
include("ECS.jl")
include("Scene.jl")
include("Telescope.jl")
include("Entities.jl")
include("Audio.jl")

mutable struct App <: System
  systems::Dict{DataType, System}
  running::Vector{Bool}
  function App()
    # singleton pattern from Tom Kwong's book
    global app
    global app_lock
    lock(app_lock)
    try 
      if !isassigned(app)

        a = new(Dict(), Vector{Bool}())
        
        system!(a, clk)
        system!(a, ecs)
        system!(a, rnd)
        system!(a, scn)
      
        a.running = [false for s in keys(a.systems)]

        app[] = finalizer(shutdown!, a)

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

on(a::App) = all(a.running)
off(a::App) = all(!r for r in a.running)
# shrodinger's app is neither on nor off, 
# i.e. some system is not synchronized with the others
cat(a::App) = !on(a) && !off(a)

system!(a::App, s::System) = a.systems[typeof(s)] = s
# note that if running from a script the app will
# still exit when julia exits, it will never block.
# figuring out whether/how to keep it alive is
# on the user.
function awake!(a::App)
  if !on(a)
    job!(a.systems[Clock], dispatchMessage) # this could be parallelized if not for mqueue_lock
    a.running = map(awake!, values(a.systems))
  end
  return a.running
end
function shutdown!(a::App)
  if !off(a)
    a.running = map(shutdown!, values(a.systems))
  end
  return a.running
end

awake!() = awake!(app[])
shutdown!() = shutdown!(app[])

end