
export App
export run!
export on, off
export addsystem!, delsystem!

mutable struct App
  running::Bool
  ecs::Guard{EntityComponentSystem}
  systems::Dict{Function, System}
  resources::Set{Val}
  function App(ecs::EntityComponentSystem, fs::Function..., rs::Symbol...)
    gecs = guard(ecs)
    return new(false, gecs, Dict(f=>System(f, gecs) for f ∈ fs), Set(Val(r) for r ∈ rs))
  end
end

on(a::App) = a.running
off(a::App) = !a.running

function awake!(a::App)
  if on(a) shutdown!(a) end
  map(awake!, a.resources)
  pmap(awake!, values(a.systems))
  a.running = true
end

function shutdown!(a::App) 
  pmap(shutdown!, values(a.systems))
  map(shutdown!, a.resources)
  a.running = false
end

function addsystem!(a::App, f::Function)
  if haskey(a.systems, f) shutdown!(a.systems[f]) end
  a.systems[f] = System(f, a.ecs)
end

function delsystem!(a::App, f::Function)
  if haskey(a.systems, f) shutdown!(a.systems[f]) end
  delete!(a.systems, f)
end

function run!(as::App...)
  awake!.(as)
  if !isinteractive()
    while all(on.(as))
      yield()
    end
  end
end