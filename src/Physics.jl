export Physics

mutable struct Physics <: System end

# function addRigidBody!(p::Physics, e::Entity)

# end

# function removeRigidBody!(p::Physics, e::Entity)

# end

# function dispatchCollision(e1::Entity, e2::Entity, c::Collision)

# end

function handleMessage!(p::Physics, m::TICK)
  @debug "Physics tick"
  # advance physics simulation -> Telescope
  # poll transform updates -> Telescope
  # update transforms -> Telescope
  # poll collision events -> Telescope
  # dispatch collision events -> Telescope
end

function awake!(p::Physics)
  listenFor(p, TICK)
end

function shutdown!(p::Physics)
  unlistenFrom(p, TICK)
end