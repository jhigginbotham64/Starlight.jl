export Scene
export scn

# this is the scene graph, ladies and gentlemen,
# which we can traverse and mutate however we want
# during iteration, and initialize however we want
# and destroy however we want...sorry, it took me
# a long time to come up with this design, and i'm
# a little bit psyched about it. :)
mutable struct Scene <: ECSIterator end
const scn = Scene() # needs awake! and shutdown! for initialization/deinitialization, and a periodic task for keeping its cache updated

awake!(s::Scene) = true
shutdown!(s::Scene) = false

listenFor(scn, Starlight.TICK)

function handleMessage(s::Scene, m::Starlight.TICK)
  # sort just once per tick rather than every time we iterate
  @debug "Scene tick"
  sort!(ecs.df, [order(POSITION, rev=true, by=(pos)->pos.z)])
end

function Base.iterate(s::Scene, state::ECSIteratorState=ECSIteratorState())
  # does reverse-z order for now, only 
  # suitable for simple 2d drawing
  if state.index > length(ecs) return nothing end
  ent = ecs.df[!, ENT][state.index]
  state.index += 1
  return (ent, state)
end