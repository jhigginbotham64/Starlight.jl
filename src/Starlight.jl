module Starlight

using Reexport
@reexport using Base: Semaphore, acquire, release, ReentrantLock, lock, unlock
@reexport using DataStructures: Queue, PriorityQueue, enqueue!, dequeue!
@reexport using DataFrames
@reexport using YAML
@reexport using SimpleDirectMediaLayer
@reexport using SimpleDirectMediaLayer.LibSDL2

export priority, handleMessage, sendMessage, listenFor, dispatchMessage
export System, App, awake!, shutdown!, system!, on, off, cat
export app

import DotEnv
cfg = DotEnv.config()

DEFAULT_PRIORITY = parse(Int, get(ENV, "DEFAULT_PRIORITY", "0"))
MQUEUE_SIZE = parse(Int, get(ENV, "MQUEUE_SIZE", "1000"))

const listeners = Dict{DataType, Set{Any}}()
const messages = PriorityQueue{Any, Int}()

const slot_available = Semaphore(MQUEUE_SIZE)
const msg_ready = Semaphore(MQUEUE_SIZE)
const mqueue_lock = Semaphore(1)
const entity_lock = Semaphore(1)
const listener_lock = Semaphore(1)

for i in 1:MQUEUE_SIZE
  acquire(msg_ready)
end

function priority(e)
  (hasproperty(e, :priority)) ? e.priority : DEFAULT_PRIORITY
end

handleMessage(l, m) = nothing

function sendMessage(m)
  # drop if no one's listening
  if haskey(listeners, typeof(m))
    acquire(slot_available)
    acquire(mqueue_lock)
    enqueue!(messages, m, priority(m))
    release(mqueue_lock)
    release(msg_ready)
  end
end

function listenFor(e::Any, d::DataType)
  acquire(listener_lock)
  if !haskey(listeners, d) listeners[d] = Set{Any}() end
  push!(listeners[d], e)
  release(listener_lock)
end

# TODO implement "unlisten" function and test

# uses single argument to support
# being called as a job by a Clock,
# see Clock.jl for that interface
function dispatchMessage(arg)
  acquire(msg_ready)
  acquire(mqueue_lock)
  m = dequeue!(messages)
  @debug "dequeued message"
  if haskey(listeners, typeof(m))
    for l in listeners[typeof(m)]
      @debug "calling handleMessage"
      handleMessage(l, m)
    end
  end
  release(mqueue_lock)
  release(slot_available)
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
include("SDL.jl")

mutable struct App <: System
  systems::Dict{DataType, System}
  running::Vector{Bool}
  function App(appf::String="")
    # singleton pattern from Tom Kwong's book
    global app
    global app_lock
    lock(app_lock)
    try 
      if !isassigned(app)

        a = new(Dict(), Vector{Bool}())
        
        system!(a, clk)
        system!(a, ecs)
        system!(a, sdl)
      
        a.running = [false for s in keys(a.systems)]

        app[] = finalizer(shutdown!, a)

      end

      # making this separate from instance initialization
      # means that sequential YAML file loads will merge
      # and/or overwrite results with each other on the global app
      if isfile(appf)
        yml = YAML.load_file(appf) # may support other file types in the future
        if haskey(yml, "clock") && yml["clock"] isa Dict
          clock = yml["clock"]
          if haskey(clock, "fire_sec") clk.fire_sec = clock["fire_sec"] end
          if haskey(clock, "fire_msec") clk.fire_msec = clock["fire_msec"] end
          if haskey(clock, "fire_usec") clk.fire_usec = clock["fire_usec"] end
          if haskey(clock, "fire_nsec") clk.fire_nsec = clock["fire_nsec"] end
          if haskey(clock, "freq") clk.freq = clock["freq"] end
        end
      end

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
  job!(a.systems[Clock], dispatchMessage)
  return a.running = map(awake!, values(a.systems))
end
shutdown!(a::App) = a.running = map(shutdown!, values(a.systems))

awake!() = awake!(app[])
shutdown!() = shutdown!(app[])

end