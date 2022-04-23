export Entity, update!
export ECS, XYZ, accumulate_XYZ, get_entity_row, get_entity_by_id
export get_entity_row_by_id, get_df_row_prop, set_df_row_prop!
export ECSIterator, ECSIteratorState, Level
export Root, instantiate!, destroy!
export Scene, scene_view


abstract type Entity <: System end

awake!(e::Entity) = true
shutdown!(e::Entity) = false
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
  ID=>Int,
  PARENT=>Int,
  CHILDREN=>Set{Int},
  POSITION=>XYZ,
  ROTATION=>XYZ,
  PROPS=>Dict{Symbol, Any}
)

mutable struct ECS <: System
  df::DataFrame
  awoken::Bool
  lock::ReentrantLock
  next_id::Int
  function ECS()
    df = DataFrame(
      NamedTuple{Tuple(keys(components))}(
        t[] for t in values(components)
      ))
    return new(df, false, ReentrantLock(), 0)
  end
end

# internally uses Base.getproperty directly so
# as to not break if the symbol values change
get_entity_row(ent::Entity) = @view ecs().df[getproperty(ecs().df, ENT) .== [ent], :]
get_entity_by_id(id::Int) = ecs().df[getproperty(ecs().df, ID) .== [id], ENT][1]
get_entity_row_by_id(id::Int) = @view ecs().df[getproperty(ecs().df, ID) .== [id], :]
get_df_row_prop(r, s) = r[!, s][1]
set_df_row_prop!(r, s, x) = r[!, s][1] = x

function Base.propertynames(ent::Entity)
  return (
    ENT,
    TYPE,
    ID,
    CHILDREN,
    PARENT,
    POSITION,
    ROTATION,
    ABSOLUTE_POSITION,
    ABSOLUTE_ROTATION,
    PROPS,
    [n for n in keys(getproperty(ent, PROPS))]...
  )
end

function Base.hasproperty(ent::Entity, s::Symbol)
  return s in Base.propertynames(ent)
end

function accumulate_XYZ(r, s)
  acc = XYZ()
  while true
    inc = get_df_row_prop(r, s)
    acc += inc
    r = get_entity_row_by_id(get_df_row_prop(r, PARENT))
    get_df_row_prop(r, PARENT) != 0 || return acc
  end
end

function Base.getproperty(ent::Entity, s::Symbol)
  e = get_entity_row(ent)
  if s == ABSOLUTE_POSITION return accumulate_XYZ(e, POSITION)
  elseif s == ABSOLUTE_ROTATION return accumulate_XYZ(e, ROTATION)
  elseif s in keys(components) return get_df_row_prop(e, s)
  elseif s in keys(get_df_row_prop(e, PROPS)) return get_df_row_prop(e, PROPS)[s]
  else return getfield(ent, s)
  end
end

function Base.setproperty!(ent::Entity, s::Symbol, x)
  e = get_entity_row(ent)
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
    par = get_entity_by_id(get_df_row_prop(e, PARENT))
    push!(getproperty(par, CHILDREN), get_df_row_prop(e, ID))
  elseif s in keys(components) && s != PROPS
    set_df_row_prop!(e, s, x)
  else
    get_df_row_prop(e, PROPS)[s] = x
  end
  unlock(ecs().lock)
end

Base.length(e::ECS) = size(e.df)[1]

# can define multiple iteration types using
# multiple dispatch thanks to all the global
# constants, and by defining them as structs
# rather than enums we can pass arbitrary
# parameters to the iterator
abstract type ECSIterator <: System end

mutable struct ECSIteratorState
  root::Int
  q::Queue{Int}
  root_visited::Bool
  index::Int
  ECSIteratorState(; root=0, q=Queue{Int}(), root_visited=false, index=1) = new(root, q, root_visited, index)
end

# refers to tree level, i.e. breadth-first,
# nothing special to see here
struct Level <: ECSIterator end 
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

  ent = get_entity_by_id(dequeue!(state.q))

  for c in getproperty(ent, CHILDREN) 
    enqueue!(state.q, c)
  end

  return (ent, state)
end

function handleMessage(e::ECS, m::TICK)
  @debug "ECS tick"
  try
    map((ent) -> update!(ent, m.Δ), Level()) # TODO investigate parallelization
  catch
    handleException()
  end
end

function awake!(e::ECS)
  e.awoken = true
  map(awake!, Level())
  listenFor(e, TICK)
end

function shutdown!(e::ECS) 
  unlistenFrom(e, TICK)
  all(map(shutdown!, Level()))
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
    CHILDREN=>get(kw, :children, Set{Int}()),
    PARENT=>get(kw, :pid, 0),
    POSITION=>get(kw, :pos, XYZ()),
    ROTATION=>get(kw, :rot, XYZ()),
    PROPS=>merge(get(kw, :props, Dict{Symbol, Any}()), 
      Dict(k=>v for (k,v) in kw if k ∉ 
      [:children, :pid, :pos, :rot, :props]))
  ))

  if id != 0 # root has no parent but itself
    par = get_entity_by_id(get(kw, :pid, 0))
    push!(getproperty(par, CHILDREN), id)
  end

  unlock(ecs().lock)

  if ecs().awoken awake!(e) end

  return e
end

function destroy!(e::Entity)
  shutdown!(e)

  lock(ecs().lock)

  p = get_entity_by_id(getproperty(e, PARENT))

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
scene_view() = ecs().df[ecs().df.type .<: [Renderable], :]

mutable struct Scene <: ECSIterator end

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
  listenFor(s, TICK)
end

function shutdown!(s::Scene)
  unlistenFrom(s, TICK)
end

function handleMessage(s::Scene, m::TICK)
  # sort just once per tick rather than every time we iterate
  @debug "Scene tick"
  try
    sort!(ecs().df, [order(POSITION, rev=true, by=(pos)->pos.z)])
  catch
    handleException()
  end
end