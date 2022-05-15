# Clock

So we need a `Clock` subsystem which uses its `awake!` and `shutdown!` functions to synchronize coroutines, and which also fires a periodic time event or "tick".

All of our coroutines need to be able to wait for the `Clock` to start, since they can be schedule any time before `awake!` is called. Ones that run periodically in the background need to be able to check whether the clock is still running, and the `Clock` itself needs to know how often to fire its tick event.

We can start with the following struct:

```julia
mutable struct Clock
  start_event::Base.Event
  is_stopped::Bool
  frequency::AbstractFloat
  Clock() = new(Base.Event(), true, 0.01667) # 60 Hz
end
```

Background tasks might be scheduled as follows, with an optional `arg` parameter in case arguments need to be passed:

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

One-off tasks might look similar, just without the loop:

```julia
function oneshot!(c::Clock, f, arg=1)
  function oneshot()
    Base.wait(c.start_event)
    f(arg)
  end
  schedule(Task(oneshot))
end
```

What about firing tick events? How do we tell a background job to wait a certain length of time between executions, since it just gets called in an infinite loop? We could try using `sleep`, but that only gives us millisecond resolution. Fortunately Julia provides the tools we need to implement our own nanosecond `sleep` function, and it's not likely we'll need finer resolution than that.

```julia
struct TICK
  Δ::AbstractFloat
end

struct SLEEP_NSEC
  Δ::UInt
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
end
```

Now we have everything we need to implement the `Clock`'s `awake!` and `shutdown!` functions:

```julia
function awake!(c::Clock)
  job!(c, tick, c.freq)
  c.is_stopped = false
  Base.notify(c.start_event)
end

function shutdown!(c::Clock)
  c.is_stopped = true
  c.start_event = Base.Event() # old one remains signaled no matter what, replace
end
```

But we still need to tell the `App` about the `Clock`. Change the constructor's `if` block:

```julia
...
a = new(Dict{DataType, Any}(), false)
system!(a, Clock())
...
```

We can add an accessor function to get the "global clock":

```julia
clk() = app[].systems[Clock]
```

And now we can add the message dispatcher to `awake!`:

```julia
function awake!(a::App)
  if !on(a)
    job!(clk(), dispatchMessage)
    map(awake!, values(a.systems))
    a.running = true
  end
end
```

If you add debug output to your code so far and run it, you'll notice it merrily dispatching and processing tick events at 60 Hz (after some startup lag from the compiler) much like in our earlier example.

The current approach of adding subsystems to the `App` doesn't scale well, since it requires modifying the constructor and adding a helper function for each subsystem. It's fine for a few important "static" systems that are considered part of the framework itself, but not for the vast number of objects that will be dynamically created, updated, used, and deleted within the lifetime of even a moderately complex program. And yet we still want these objects to be able to hook into the framework somehow so that they can be shared among subsystes and managed by the `App`. We can accomplish this with an [Entity Component System](https://en.wikipedia.org/wiki/Entity_component_system).