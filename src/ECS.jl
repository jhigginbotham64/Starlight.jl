export Entity, update!
export ECS, XYZ, accumulate_XYZ
export getEntityRow, getEntityById, getEntityRowById, getDfRowProp, setDfRowProp!
export ECSIteratorState, Level
export instantiate!, destroy!
export Scene, scene_view

abstract type Entity end

update!(e, Δ) = nothing

# magic symbols that getproperty and setproperty! (and end users) care about
const ENT = :ent
const TYPE = :type
const ID = :id
const PARENT = :parent
const CHILDREN = :children
const POSITION = :pos
const ROTATION = :rot
const ABSOLUTE_POSITION = :abs_pos
const ABSOLUTE_ROTATION = :abs_rot
const HIDDEN = :hidden
const PROPS = :props

# position, rotation, velocity, acceleration, whatever
mutable struct XYZ
  x::Number
  y::Number
  z::Number
  XYZ(x=0, y=0, z=0) = new(x, y, z)
end

import Base.+, Base.-, Base.*, Base.÷, Base./, Base.%
+(a::XYZ, b::XYZ) = XYZ(a.x+b.x,a.y+b.y,a.z+b.z)
-(a::XYZ, b::XYZ) = XYZ(a.x-b.x,a.y-b.y,a.z-b.z)
*(a::XYZ, b::Number) = XYZ(a.x*b,a.y*b,a.z*b)
÷(a::XYZ, b::Number) = XYZ(a.x÷b,a.y÷b,a.z÷b)
/(a::XYZ, b::Number) = XYZ(a.x/b,a.y/b,a.z/b)
%(a::XYZ, b::Number) = XYZ(a.x%b,a.y%b,a.z%b)

# columns of the in-memory database
const components = Dict(
  ENT=>Entity,
  TYPE=>DataType,
  ID=>Number,
  PARENT=>Number,
  CHILDREN=>Set{Number},
  POSITION=>XYZ,
  ROTATION=>XYZ,
  HIDDEN=>Bool,
  PROPS=>Dict{Symbol, Any}
)

mutable struct ECS
  df::DataFrame
  awoken::Bool
  lock::ReentrantLock
  next_id::Number
  function ECS()
    df = DataFrame(
      NamedTuple{Tuple(keys(components))}(
        t[] for t in values(components)
      ))
    return new(df, false, ReentrantLock(), 0)
  end
end

# internally using Base.getproperty directly so
# as to not break if the symbol values change
getEntityRow(ent::Entity) = @view ecs().df[getproperty(ecs().df, ENT) .== [ent], :]
function getEntityById(id::Number)
  arr = ecs().df[getproperty(ecs().df, ID) .== [id], ENT]
  if length(arr) > 0
    return arr[1]
  end
  return nothing
end
getEntityRowById(id::Number) = @view ecs().df[getproperty(ecs().df, ID) .== [id], :]
getDfRowProp(r, s) = r[!, s][1]
setDfRowProp!(r, s, x) = r[!, s][1] = x

function Base.propertynames(ent::Entity)
  return (
    keys(components)...,
    ABSOLUTE_POSITION,
    ABSOLUTE_ROTATION,
    [n for n in keys(getproperty(ent, PROPS))]...
  )
end

function Base.hasproperty(ent::Entity, s::Symbol)
  return s in Base.propertynames(ent)
end

function accumulate_XYZ(r, s)
  acc = XYZ()
  while true
    inc = getDfRowProp(r, s)
    acc += inc
    r = getEntityRowById(getDfRowProp(r, PARENT))
    getDfRowProp(r, PARENT) != 0 || return acc
  end
end

function Base.getproperty(ent::Entity, s::Symbol)
  e = getEntityRow(ent)
  if s == ABSOLUTE_POSITION return accumulate_XYZ(e, POSITION)
  elseif s == ABSOLUTE_ROTATION return accumulate_XYZ(e, ROTATION)
  elseif s in keys(components) return getDfRowProp(e, s)
  elseif s in keys(getDfRowProp(e, PROPS)) return getDfRowProp(e, PROPS)[s]
  else return getfield(ent, s)
  end
end

function Base.setproperty!(ent::Entity, s::Symbol, x)
  e = getEntityRow(ent)
  if s in [
    ENT, # immutable
    TYPE, # automatically set
    ID, # automatically set
    ABSOLUTE_POSITION, # computed
    ABSOLUTE_ROTATION # computed
  ]
    error("cannot set property $(s) on Entity")
  end

  lock(ecs().lock)
  if s == PARENT
    par = getEntityById(getDfRowProp(e, PARENT))
    push!(getproperty(par, CHILDREN), getDfRowProp(e, ID))
  elseif s in keys(components) && s != PROPS
    setDfRowProp!(e, s, x)
  else
    getDfRowProp(e, PROPS)[s] = x
  end
  unlock(ecs().lock)
