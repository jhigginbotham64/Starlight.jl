export Clock, TICK, SLEEP_NSEC, SLEEP_SEC
export tick, job!, oneshot!

"""
```julia
mutable struct Clock
  start_event::Base.Event
  is_stopped::Bool
  frequency::AbstractFloat
  Clock() = new(Base.Event(), true, 0.01667)
end
```
# Fields
- `start_event`::Base.Event Whether awake! has been called
- `is_stopped`::Bool Whether shutdown! has been called
- `frequency`::AbstractFloat Tick frequency
"""
mutable struct Clock
  start_event::Base.Event
  is_stopped::Bool
  frequency::AbstractFloat
  Clock() = new(Base.Event(), true, 0.01667)
end

"""
```julia
struct TICK
  Δ::AbstractFloat # seconds
end
```
"""
struct TICK
  Δ::AbstractFloat # seconds
end

"""
```julia
struct SLEEP_SEC
  Δ::AbstractFloat
end
```
"""
struct SLEEP_SEC
  Δ::AbstractFloat
end

"""
```julia
struct SLEEP_NSEC
  Δ::UInt
end
```
"""
struct SLEEP_NSEC
  Δ::UInt
end

"""
```julia
function Base.sleep(s::SLEEP_SEC) ::Float64
  t1 = time()
  while true
    if time() - t1 >= s.Δ break end
    yield()
  end
  return time() - t1
end
```

`sleep(::SLEEP_SEC) -> Float64`

Sleep the specified number of seconds.
"""
function Base.sleep(s::SLEEP_SEC) ::Float64
  t1 = time()
  while true # TODO: NEVER busy wait, jc this will melt PCs because it spikes the thread to 100% usage. Use Base.Condition instead
    if time() - t1 >= s.Δ break end
    yield()
  end
  return time() - t1
end

"""
```julia
function Base.sleep(s::SLEEP_NSEC)
  t1 = time_ns()
  while true
    if time_ns() - t1 >= s.Δ break end
    yield()
  end
  return time_ns() - t1
end
```

`sleep(::SLEEP_NSEC) -> UInt64`

Sleep the specified number of nanoseconds
"""
function Base.sleep(s::SLEEP_NSEC) ::UInt64
  t1 = time_ns()
  while true # TODO: see above
    if time_ns() - t1 >= s.Δ break end
    yield()
  end
  return time_ns() - t1
end

"""
```julia
function tick(Δ)
  δ = sleep(SLEEP_NSEC(Δ * 1e9))
  sendMessage(TICK(δ / 1e9))
end
```

`tick(::Any) -> Nothing`

Sleep Δ seconds, the raise a TICK event with the actual amount of time slept.
Called in a background task in an infinite loop. Primary purpose is to trigger subsystem TICK handlers.
"""
function tick(Δ) ::Nothing
  δ = sleep(SLEEP_NSEC(Δ * 1e9))
  sendMessage(TICK(δ / 1e9))
  Log.@debug "tick"

  return nothing
end

"""
```julia
function job!(c::Clock, f, arg=1)
  function job()
    Base.wait(c.start_event)
    while !c.is_stopped
      f(arg)
    end
  end
  schedule(Task(job))
end
```

`job!(::Clock, f::Any, arg::Any) -> Task`

Schedule a background task to be run and synchronized with clock state.
Used internally to run dispatchMessage and tick.
"""
function job!(c::Clock, f, arg=1) ::Task
  function job()
    Base.wait(c.start_event)
    while !c.is_stopped
      f(arg)
    end
  end
  schedule(Task(job))
end

"""
```julia
function oneshot!(c::Clock, f, arg=1)
  function oneshot()
    Base.wait(c.start_event)
    f(arg)
  end
  schedule(Task(oneshot))
end
```

`oneshot!(::Clock, f::Any, arg::Any) -> Task`

Schedule a background task to be run once, synchronized with Clock state.
"""
function oneshot!(c::Clock, f, arg=1) ::Task
  function oneshot()
    Base.wait(c.start_event)
    f(arg)
  end
  schedule(Task(oneshot))
end

"""
```julia
function awake!(c::Clock)
  job!(c, tick, c.frequency)

  c.is_stopped = false

  Base.notify(c.start_event)
end
```

`awake!(::Clock) -> Nothing`

Starts the tick job and signals all waiting Tasks that the clock has started.
"""
function awake!(c::Clock) ::Nothing
  Log.@debug "Clock awake!"

  job!(c, tick, c.frequency)
  c.is_stopped = false
  Base.notify(c.start_event)
end


"""
```julia
function shutdown!(c::Clock)
  c.is_stopped = true
  
  c.start_event = Base.Event()
end
```

`shutdown!(::Clock) -> Nothing`

Signal Tasks that the Clock has stopped.
"""
function shutdown!(c::Clock) ::Nothing
  Log.@debug "Clock shutdown!"

  c.is_stopped = true
  c.start_event = Base.Event() # old one remains signaled no matter what, replace
  return nothing
end