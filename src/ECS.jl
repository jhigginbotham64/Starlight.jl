abstract type Entity <: System end

awake(e::Entity) = nothing
shutdown(e::Entity) = nothing
update(e::Entity, Δ::AbstractFloat) = nothing

export ECS, XYZ, accumulate_XYZ, get_entity_row, get_entity_by_id
export get_entity_row_by_id, get_df_row_prop, set_df_row_prop!
export TREE_ORDER, ECS_ITERATION_STATE

# symbols that getproperty and setproperty! (and end users) care about
const ENT = :ent
const TYPE = :type
const ID = :id
const PARENT = :parent
const CHILDREN = :children
const POSITION = :pos
const ROTATION = :rot
const ABSOLUTE_POSITION = :abs_pos
const ABSOLUTE_ROTATION = :abs_rot
const ACTIVE = :active
const HIDDEN = :hidden
const PROPS = :props

# position, rotation, velocity, acceleration, whatever
mutable struct XYZ
  x::Number
  y::Number
  z::Number
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
  CHILDREN=>Vector{Int},
  POSITION=>XYZ,
  ROTATION=>XYZ,
  ACTIVE=>Bool,
  HIDDEN=>Bool,
  PROPS=>Dict{Any, Any}
)

struct ECS <: Starlight.System
  df::DataFrame
  function ECS()
    df = DataFrame(
      NamedTuple{Tuple(keys(components))}(
        t[] for t in values(components)
      ))
    return new(df)
  end
end

const ecs = ECS()

# internally uses Base.getproperty directly so
# as to not break if the symbol values change
get_entity_row(e::ECS, ent::Entity) = e.df[Base.getproperty(e.df, ENTITY) .== ent, :]
get_entity_by_id(e::ECS, id::Int) = e.df[Base.getproperty(e.df, ID) .== id, ENT][1]
get_entity_row_by_id(e::ECS, id::Int) = e.df[Base.getproperty(e.df, ID) .== id, :]
get_df_row_prop(r, s) = r[!, s][1]
set_df_row_prop!(r, s, x) = r[!, s][1] = x

function accumulate_XYZ(r, s)
  acc = XYZ(0, 0, 0)
  while true
    r = get_entity_row_by_id(ecs, get_df_row_prop(r, PARENT))
    inc = get_df_row_prop(r, s)
    acc += inc
    get_df_row_prop(r, PARENT) != 0 || return acc
  end
end

function Base.getproperty(ent::Entity, s::Symbol)
  e = get_entity_row(ecs, ent)
  if s == ABSOLUTE_POSITION return accumulate_XYZ(e, POSITION)
  elseif s == ABSOLUTE_ROTATION return accumulate_XYZ(e, ROTATION)
  elseif s in keys(components) return get_df_row_prop(e, s)
  elseif s in keys(get_df_row_prop(e, PROPS)) return get_df_row_prop(e, PROPS)[s]
  else return getfield(ent, s)
  end
end

function Base.setproperty!(ent::Entity, s::Symbol, x)
  e = get_entity_row(ecs, ent)
  if s in [
    ENT, # immutable
    TYPE, # automatically set
    ID, # automatically set
    ABSOLUTE_POSITION, # computed
    ABSOLUTE_ROTATION # computed
  ]
    error("cannot set property $(s) on Entity")
  elseif s in keys(components) && s != PROPS
    set_df_row_prop!(e, s, x)
  else
    get_df_row_prop(e, PROPS)[s] = x
  end
end

# you can iterate over an ECS!
# only supports level order for now,
# but may support others once we get
# into physics and rendering, such as
# z-order. other tree traversal types
# can be added in the future.
Base.eltype(::Type{ECS}) = Entity
Base.length(e::ECS) = size(e.df)[1]

@enum TREE_ORDER begin
  LEVEL=1 # i.e. breadth-first
end

mutable struct ECS_ITERATION_STATE
  root::Int
  o::TREE_ORDER
  q::Queue{Entity}
  root_visited::Bool
  ECS_ITERATION_STATE(; root=0, o=LEVEL, q=Queue{Entity}(), root_visited=false) = new(root, o, q, root_visited)
end

function Base.iterate(e::ECS, state::ECS_ITERATION_STATE=ECS_ITERATION_STATE())
  if state.o == LEVEL
    if isempty(state.q)
      if !state.root_visited # just started
        enqueue!(state.q, get_entity_by_id(e, state.root))
        s.root_visited = true
      else # just finished
        return nothing
      end
    end

    ent = dequeue!(state.q)

    for c in getproperty(ent, CHILDREN) 
      enqueue!(state.q, get_entity_by_id(e, c))
    end

    return ent
  end
end

listenFor(ecs, Starlight.TICK)

function handleMessage(e::ECS, m::Starlight.TICK)
  _update = (ent::Entity) -> update(ent, m.Δ)
  map(_update, e)
end

function awake(e::ECS)
  map(awake, e)
end

function shutdown(e::ECS)
  map(shutdown, e)
end