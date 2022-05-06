export Clock, TICK, SLEEP_NSEC, SLEEP_SEC
export tick, job!, oneshot!

"""
```julia
@with_kw mutable struct Clock{T<:AbstractFloat}
  started::Base.Event = Base.Event()
  stopped::Bool = true
  freq::T = 0.01667
end
```
# Fields
- started::Base.Event Whether awake! has been called
- stopped::Bool Whether shutdown! has been called
- freq::AbstractFloat Tick frequency
"""
@with_kw mutable struct Clock{T<:AbstractFloat}
  started::Base.Event = Base.Event()
  stopped::Bool = true
  freq::T = 0.01667
end

"""
```julia
struct TICK{T<:AbstractFloat}
  Δ::T # seconds
end
```
"""
struct TICK{T<:AbstractFloat}
  Δ::T # seconds
end

"""
```julia
struct SLEEP_SEC{T<:AbstractFloat}
  Δ::T
end
```
"""
struct SLEEP_SEC{T<:AbstractFloat}
  Δ::T
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
function Base.sleep(s::SLEEP_SEC)
  t1 = time()
  while true
    if time() - t1 >= s.Δ break end
    yield()
  end
  return time() - t1
end
```

Sleep the specified number of seconds.
"""
function Base.sleep(s::SLEEP_SEC)
  t1 = time()
  while true
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

Sleep the specified number of nanoseconds.
"""
function Base.sleep(s::SLEEP_NSEC)
  t1 = time_ns()
  while true
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

Sleep Δ seconds, the raise a TICK event with the actual amount of time slept.

Called in a background task in an infinite loop.

Primary purpose is to trigger subsystem TICK handlers.
"""
function tick(Δ)
  δ = sleep(SLEEP_NSEC(Δ * 1e9))
  sendMessage(TICK(δ / 1e9))
  @debug "tick"
end

"""
```julia
function job!(c::Clock, f, arg=1)
  function job()
    Base.wait(c.started)
    while !c.stopped
      f(arg)
    end
  end
  schedule(Task(job))
end
```

Schedule a background task to be run and synchronized with clock state.

Used internally to run dispatchMessage and tick.
"""
function job!(c::Clock, f, arg=1)
  function job()
    Base.wait(c.started)
    while !c.stopped
      f(arg)
    end
  end
  schedule(Task(job))
end

"""
```julia
function oneshot!(c::Clock, f, arg=1)
  function oneshot()
    Base.wait(c.started)
    f(arg)
  end
  schedule(Task(oneshot))
end
```

Schedule a background task to be run once, synchronized with Clock state.
"""
function oneshot!(c::Clock, f, arg=1)
  function oneshot()
    Base.wait(c.started)
    f(arg)
  end
  schedule(Task(oneshot))
end

"""
```julia
function awake!(c::Clock)
  job!(c, tick, c.freq)

  c.stopped = false

  Base.notify(c.started)
end
```

Starts the tick job and signals all waiting Tasks that the clock has started.
"""
function awake!(c::Clock)
  @debug "Clock awake!"

  job!(c, tick, c.freq)

  c.stopped = false

  Base.notify(c.started)
end


"""
```julia
function shutdown!(c::Clock)
  c.stopped = true
  
  c.started = Base.Event()
end
```

Signal Tasks that the Clock has stopped.
"""
function shutdown!(c::Clock)
  @debug "Clock shutdown!"

  c.stopped = true
  
  c.started = Base.Event() # old one remains signaled no matter what, replace
end