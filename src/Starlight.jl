module Starlight

using Base: Semaphore, acquire, release
using DataStructures
using YAML
using SimpleDirectMediaLayer
using SimpleDirectMediaLayer.LibSDL2

export priority, id, handleMessage, sendMessage, listenFor, dispatchNextMessage
export System, App, awake, shutdown

entities = Dict{Int, Any}()
listeners = Dict{DataType, Vector{Any}}()
messages = PriorityQueue{Any, Int}()

DEFAULT_PRIORITY = -Inf # non-library messages go first
DEFAULT_ID = -Inf # will not be used by any sane id generation scheme

MQUEUE_SIZE = 1000

slot_available = Semaphore(MQUEUE_SIZE)
msg_ready = Semaphore(MQUEUE_SIZE)
mqueue_lock = Semaphore(1)
entity_lock = Semaphore(1)
listener_lock = Semaphore(1)

release(mqueue_lock)
release(entity_lock)
release(listener_lock)

for i in 1:MQUEUE_SIZE
  release(slot_available)
end

function priority(e)
    (hasproperty(e, :priority)) ? e.priority : DEFAULT_PRIORITY
end

function id(e)
    (hasproperty(e, :id)) ? e.id : DEFAULT_ID
end

function handleMessage(l, m)
    nothing
end

function sendMessage(e)
  acquire(slot_available)
  acquire(mqueue_lock)
  enqueue!(events, e, priority(e))
  release(mqueue_lock)
  release(msg_ready)
end

function listenFor(d::DataType, e)
  acquire(listener_lock)
  if !haskey(listeners, d) listeners[d] = Vector{Any}()
  push!(listeners[d], e)
  release(listener_lock)
end

function dispatchNextMessage()
  acquire(msg_ready)
  acquire(mqueue_lock)
  m = dequeue_pair!(messages)
  for l in listeners[typeof(m)]
    handleMessage(l, m)
  end
  release(mqueue_lock)
  release(slot_available)
end

abstract type System end
abstract type Event end

awake(s::System) = nothing
shutdown(s::System) = nothing

mutable struct App <: System
  systems::Vector{System}
end

awake(a::App) = map(awake, a.systems)
shutdown(a::App) = map(shutdown, a.systems)

include("Clock.jl")
include("Renderer.jl")
include("Physics.jl")
include("AI.jl")
include("Audio.jl")
include("Scene.jl")
include("Input.jl")

function App(ymlf::String)
  yml = YAML.load_file(ymlf)
end