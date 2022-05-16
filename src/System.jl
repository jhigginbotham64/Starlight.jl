export System

mutable struct System
  f::Function
  ecs::Guard{EntityComponentSystemy}
  l::Link
  System(f::Function, ecs::Guard{EntityComponentSystem}) = new(f, ecs)
end

function awake!(s::System)
  s.l = spawn(s.f, s.ecs)
  cast(s.l)
end

function shutdown(s::System)
  exit!(s.l)
end