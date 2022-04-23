export Physics

mutable struct Physics <: System end

function handleMessage!(p::Physics, m::TICK)
  @debug "Physics tick"
  # advance physics simulation
  # update transforms
  # dispatch collision events
end

function awake!(p::Physics)
  listenFor(p, TICK)
end

function shutdown!(p::Physics)
  unlistenFrom(p, TICK)
end