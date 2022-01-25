mutable struct Clock <: Starlight.System
  started::Base.Event
  stopped::Bool
  fire_sec::Bool
  fire_msec::Bool
  fire_usec::Bool
  fire_nsec::Bool
  freq::AbstractFloat
end

Clock() = Clock(Base.Event(), true, false, false, false, false, 0.01667) # default frequency of approximately 60 Hz

# RT == "real time"
# Δ carries the "actual" number of given time units elapsed
struct RT_SEC <: Starlight.Event
  Δ::AbstractFloat
end
struct RT_MSEC <: Starlight.Event
  Δ::AbstractFloat
end
struct RT_USEC <: Starlight.Event
  Δ::AbstractFloat
end
struct RT_NSEC <: Starlight.Event
  Δ::AbstractFloat
end
struct TICK <: Starlight.Event
  Δ::AbstractFloat # seconds, but is a distinct event from RT_SEC
end

struct SLEEP_TIME
  Δ::UInt # time in nanoseconds to sleep for
end

function Base.sleep(s::SLEEP_TIME)
  t1 = time_ns()
  while true
    if time_ns() - t1 >= s.Δ break end
    yield()
  end
  return time_ns() - t1
end

function nsleep(Δ)
  δ = sleep(SLEEP_TIME(Δ))
  Starlight.sendMessage(RT_NSEC(δ))
  @debug "nanosecond"
end

function usleep(Δ)
  δ = sleep(SLEEP_TIME(Δ * 1e3))
  Starlight.sendMessage(RT_USEC(δ / 1e3))
  @debug "microsecond"
end

function msleep(Δ)
  δ = sleep(SLEEP_TIME(Δ * 1e6))
  Starlight.sendMessage(RT_MSEC(δ / 1e6))
  @debug "millisecond"
end

function ssleep(Δ)
  δ =  sleep(SLEEP_TIME(Δ * 1e9))
  Starlight.sendMessage(RT_SEC(δ / 1e9))
  @debug "second"
end

function tick(Δ)
  δ = sleep(SLEEP_TIME(Δ * 1e9))
  Starlight.sendMessage(TICK(δ / 1e9))
  @debug "tick"
end

function add_job!(c::Clock, f, arg=1)
  function job()
    Base.wait(c.started)
    while !c.stopped
      f(arg)
    end
  end
  schedule(Task(job))
end

function awake(c::Clock)
  if c.fire_sec add_job!(c, ssleep) end
  if c.fire_msec add_job!(c, msleep) end
  if c.fire_usec add_job!(c, usleep) end
  if c.fire_nsec add_job!(c, nsleep) end

  add_job!(c, tick, c.freq)

  c.stopped = false

  Base.notify(c.started)
end

function shutdown(c::Clock)
  c.stopped = true
end