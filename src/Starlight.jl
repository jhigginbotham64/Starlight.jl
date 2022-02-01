module Starlight

using Reexport
@reexport using Base: ReentrantLock, lock, unlock
@reexport using DataStructures: Queue, enqueue!, dequeue!
@reexport using DataFrames
@reexport using Colors, ColorTypes, ColorVectorSpace
@reexport using SimpleDirectMediaLayer
@reexport using SimpleDirectMediaLayer.LibSDL2

export handleMessage, sendMessage, sendMessageTo, listenFor, listenForFrom, handleException, dispatchMessage
export System, App, awake!, shutdown!, system!, on, off, cat
export app, cfg, str_to_clrnt, get_env_int, get_env_str, get_env_clr, get_env_flt, get_env_bl

import DotEnv
cfg = DotEnv.config()

str_to_clrnt(s) = parse(Colorant, s)
get_env_int(n, d) = parse(Int, get(ENV, n, string(d)))
get_env_str(n, d) = get(ENV, n, string(d)) # no parse necessary since all env variables are strings by default
get_env_clr(n, d) = str_to_clrnt(get(ENV, n, string(d)))
get_env_flt(n, d) = parse(Float64, get(ENV, n, string(d)))
get_env_bl(n, d) = parse(Bool, get(ENV, n, string(d)))

const listeners = Dict{DataType, Set{Any}}()
const messages = Channel(Inf)
const from = Dict{Any, Dict{DataType, Set{Any}}}()

const listener_lock = ReentrantLock()

handleMessage(l, m) = nothing

function sendMessage(m)
  # drop if no one's listening
  if haskey(listeners, typeof(m))
    put!(messages, m)
  end
end

# allow direct invocation of message handlers
# for cases when we know all the recipients in
# advance and there would otherwise be too many
# listeners (i.e. collision notifications)
function sendMessageTo(m, targets...)
  for to in targets handleMessage(to, m) end
end

function add_listener!(e::Any, d::DataType)
  if !haskey(listeners, d) listeners[d] = Set{Any}() end
  push!(listeners[d], e)
end

function listenFor(e::Any, d::DataType)
  lock(listener_lock)
  add_listener!(e, d)
  unlock(listener_lock)
end

# used in cases where we care about the sender
# as well as the message
function listenForFrom(e::Any, d::DataType, e2::Any)
  lock(listener_lock)
  add_listener!(e, d)
  if !haskey(from, e) from[e] = Dict{DataType, Set{Any}}() end
  if !haskey(from[e], d) from[e][d] = Set{Any}() end
  push!(from[e][d], e2)
  unlock(listener_lock)
end

# TODO implement "unlisten" function and test
# NOTE this would only ever be used by the ECS
# when removing an entity, it's too much to ask
# users to write finalizers that do this, i.e.
# this is not terribly important right now

function handleException()
  for s in stacktrace(catch_backtrace())
    println(s)
  end
  rethrow()
end

# uses single argument to support
# being called as a job by a Clock,
# see Clock.jl for that interface
function dispatchMessage(arg)
  try
    m = take!(messages) # NOTE messages are fully processed in the order they are received
    d = typeof(m)
    @debug "dequeued message $(m) of type $(d)"
    if haskey(listeners, d)
      # Threads.@threads doesn't work on raw sets
      # because it needs to use indexing to split
      # up memory, i work around it this way
      Threads.@threads for l in Vector([listeners[d]...])
        # only call handler if the sender is
        # being listened for, i.e. matches one
        # the recipient cares about, or the
        # recipient doesn't care
        if haskey(from, l) && haskey(from[l], d)
          if !hasproperty(m, :from) || m.from ∉ from[l][d]
            continue
          end
        end
        handleMessage(l, m)
      end
    end
  catch
    handleException()
  end
end

abstract type System end

# these functions are supposed to return
# whether a value indicating whether the 
# system is still running or not, except
# for App where it returns a vector of
# booleans indicating whether each system
# is still running
awake!(s::System) = true
shutdown!(s::System) = false

include("Clock.jl")
include("ECS.jl")
include("Entities.jl")
include("Scene.jl")
include("SDL.jl")
# TODO Artifacts/Assets
# TODO Sprites
# TODO Text
# TODO Audio
# TODO Input testing
# TODO game compilation
# TODO 3D drawing
# TODO 3D physics
# TODO 2D physics

mutable struct App <: System
  systems::Dict{DataType, System}
  running::Vector{Bool}
  function App()
    # singleton pattern from Tom Kwong's book
    global app
    global app_lock
    lock(app_lock)
    try 
      if !isassigned(app)

        a = new(Dict(), Vector{Bool}())
        
        system!(a, clk)
        system!(a, ecs)
        system!(a, sdl)
        system!(a, scn)
      
        a.running = [false for s in keys(a.systems)]

        app[] = finalizer(shutdown!, a)

      end

      # clock
      clk.freq = get_env_flt("CLOCK_FREQ", 0.01667) # 60hz
      clk.fire_sec = get_env_bl("CLOCK_FIRE_SEC", false)
      clk.fire_msec = get_env_bl("CLOCK_FIRE_MSEC", false)
      clk.fire_usec = get_env_bl("CLOCK_FIRE_USEC", false)
      clk.fire_nsec = get_env_bl("CLOCK_FIRE_NSEC", false)

      # sdl
      sdl.bgrd = to_ARGB(get_env_clr("BACKGROUND_COLOR", "gray"))
      sdl.wdth = get_env_int("WINDOW_WIDTH", 800)
      sdl.hght = get_env_int("WINDOW_HEIGHT", 400)
      sdl.ttl = get_env_str("TITLE", "Starlight.jl")

    catch e
      rethrow()
    finally
      unlock(app_lock)
      return app[]
    end
  end
end

const app = Ref{App}()
const app_lock = ReentrantLock()

on(a::App) = all(a.running)
off(a::App) = all(!r for r in a.running)
# shrodinger's app is neither on nor off, 
# i.e. some system is not synchronized with the others
cat(a::App) = !on(a) && !off(a)

system!(a::App, s::System) = a.systems[typeof(s)] = s
# note that if running from a script the app will
# still exit when julia exits, it will never block.
# figuring out whether/how to keep it alive is
# on the user.
function awake!(a::App)
  if !on(a)
    job!(a.systems[Clock], dispatchMessage) # this could be parallelized if not for mqueue_lock
    a.running = map(awake!, values(a.systems))
  end
  return a.running
end
function shutdown!(a::App)
  if !off(a)
    a.running = map(shutdown!, values(a.systems))
  end
  return a.running
end

awake!() = awake!(app[])
shutdown!() = shutdown!(app[])

end