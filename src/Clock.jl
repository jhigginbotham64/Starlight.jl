export Clock, TICK, SLEEP_NSEC, SLEEP_SEC
export tick, job!, oneshot!

mutable struct Clock <: System
  started::Base.Event
  stopped::Bool
  freq::AbstractFloat
  Clock() = new(Base.Event(), true, 0.01667)
end

struct TICK
  Δ::AbstractFloat # seconds
end

struct SLEEP_SEC
  Δ::UInt
end

struct SLEEP_NSEC
  Δ::UInt
end

function Base.sleep(s::SLEEP_SEC)
  t1 = time()
  while true
    if time() - t1 >= s.Δ break end
    yield()
  end
  return time() - t1
end

function Base.sleep(s::SLEEP_NSEC)
  t1 = time_ns()
  while true
    if time_ns() - t1 >= s.Δ break end
    yield()
  end
  return time_ns() - t1
end

function tick(Δ)
  δ = sleep(SLEEP_NSEC(Δ * 1e9))
  sendMessage(TICK(δ / 1e9))
  @debug "tick"
end

function job!(c::Clock, f, arg=1)
  function job()
    Base.wait(c.started)
    while !c.stopped
      f(arg)
    end
  end
  schedule(Task(job))
end

function oneshot!(c::Clock, f, arg=1)
  function oneshot()
    Base.wait(c.started)
    f(arg)
  end
  schedule(Task(oneshot))
end

function awake!(c::Clock)
  @debug "Clock awake!"

  job!(c, tick, c.freq)

  c.stopped = false

  Base.notify(c.started)
end

function shutdown!(c::Clock)
  @debug "Clock shutdown!"
  c.stopped = true
  c.started = Base.Event() # old one remains signaled no matter what, replace
end