# Physics

Starlight provides a default subsystem for conveniently working with Telescope's Bullet integration. Explaining all of how it works would require an explanation of [Bullet itself](https://pybullet.org/wordpress/index.php/forum-2/), but we'll attempt a high-level overview of the most important things it does.

```julia
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

function handleMessage!(p::Physics, m::TICK)
  TS_BtStepSimulation()
  for (id, pinfo) in p.ids
    pos = TS_BtGetPosition(id)
    # TODO: this is a bad hack for working specifically with rectangular objects, needs improvement
    getEntityById(id).pos = XYZ(pos.x - pinfo.hx, pos.y - pinfo.hy, pos.z - pinfo.hz)
  end
  while true
    col = TS_BtGetNextCollision()
    if col.id1 == -1 && col.id2 == -1 break end
    e1 = getEntityById(col.id1)
    e2 = getEntityById(col.id2)
    handleMessage!(e1, col)
    handleMessage!(e2, col)
  end
end

function awake!(p::Physics)
  listenFor(p, TICK)
end

function shutdown!(p::Physics)
  unlistenFrom(p, TICK)
end
```

Basically there is a struct, `PhysicsObjectInfo`, that Starlight uses to keep track of the physics entities created using its API (which is not shown, but uses Telescope's Bullet-related APIs). The tick handler tells Bullet to update its internal state ("simulation"), then takes care of updating the positions of any objects that have moved as well as dispatching collision events.

Note that for now collision handlers (`handleMessage!` methods where the message has type `TS_CollisionEvent`) are invoked directly by the physics system rather than through the message dispatcher. Changing this would be complicated, since it requires the message dispatcher to know about "message recipients" or some such (since all it does currently is broadcast based on message type), which would also require changes to `listenFor` and `unlistenFrom`. However there are in fact plans to make those changes, since ideally all events would go through the dispatcher, and doing so would both simplify the existing physics code and make it easier to implement alternative physics subsystems.