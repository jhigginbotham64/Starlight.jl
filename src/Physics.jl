export Physics

mutable struct Physics <: System end

function handleMessage(p::Physics, m::TICK)
  nothing
end

function awake!(p::Physics)
  listenFor(p, TICK)
end

function shutdown!(p::Physics)
  unlistenFrom(p, TICK)
end