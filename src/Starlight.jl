module Starlight

using Reexport
@reexport using Base: Semaphore, acquire, release
@reexport using DataStructures: Queue, PriorityQueue, enqueue!, dequeue!
@reexport using DataFrames
@reexport using YAML
@reexport using SimpleDirectMediaLayer
@reexport using SimpleDirectMediaLayer.LibSDL2

export priority, handleMessage, sendMessage, listenFor, dispatchMessage
export System, Message, App, awake, shutdown, system!, on, off, cat

import DotEnv
cfg = DotEnv.config()

DEFAULT_PRIORITY = parse(Int, get(ENV, "DEFAULT_PRIORITY", "0"))
MQUEUE_SIZE = parse(Int, get(ENV, "MQUEUE_SIZE", "1000"))

listeners = Dict{DataType, Vector{Any}}()
messages = PriorityQueue{Any, Int}()

slot_available = Semaphore(MQUEUE_SIZE)
msg_ready = Semaphore(MQUEUE_SIZE)
mqueue_lock = Semaphore(1)
entity_lock = Semaphore(1)
listener_lock = Semaphore(1)

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
  if !haskey(listeners, d) listeners[d] = Vector{Any}() end
  push!(listeners[d], e)
  release(listener_lock)
end

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
abstract type Message end

# these functions are supposed to return
# whether a value indicating whether the 
# system is still running or not, except
# for App where it returns a vector of
# booleans indicating whether each system
# is still running
awake(s::System) = true
shutdown(s::System) = false

include("Clock.jl")
include("ECS.jl")
include("SDL.jl")
include("Input.jl")
include("Audio.jl")
include("AI.jl")
include("Rendering.jl")
include("Physics.jl")

mutable struct App <: System
  systems::Dict{DataType, System}
  running::Vector{Bool}
  function App(appf::String="")
    a = new(Dict(), Vector{Bool}())
    c = Clock()
    system!(a, c)
    system!(a, ecs)
    system!(a, sdl)
  
    if isfile(appf)
      yml = YAML.load_file(appf) # may support other file types in the future
      if haskey(yml, "clock") && yml["clock"] isa Dict
        clk = yml["clock"]
        if haskey(clk, "fire_sec") c.fire_sec = clk["fire_sec"] end
        if haskey(clk, "fire_msec") c.fire_msec = clk["fire_msec"] end
        if haskey(clk, "fire_usec") c.fire_usec = clk["fire_usec"] end
        if haskey(clk, "fire_nsec") c.fire_nsec = clk["fire_nsec"] end
        if haskey(clk, "freq") c.freq = clk["freq"] end
      end
    end
  
    a.running = [false for s in keys(a.systems)]

    return finalizer(shutdown, a)
  end
end

on(a::App) = all(a.running)
off(a::App) = all(!r for r in a.running)
# shrodinger's app is neither on nor off, 
# i.e. some system is not synchronized with the others
cat(a::App) = !is_on(a) && !is_off(a)

system!(a::App, s::System) = a.systems[typeof(s)] = s
# note that if running from a script the app will
# still exit when julia exits, it will never block.
# figuring out whether/how to keep it alive is
# on the user.
function awake(a::App) 
  job!(a.systems[Clock], dispatchMessage)
  return a.running = map(awake, values(a.systems))
end
shutdown(a::App) = a.running = map(shutdown, values(a.systems))

end