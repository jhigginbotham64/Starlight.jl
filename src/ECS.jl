export Entity, ECS
export runcomponent!, runcomponentforentities!

struct ECS
  nextid::Int
  nentities::Int
  ids::Dict{Any, Int}
  entities::Dict{Int, Any}
  components::Dict{Symbol, Dict{Int, Any}}
  defaults::Dict{Symbol, Any}
  computed::Dict{Symbol, Function}
  hooks::Dict{Symbol, Function}
  function ECS()
    return new(
      0,
      0, 
      Dict{Any, Int}(), 
      Dict{Int, Any}(), 
      Dict{Symbol, Dict{Int, Any}}(), 
      Dict{Symbol, Any}(), 
      Dict{Symbol, Function}(),
      Dict{Symbol, Function}()
    )
  end
end

function nextid!(ecs::ECS)  

end

function components(ecs::ECS)
  union(keys(ecs.components), keys(ecs.defaults), keys(ecs.computed))
end

function iscomponent(ecs::ECS, c::Symbol)

end

function delcomponentfromentity!(ecs::ECS, c::Symbol, id::Int)

end

Base.length(ecs::ECS) = ecs.meta[:nentities]
Base.size(ecs::ECS) = length(ecs)

mutable struct Entity
  ecs::ECS
  Entity(ecs::ECS; kw...) = finalizer(destroy!, instantiate!(new(ecs); kw...))
end

function Base.getproperty(entity::Entity, s::Symbol)
  
end

function Base.setproperty!(entity::Entity, s::Symbol, val)
  
end

function Base.propertynames(entity::Entity)
  
end

function Base.hasproperty(entity::Entity, s::Symbol)
  
end

function instantiate!(entity::Entity; kw...)
  
end

function destroy!(entity::Entity)
  
end

function runcomponent!(ecs::ECS, c::Symbol, args...; kwargs...)
  
end

function runcomponentforentities!(ecs::ECS, entityIds, c::Symbol, args...; kwargs...)
  
end
