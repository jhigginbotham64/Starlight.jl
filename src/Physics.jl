export Physics
export addRigidBox!, addStaticBox!, addStaticTriggerBox!, removePhysicsObject!

mutable struct Physics <: System 
  ids::Set{Int}
  Physics() = new(Set{Int}([]))
end

function addRigidBox!(id, hx, hy, hz, m, px, py, pz, isKinematic)
  push!(phys().ids, id)
  TS_BtAddRigidBox(id, hx, hy, hz, m, px, py, pz, isKinematic)
end

function addStaticBox!(id, hx, hy, hz, px, py, pz)
  push!(phys().ids, id)
  TS_BtAddStaticBox(id, hx, hy, hz, px, py, pz)
end

function addStaticTriggerBox!(id, hx, hy, hz, px, py, pz)
  push!(phys().ids, id)
  TS_BtAddStaticTriggerBox(id, hx, hy, hz, px, py, pz)
end

function removePhysicsObject!(id)
  delete!(phys().ids, id)
  TS_BtRemovePhysicsObject(id)
end

function handleMessage!(p::Physics, m::TICK)
  @debug "Physics tick"
  TS_BtStepSimulation()
  for id in p.ids
    pos = TS_BtGetPositionById(id)
    getEntityById(id).pos = XYZ(pos.x, pos.y, pos.z)
  end
  while true
    col = TS_BtGetNextCollision()
    if col.id1 == -1 && col.id2 == -1 break end
    e1, e2 = getEntityById.([col.id1, col.id2])
    handleMessage!(e1, col)
    handleMessage!(e2, col)
  end
end

function awake!(p::Physics)
  @debug "Physics awake!"
  listenFor(p, TICK)
end

function shutdown!(p::Physics)
  @debug "Physics shutdown!"
  unlistenFrom(p, TICK)
end