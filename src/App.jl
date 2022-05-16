
export App
export run!
export on, off
export addsystem!, delsystem!

mutable struct App
  running::Bool
  ecs::Guard{EntityComponentSystem}
  systems::Dict{Function, System}
  resources::Dict{Val, Dict{Symbol, Any}}
  function App(ecs::EntityComponentSystem, fs::Function...; kw...)
    gecs = guard(ecs)
    systems = Dict(f=>System(f, gecs) for f ∈ fs)
    resources = Dict(Val(k)=>v for (k, v) ∈ kw)
    for (k, v) ∈ resources
      awake!(k, v)
    end
    app = new(false, gecs, systems, resources)
    return finalizer(finalizeapp!, app)
  end
end

on(a::App) = a.running
off(a::App) = !a.running

function awake!(a::App)
  if on(a) shutdown!(a) end
  @grd runcomponent!(a.ecs, :awake)
  pmap(awake!, values(a.systems))
  a.running = true
end

function shutdown!(a::App)
  if on(a)
    pmap(shutdown!, values(a.systems))
    @grd runcomponent!(a.ecs, :shutdown)
    a.running = false
  end
end

function finalizeapp!(a::App)
  shutdown!(a)
  for (k, v) ∈ a.resources
    shutdown!(k, v)
  end
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
    while any(on.(as))
      yield()
    end
  end
end