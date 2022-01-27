module Starlight

using Reexport
@reexport using Base: Semaphore, acquire, release
@reexport using DataStructures: Queue, PriorityQueue
@reexport using DataFrames
@reexport using YAML
@reexport using SimpleDirectMediaLayer
@reexport using SimpleDirectMediaLayer.LibSDL2

SDL = SimpleDirectMediaLayer
export SDL
export priority, handleMessage, sendMessage, listenFor, dispatchMessages
export System, App, awake, shutdown, system!
export Event, Entity

import DotEnv
cfg = DotEnv.config()

DEFAULT_PRIORITY = parse(Int, get(ENV, "DEFAULT_PRIORITY", 0))
MQUEUE_SIZE = parse(Int, get(ENV, "MQUEUE_SIZE", 1000))

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

function handleMessage(l, m)
  nothing
end

function sendMessage(m)
  acquire(slot_available)
  acquire(mqueue_lock)
  enqueue!(messages, m, priority(m))
  release(mqueue_lock)
  release(msg_ready)
end

function listenFor(e::Any, d::DataType)
  acquire(listener_lock)
  if !haskey(listeners, d) listeners[d] = Vector{Any}() end
  push!(listeners[d], e)
  release(listener_lock)
end

function dispatchMessage(arg)
  acquire(msg_ready)
  acquire(mqueue_lock)
  m = dequeue_pair!(messages)
  @debug "dequeued message"
  if haskey(listeners, typeof(m))
    for l in listeners[typeof(m)]
      handleMessage(l, m)
    end
  end
  release(mqueue_lock)
  release(slot_available)
end

abstract type System end
abstract type Event end

awake(s::System) = nothing
shutdown(s::System) = nothing

include("Clock.jl")
include("ECS.jl")
include("Input.jl")
include("Audio.jl")
include("AI.jl")
include("Rendering.jl")
include("Physics.jl")

mutable struct App <: System
  systems::Dict{DataType, System}
  function App(ymlf::String="")
    a = new(Dict())
    c = Clock()
    system!(a, c)
    system!(a, ecs)
  
    if isfile(ymlf)
      yml = YAML.load_file(ymlf)
      if haskey(yml, "clock") && yml["clock"] isa Dict
        clk = yml["clock"]
        if haskey(clk, "fire_sec") c.fire_sec = clk["fire_sec"] end
        if haskey(clk, "fire_msec") c.fire_msec = clk["fire_msec"] end
        if haskey(clk, "fire_usec") c.fire_usec = clk["fire_usec"] end
        if haskey(clk, "fire_nsec") c.fire_nsec = clk["fire_nsec"] end
        if haskey(clk, "freq") c.freq = clk["freq"] end
      end
    end
  
    return a
  end
end

system!(a::App, s::System) = a.systems[typeof(s)] = s
function awake(a::App) 
  job!(a.systems[Clock], dispatchMessage)
  map(awake, values(a.systems))
  # if running as script, keep alive
  if !isinteractive()
    while true yield() end
  end
end
shutdown(a::App) = map(shutdown, values(a.systems))

end