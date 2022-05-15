export Entity, EntityComponentSystem
export runcomponent!, runcomponentforentities!
export components, iscomponent, iscomputed, hasdefault
export delcomponent!, delcomponentfromentity!, delentity!
export destroy!

struct EntityComponentSystem
  nextid::Int
  nentities::Int
  ids::Dict{Any, Int}
  entities::Dict{Int, Any}
  components::DefaultDict{Symbol, DefaultDict{Int, Any, Nothing}}
  defaults::Dict{Symbol, Any}
  computed::Dict{Symbol, Function}
  function EntityComponentSystem()
    return new(
      0,
      0, 
      Dict{Any, Int}(), 
      Dict{Int, Any}(), 
      DefaultDict{Symbol, DefaultDict{Int, Any, Nothing}}(DefaultDict{Int, Any, Nothing}(nothing)), 
      Dict{Symbol, Any}(), 
      Dict{Symbol, Function}(),
    )
  end
end

# default pos
# default scale
# default cell size
# default cell ind
# default region
# default color
# computed id
# set computed
# set default
# remove computed
# remove default
# hooks

function nextid!(ecs::EntityComponentSystem)  
  ecs.nextid += 1
end

function components(ecs::EntityComponentSystem)
  union(keys(ecs.components), keys(ecs.defaults), keys(ecs.computed))
end

function iscomponent(ecs::EntityComponentSystem, c::Symbol)
  haskey(ecs.components, c)
end

function iscomputed(ecs::EntityComponentSystem, c::Symbol)
  haskey(ecs.computed, c)
end

function hasdefault(ecs::EntityComponentSystem, c::Symbol)
  haskey(ecs.defaults, c)
end

function delcomponent!(ecs::EntityComponentSystem, c::Symbol)
  delete!(ecs.components, c)
end

function delcomponentfromentity!(ecs::EntityComponentSystem, c::Symbol, id::Int)
  if iscomponent(ecs, c)
    delete!(ecs.components[c], id)
  end
end

Base.length(ecs::EntityComponentSystem) = ecs.nentities
Base.size(ecs::EntityComponentSystem) = length(ecs)

function runcomponent!(ecs::EntityComponentSystem, c::Symbol, args...; kwargs...)
  if iscomponent(ecs, c)
    Threads.@threads for (k, v) ∈ collect(ecs.components[c])
      v(ecs.entities[k], args...; kwargs...)
    end
  end
end

function runcomponentforentities!(ecs::EntityComponentSystem, entityIds, c::Symbol, args...; kwargs...)
  if iscomponent(ecs, c)
    Threads.@threads for id in entityIds
      f = ecs.components[c][id]
      if !isnothing(f)
        f(ecs.entities[id], args...; kwargs...)
      end
    end
  end
end

mutable struct Entity
  ecs::Guard{EntityComponentSystem}
  Entity(ecs::Guard{EntityComponentSystem}; kw...) = instantiate!(new(ecs); kw...)
end

function getentityproperty(ecs::EntityComponentSystem, entity::Entity, s::Symbol)
  id = ecs.ids[entity]
  if iscomponent(ecs, s) && haskey(ecs.components[s], id)
    ecs.components[s][id]
  elseif iscomputed(ecs, s)
    ecs.computed[s](entity)
  elseif hasdefault(ecs, s)
    ecs.defaults[s]
  else
    nothing
  end
end

Base.getproperty(entity::Entity, s::Symbol) = @grd getentityproperty(entity.ecs, entity, s)

function setentityproperty!(ecs::EntityComponentSystem, entity::Entity, s::Symbol, val)
  id = ecs.ids[entity]
  ecs.components[s][id] = val
end

Base.setproperty!(entity::Entity, s::Symbol, val) = @grd setentityproperty!(entity.ecs, entity, s, val)

function getentitycomponents(ecs::EntityComponentSystem, entity)
  id = ecs.ids[entity]
  componentnames = []
  for c ∈ components(ecs)
    if !isnothing(ecs.components[c][id]) 
      push!(componentnames, c) 
    end
  end
  return componentnames
end

components(entity::Entity) = @grd getentitycomponents(entity.ecs, entity)

function getentitypropertynames(ecs::EntityComponentSystem, entity::Entity)
  union(components(entity), keys(ecs.defaults), keys(ecs.computed))
end

Base.propertynames(entity::Entity) = @grd getentitypropertynames(entity.ecs, entity)

function getentityhasproperty(ecs::EntityComponentSystem, entity::Entity, s::Symbol)
  id = ecs.ids[entity]
  return haskey(ecs.components[s], id) || hasdefault(ecs, s) || iscomputed(ecs, s)
end

Base.hasproperty(entity::Entity, s::Symbol) = @grd getentityhasproperty(entity.ecs, entity, s)

function addentity!(ecs::EntityComponentSystem, entity::Entity; kw...)
  id = nextid!(ecs)
  ecs.ids[entity] = id
  ecs.entities[id] = entity
  for (k, v) ∈ kw
    setproperty!(entity, k, v)
  end
  ecs.nentities += 1
  return entity
end

instantiate!(entity::Entity; kw...) = @grd addentity!(entity.ecs, entity; kw...)

function delentity!(ecs::EntityComponentSystem, entity::Entity)
  id = ecs.ids[entity]
  for c ∈ components(entity)
    delcomponentfromentity!(ecs, c, id)
  end
  delete!(ecs.entities, id)
  delete!(ecs.ids, entity)
  ecs.nentities -= 1
end

destroy!(entity::Entity) = @grd delentity!(entity.ecs, entity)
