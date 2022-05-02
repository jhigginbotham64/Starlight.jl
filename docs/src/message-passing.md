# Message Passing

We alluded earlier to Starlight's [microkernel](https://en.wikipedia.org/wiki/Microkernel) architecture. This architecture is essentially a combination of Starlight's lifecycle functions and its message passing system.

Returning to our "framework from scratch" narrative, we need a mechanism for telling subsystems what to do. Ideally we wouldn't have them busy-waiting for instructions, and we also want to maintain our mental model of subsystems executing independently of each other (even if running on a single thread). What we're describing is an [event-driven programming model](https://en.wikipedia.org/wiki/Event-driven_programming), and in fact the terms "event handling" and "message passing" are mostly interchangeable in Starlight's vocabulary.

We'll need to manage a set of event handlers for each type of event. These "handlers" might also be called "listeners", and we can start by keeping them in a dictionary:

```julia
const listeners = Dict{DataType, Set{Any}}()
```

Event order may be important, and access to the queue needs to be synchronized since even on a single thread we don't know what order the subsystems will be running in. Julia provides [Channels](https://docs.julialang.org/en/v1/base/parallel/#Channels) for exactly this use case:

```julia
const messages = Channel(Inf)
```

Now we can define simple functions for sending and listening for messages, throwing in a synchronization primitive since we're assuming a parallel environment:

```julia
function sendMessage(m)
  if haskey(listeners, typeof(m))
    put!(messages, m)
  end
end

const listener_lock = ReentrantLock()

function listenFor(e::Any, d::DataType)
  lock(listener_lock)
  if !haskey(listeners, d) listeners[d] = Set{Any}() end
  push!(listeners[d], e)
  unlock(listener_lock)
end

function unlistenFrom(e::Any, d::DataType)
  lock(listener_lock)
  if haskey(listeners, d) delete!(listeners[d], e) end
  unlock(listener_lock)
end
```

...but receiving messages is a little bit trickier. We have listeners, but who tells them about events? Keeping that question in mind, we can write a function to dispatch a single message that can be called from wherever-because-we-don't-know-yet (note the trivial parallelization):

```julia
handleMessage!(l, m) = nothing

function dispatchMessage()
  m = take!(messages)
  d = typeof(m)
  if haskey(listeners, d)
    Threads.@threads for l in Vector([listeners[d]...])
      handleMessage!(l, m)
    end
  end
end
```

...so, in theory, anyone who wants to receive an event could

  1. Define a custom data type
  2. Create an instance of that data type
  3. Call `listenFor` with their instance
  4. Have their `handleMessage!` function invoked automatically when events are processed
  5. Call `unlistenFrom` when finished

This is, in fact, exactly the workflow that subsystems implement in order to process events. Their `awake!` and `shutdown!` functions even provide the perfect opportunity to call `listenFor` and `unlistenFrom` respectively.

But whose job is it to call `dispatchMessage`?

Let's outline some requirements:

  1. Start processing messages when the `App` `awake!`s
  2. Stop processing messages when the `App` `shutdown!`s
  3. Run "in the background" so that it can yield to other processes if there are no messages

Sounds like our event dispatcher needs to run inside a coroutine managed by a subsystem that synchronizes tasks.

But we're not quite there yet. To finally answer the question of what we actually need, we need to ask one further question: what events do the various subsystems listen for? We've assumed that they'll be running continuously, but also responding to events. How do you do both at the same time?

One way is to model the passage of time as an event that subsystems listen for, and fire that event from another coroutine.

For that we could use a `Clock`, which will be the first subsystem we implement.