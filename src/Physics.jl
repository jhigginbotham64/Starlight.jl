export Physics
export addRigidBox!, addStaticBox!, addTriggerBox!, removePhysicsObject!
export other

other(e::Entity, col::TS_CollisionEvent) = (e.id == col.id1) ? col.id2 : col.id1

mutable struct PhysicsObjectInfo
  hx::AbstractFloat
  hy::AbstractFloat
  hz::AbstractFloat
  m::AbstractFloat
  isKinematic::Bool
  mx::AbstractFloat
  my::AbstractFloat
  mz::AbstractFloat
  PhysicsObjectInfo(hx = 0, hy = 0, hz = 0, m = 0, isKinematic = false, mx = 0, my = 0, mz = 0) = new(hx, hy, hz, m, isKinematic, mx, my, mz)
end

mutable struct Physics 
  ids::Dict{Number, PhysicsObjectInfo}
  Physics() = new(Dict{Number, PhysicsObjectInfo}())
end

function addRigidBox!(e, hx, hy, hz, m, px, py, pz, isKinematic = false, mx = 0, my = 0, mz = 0)
  phys().ids[e.id] = PhysicsObjectInfo(hx, hy, hz, m, isKinematic, mx, my, mz)
  TS_BtAddRigidBox(e.id, hx + mx, hy + my, hz + mz, m, px, py, pz, isKinematic)
end

function addStaticBox!(e, hx, hy, hz, px, py, pz, mx = 0, my = 0, mz = 0)
  phys().ids[e.id] = PhysicsObjectInfo(hx, hy, hz, 0.0, false, mx, my, mz)
  TS_BtAddStaticBox(e.id, hx + mx, hy + my, hz + mz, px, py, pz)
end

function addTriggerBox!(e, hx, hy, hz, px, py, pz, mx = 0, my = 0, mz = 0)
  phys().ids[e.id] = PhysicsObjectInfo(hx, hy, hz, 1.0, false, mx, my, mz)
  TS_BtAddTriggerBox(e.id, hx + mx, hy + my, hz + mz, px, py, pz)
end

function removePhysicsObject!(e)
  delete!(phys().ids, e.id)
  TS_BtRemovePhysicsObject(e.id)
end

function handleMessage!(p::Physics, m::TICK)
  Log.@debug "Physics tick"
  TS_BtStepSimulation()
  for (id, pinfo) in p.ids
    pos = TS_BtGetPosition(id)
    # TODO: this is a bad hack for working specifically with rectangular objects, needs improvement
    getEntityById(id).pos = XYZ(pos.x - pinfo.hx, pos.y - pinfo.hy, pos.z - pinfo.hz)
  end
  while true
    col = TS_BtGetNextCollision()
    if col.id1 == -1 && col.id2 == -1 break end
    Log.@debug "entities $(col.id1) and $(col.id2) have a collision event"
    e1 = getEntityById(col.id1)
    e2 = getEntityById(col.id2)
    handleMessage!(e1, col)
    handleMessage!(e2, col)
  end
end

function awake!(p::Physics)
  Log.@debug "Physics awake!"
  listenFor(p, TICK)
end

function shutdown!(p::Physics)
  Log.@debug "Physics shutdown!"
  unlistenFrom(p, TICK)
end