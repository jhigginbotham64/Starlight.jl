export Scene
export scn
export scene_view

# this is the scene graph, ladies and gentlemen,
# which we can traverse and mutate however we want
# during iteration, and initialize however we want
# and destroy however we want...sorry, it took me
# a long time to come up with this design, and i'm
# a little bit psyched about it. :)
scene_view() = ecs.df[(ecs.df.type .<: [Renderable]) .& (ecs.df.hidden .== [false]), :]

mutable struct Scene <: ECSIterator end

const scn = Scene() # needs awake! and shutdown! for initialization/deinitialization

Base.length(s::Scene) = size(scene_view())[1]

function awake!(s::Scene)
  listenFor(scn, TICK)
  return true
end

function shutdown!(s::Scene)
  unlistenFrom(scn, TICK)
  return false
end


function handleMessage(s::Scene, m::TICK)
  # sort just once per tick rather than every time we iterate
  @debug "Scene tick"
  try
    sort!(ecs.df, [order(POSITION, rev=true, by=(pos)->pos.z)])
  catch
    handleException()
  end
end

function Base.iterate(s::Scene, state::ECSIteratorState=ECSIteratorState())
  # does reverse-z order for now, only 
  # suitable for simple 2d drawing
  if state.index > length(s) return nothing end
  ent = scene_view()[!, ENT][state.index]
  state.index += 1
  return (ent, state)
end