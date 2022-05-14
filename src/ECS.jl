export Entity, ECS
export nextid!, components, iscomponent, addentity!, delentity!, delcomponentfromentity!
export runcomponent!, runcomponentforentities!

setnesteddictval!(dict, key1, key2, val) = dict[key1][key2] = val

deldictkey!(dict, key) = delete!(dict, key)

delnesteddictkey!(dict, key1, key2) = delete!(dict[key1], key2)

getdictkeys(dict) = keys(dict)

dicthaskey(dict, key) = haskey(dict, key)

struct ECS
  meta
  ids
  entities
  components
  function ECS()
    meta = guard(Dict{Symbol, Any}(
      :nextid => 0,
      :nentities => 0,
    ))
    ids = guard(Dict{Any, Int}())
    entities = guard(Dict{Int, Any}())
    components = guard(Dict{Symbol, DefaultDict{Int, Any, Nothing}}())
    return new(meta, ids, entities, components)
  end
end

function nextid!(ecs::ECS)  
  return ecs.meta[:nextid] += 1
end

function components(ecs::ECS)
  @grd getdictkeys(ecs.components)
end

function iscomponent(ecs::ECS, c::Symbol)
  @grd dicthaskey(ecs.components, c)
end

function delcomponentfromentity!(ecs::ECS, c::Symbol, id::Int)
  @grd delnesteddictkey!(ecs.components, c, id)
end

Base.length(ecs::ECS) = ecs.meta[:nentities]
Base.size(ecs::ECS) = length(ecs)

mutable struct Entity
  ecs::ECS
  Entity(ecs::ECS; kw...) = finalizer(destroy!, instantiate!(new(ecs); kw...))
end

function Base.getproperty(entity::Entity, s::Symbol)
  ecs = entity.ecs
  id = ecs.ids[entity]
  if iscomponent(ecs, s)
    return ecs.components[s][id]
  else
    return nothing
  end
end

function Base.setproperty!(entity::Entity, s::Symbol, val)
  ecs = entity.ecs
  id = ecs.ids[entity]
  @grd setnesteddictval!(ecs.components, s, id, val)
end

function Base.propertynames(entity::Entity)
  ecs = entity.ecs
  id = ecs.ids[entity]
  pnames = []
  for c ∈ components(ecs)
    if !isnothing(ecs.components[c][id]) 
      push!(pnames, c) 
    end
  end
  return pnames
end

function Base.hasproperty(entity::Entity, s::Symbol)
  ecs = entity.ecs
  id = ecs.ids[entity]
  return !isnothing(ecs.components[s][id])
end

function instantiate!(entity::Entity; kw...)
  ecs = entity.ecs
  id = nextid!(ecs)
  ecs.ids[entity] = id
  ecs.entities[id] = entity
  for (k, v) ∈ kw
    setproperty!(entity, k, v)
  end
  ecs.meta[:nentities] += 1
  return entity
end

function destroy!(entity::Entity)
  ecs = entity.ecs
  id = ecs.ids[entity]
  for p ∈ propertynames(entity)
    delcomponentfromentity!(ecs, p, id)
  end
  @grd deldictkey!(ecs.entities, ecs.ids[entity])
  @grd deldictkey!(ecs.ids, entity)
  ecs.meta[:nentities] -= 1
end

function runcomponent!(ecs::ECS, c::Symbol, args...; kwargs...)
  if iscomponent(ecs, c)
    Threads.@threads for (k, v) ∈ collect(ecs.components[c])
      v(ecs.entities[k], args...; kwargs...)
    end
  end
end

function runcomponentforentities!(ecs::ECS, entityIds, c::Symbol, args...; kwargs...)
  if iscomponent(ecs, c)
    Threads.@threads for id in entityIds
      f = ecs.components[c][id]
      if !isnothing(f)
        f(ecs.entities[id], args...; kwargs...)
      end
    end
  end
end
