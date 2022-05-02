# App Lifecycle

Everything begins with "the app". Your great idea. The grand plan. The next big thing.

Living organisms have a lifecycle. Products have a development lifecycle. Software has a runtime lifecycle.

Your app is going to have a lifecycle. In fact, it's going to have multiple layers of lifecycles. Your framework needs to help you manage all of them.

Let's start with the basics. Apps manage a variety of interlocking components that need to communicate with each other. 

You can imagine having one "master" app managing a variety of "components" or "subsystems", which may be added or removed at random. These subsystems serve different purposes which can be represented by their types, and they manage data which may be contained in their instance.

So we can start with something like the following:

```julia
mutable struct App
  systems::Dict{DataType, Any}
end

system!(a::App, s) = a.systems[typeof(s)] = s
```

This provides us with a simple mechanism to create a master app and add systems to it. But what kind of initialization needs to be performed? And how do you synchronize the initialization of the app with the initialization of the subsystems?

Well, for one thing, we're speaking in terms of a "master" app, so the [singleton pattern](https://en.wikipedia.org/wiki/Singleton_pattern) may be appropriate (see Tom Kwong's [book](https://www.ebooks.com/en-us/book/209928557/hands-on-design-patterns-and-best-practices-with-julia/tom-kwong/) for an explanation of how this works in Julia).

```julia
const app = Ref{App}()
const app_lock = ReentrantLock()

function App()
  global app
  global app_lock
  lock(app_lock)
  if !isassigned(app)
    app[] = new(Dict{DataType, Any}())
  end
  unlock(app_lock)
  return app[]
end
```

Systems may be added or removed at any time, but they all need to be synchronized with the master app. This means we have a second initialization phase, as well as the need for a shutdown phase, and some indication of whether the master app is "running". Having a common subsystem interface for initialization and shutdown would greatly simplify things. 

We can add a field to our `App`, update the constructor, and add a couple of helper functions to get at on/off state:

```julia
mutable struct App
  systems::Dict{DataType, Any}
  running::Bool
end

function App()
  ...
  app[] = new(Dict{DataType, Any}(), false)
  ...
end

on(a::App) = a.running
off(a::App) = !a.running
```

Now we can implement the following `App` lifecycle functions and use them as a starting point for our subsystem lifecycle interface:

```julia
awake!(s) = nothing
shutdown!(s) = nothing

function awake!(a::App)
  if !on(a)
    map(awake!, values(a.systems))
    a.running = true
  end
end

function shutdown!(a::App)
  if !off(a)
    map(shutdown!, values(a.systems))
    a.running = false
  end
end
```

Let's throw in a little helper for use in scripts:

```julia
function run!(a::App)
  awake!(a)
  if !isinteractive()
    while on(a)
      yield()
    end
  end
end
```

We now have a ready-made "destructor" for our `App`, trust us that our lives will be much easier if it gets called automatically:

```julia
function App()
  ...
  app[] = finalizer(shutdown!, 
          new(Dict{DataType, Any}(), false))
  ...
end
```

We can now define subsystems in terms of their `awake!` and `shutdown!` methods and add them to our `App`. We can also access the master `App` by simply calling its constructor with no arguments, i.e. `App()`.

But we have no subsystems, and if they did they wouldn't do anything. Or rather, we have no mechanism for telling them what to do besides turning on and off. Time to fix that.