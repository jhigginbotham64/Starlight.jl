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

mutable struct Scene <: ECSIterator
  view
  Scene() = new(scene_view())
end
const scn = Scene() # needs awake! and shutdown! for initialization/deinitialization, and a periodic task for keeping its cache updated

Base.length(s::Scene) = size(s.view)[1]

awake!(s::Scene) = true
shutdown!(s::Scene) = false

listenFor(scn, TICK)

function handleMessage(s::Scene, m::TICK)
  # sort just once per tick rather than every time we iterate
  @debug "Scene tick"
  try
    sort!(ecs.df, [order(POSITION, rev=true, by=(pos)->pos.z)])
    scn.view = scene_view()
  catch
    handleException()
  end
end

function Base.iterate(s::Scene, state::ECSIteratorState=ECSIteratorState())
  # does reverse-z order for now, only 
  # suitable for simple 2d drawing
  if state.index > length(s) return nothing end
  ent = renderables[!, ENT][state.index]
  state.index += 1
  return (ent, state)
end