end

Base.length(e::ECS) = size(e.df)[1]

# TODO: the type/struct approach feels clunky, fix with Vals?
abstract type ECSIterator end

mutable struct ECSIteratorState
  root::Number
  q::Queue{Number}
  root_visited::Bool
  index::Number
  ECSIteratorState(; root=0, q=Queue{Number}(), 
  root_visited=false, index=1) = new(root, q, root_visited, index)
end

# refers to tree level, i.e. breadth-first,
# nothing special to see here
struct Level end 
Base.length(l::Level) = length(ecs())

function Base.iterate(l::Level, state::ECSIteratorState=ECSIteratorState())
  if isempty(state.q)
    if !state.root_visited # just started
      enqueue!(state.q, state.root)
      state.root_visited = true
    else # just finished
      return nothing
    end
  end

  ent = getEntityById(dequeue!(state.q))

  for c in getproperty(ent, CHILDREN) 
    enqueue!(state.q, c)
  end

  return (ent, state)
end

function handleMessage!(e::ECS, m::TICK)
  @debug "ECS tick"
  try
    map((ent) -> update!(ent, m.Δ), Level()) # TODO investigate parallelization
  catch
    handleException()
  end
end

function awake!(e::ECS)
  @debug "ECS awake!"
  e.awoken = true
  map(awake!, Level())
  listenFor(e, TICK)
end

function shutdown!(e::ECS)
  @debug "ECS shutdown!"
  unlistenFrom(e, TICK)
  map(shutdown!, Level())
  e.awoken = false
end

function instantiate!(e::Entity; kw...)
  lock(ecs().lock)

  id = ecs().next_id
  ecs().next_id += 1

  # update ecs
  # allows invalid parents and children for now
  push!(ecs().df, Dict(
    ENT=>e,
    TYPE=>typeof(e),
    ID=>id,
    CHILDREN=>get(kw, CHILDREN, Set{Number}()),
    PARENT=>get(kw, PARENT, 0),
    POSITION=>get(kw, POSITION, XYZ()),
    ROTATION=>get(kw, ROTATION, XYZ()),
    HIDDEN=>get(kw, HIDDEN, false),
    PROPS=>merge(get(kw, PROPS, Dict{Symbol, Any}()), 
      Dict(k=>v for (k,v) in kw if k ∉ 
      [CHILDREN, PARENT, POSITION, ROTATION, HIDDEN, PROPS]))
  ))

  if id != 0 # root has no parent but itself
    par = getEntityById(get(kw, PARENT, 0))
    push!(getproperty(par, CHILDREN), id)
  end

  unlock(ecs().lock)

  if ecs().awoken awake!(e) end

  return e
end

function destroy!(e::Entity)
  shutdown!(e)

  lock(ecs().lock)

  p = getEntityById(getproperty(e, PARENT))

  # if not root
  if getproperty(p, ID) != getproperty(e, ID)
    # update parent
    delete!(getproperty(p, CHILDREN), getproperty(e, ID))
    # update dataframe
    deleteat!(ecs().df, getproperty(ecs().df, ENT) .== [e])
  end

  unlock(ecs().lock)
end

function destroy!(es...)
  map(destroy!, es) # TODO investigate parallelization
end

# this is the scene graph, ladies and gentlemen,
# which we can traverse and mutate however we want
# during iteration, and initialize however we want
# and destroy however we want...sorry, it took me
# a long time to come up with this design, and i'm
# a little bit psyched about it. :)
scene_view() = ecs().df[(ecs().df.type .<: [Renderable]) .& (ecs().df.hidden .== [false]), :]

struct Scene end

Base.length(s::Scene) = size(scene_view())[1]

function Base.iterate(s::Scene, state::ECSIteratorState=ECSIteratorState())
  # does reverse-z order for now, only 
  # suitable for simple 2d drawing
  if state.index > length(s) return nothing end
  ent = scene_view()[!, ENT][state.index]
  state.index += 1
  return (ent, state)
end

function awake!(s::Scene)
  @debug "Scene awake!"
  listenFor(s, TICK)
end

function shutdown!(s::Scene)
  @debug "Scene shutdown!"
  unlistenFrom(s, TICK)
end

function handleMessage!(s::Scene, m::TICK)
  # sort just once per tick rather than every time we iterate
  @debug "Scene tick"
  try
    sort!(ecs().df, [order(POSITION, rev=true, by=(pos)->pos.z)])
  catch
    handleException()
  end
end