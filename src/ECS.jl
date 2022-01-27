abstract type Entity <: System end

# TODO support position and rotation using special decomposition algorithm

# symbols that getproperty and setproperty! care about
const ENT = :ent
const TYPE = :type
const ID = :id
const PARENT = :parent
const CHILDREN = :children
const POSITION = :pos
const ROTATION = :rot
const SHAPE = :shape
const ACTIVE = :active
const HIDDEN = :hidden
const PROPS = :props

# position, rotation, velocity, acceleration, whatever
mutable struct XYZ
  x::Number
  y::Number
  z::Number
end

# columns of the in-memory database
const components = Dict(
  ENT=>Entity,
  TYPE=>DataType,
  ID=>Int,
  PARENT=>Int,
  CHILDREN=>Vector{Int},
  POSITION=>XYZ,
  ROTATION=>XYZ,
  SHAPE=>Shape,
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

function instantiate!(comps::Dict)
  push!(ecs.df, comps)
end

get_df_row_prop(df, s) = df[!, s][1]
set_df_row_prop!(df, s, x) = df[!, s][1] = x

function Base.getproperty(ent::Entity, s::Symbol)
  e = ecs.df[!, Base.getproperty(ecs.df, ENTITY) .== ent]
  if s in keys(components) return get_df_row_prop(e, s)
  elseif s in keys(e[!, PROPS][1]) return get_df_row_prop(e, PROPS)[s]
  else return getfield(ent, s)
  end
end


function Base.setproperty!(ent::Entity, s::Symbol, x)
  e = ecs.df[!, Base.getproperty(ecs.df, ENTITY) .== ent]
  if s in [
    ENT, # immutable
    TYPE, # automatically set
    ID, # automatically set
  ]
    error("cannot set property $(s) on Entity")
  elseif s in keys(components) && s != PROPS
    set_df_row_prop!(e, s, x)
  else
    get_df_row_prop(e, PROPS)[s] = x
  end
end
