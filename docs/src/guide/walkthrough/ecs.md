# Entity Component System

An [Entity Component System](https://en.wikipedia.org/wiki/Entity_component_system) (or "ECS" for short) is an in-memory object database where rows are instances and columns are properties. Arbitrary properties can be supported if one or more of the columns contain dictionaries.

Are we going to use database connectors and [ORM](https://en.wikipedia.org/wiki/Object%E2%80%93relational_mapping)? Not exactly, but sort of. We definitely *could* do it that way, but it would be much more difficult to set up. We can achieve a similar effect, however, if we use a [DataFrame](https://dataframes.juliadata.org/stable/), an abstract type, and special methods for `getproperty` and `setproperty!`.

But what attributes is our DataFrame going to have? That depends on what semantics we want our data to have.

GUI applications, including video games, typically arrange objects in a tree, where child nodes move with their parent nodes. So we want to know what a node's local position and rotation are, and what its "absolute" (inherited + local) position and rotation are. We also need to keep track of parent nodes and lists of children. We need to be able to fetch nodes at any time, so being able to look them up by ID will be useful. Keeping track of the node's Julia type and instance will allow us to reuse the property-accessing semantics and apply operations to type-based subsets of nodes. Having a way to distinguish between what's visible in a window and what isn't may be useful. Finally, having a dictionary column will not only allow arbitrary properties, but it will allow users to create arbitrary custom types with appropriate semantics. This will come in handy later. A lot.

Let's start with that abstract type we mentioned. From here on out we're going to start referring to "entities", since they are not only nodes in a tree but also members of an entity component system.

```julia
abstract type Entity end
```

Let's establish what symbolic names we're going to use for our columns:

```julia
const ENT = :ent # entity, the original Julia object instance
const TYPE = :type
const ID = :id
const PARENT = :parent
const CHILDREN = :children
const POSITION = :pos
const ROTATION = :rot
const ABSOLUTE_POSITION = :abs_pos
const ABSOLUTE_ROTATION = :abs_rot
const HIDDEN = :hidden
const PROPS = :props
```

Position and rotation usually have X, Y, and Z components, and it's helpful to be able to refer to those components as properties. We're looking for a better way to do things, but for now the following will suffice:

```julia
mutable struct XYZ
  x::Number
  y::Number
  z::Number
  XYZ(x=0, y=0, z=0) = new(x, y, z)
end

import Base.+, Base.-, Base.*, Base.÷, Base./, Base.%
+(a::XYZ, b::XYZ) = XYZ(a.x+b.x,a.y+b.y,a.z+b.z)
-(a::XYZ, b::XYZ) = XYZ(a.x-b.x,a.y-b.y,a.z-b.z)
*(a::XYZ, b::Number) = XYZ(a.x*b,a.y*b,a.z*b)
÷(a::XYZ, b::Number) = XYZ(a.x÷b,a.y÷b,a.z÷b)
/(a::XYZ, b::Number) = XYZ(a.x/b,a.y/b,a.z/b)
%(a::XYZ, b::Number) = XYZ(a.x%b,a.y%b,a.z%b)
```

Now we can define the types that the columns of our DataFrame will have:

```julia
const components = Dict(
  ENT=>Entity,
  TYPE=>DataType,
  ID=>Number,
  PARENT=>Number,
  CHILDREN=>Set{Number},
  POSITION=>XYZ,
  ROTATION=>XYZ,
  HIDDEN=>Bool,
  PROPS=>Dict{Symbol, Any}
)
```

Now we're almost ready to create our DataFrame. But first, a few more observations. We're still assuming a parallel environment where we don't know what order systems will be running in, so we need to synchronize access to the DataFrame. A simple lock will suffice. The ECS can also be responsible for calling the lifecycle functions of entities, but since these can be added or removed at any time, we need to know whether `awake!` has already been called. Finally, we need to keep track of what IDs are available and in use. A simple integer will do the trick.

With that our DataFrame and ECS struct become surprisingly simple:

```julia
mutable struct ECS
  df::DataFrame
  awoken::Bool
  lock::ReentrantLock
  next_id::Number
  function ECS()
    df = DataFrame(
      NamedTuple{Tuple(keys(components))}(
        t[] for t in values(components)
      ))
    return new(df, false, ReentrantLock(), 0)
  end
end
```

...but don't worry, there's plenty of complexity just around the corner. The reason is that we we're going to be implementing a tree structure on top of this DataFrame. We can now add an `ECS` to our `App`'s constructor...

```julia
...
system!(a, ECS())
...
```

...and the associated helper function...

```julia
ecs() = a.systems[ECS]
```

...but we're not ready to implement the `ECS`'s `awake!` and `shutdown!` just yet. We'll need to have tree traversal in place first, and for that we're going to need some custom iterators. And for that...well, we'll be looking at our entities' parent and children properties, so we'll need to start with getters and setters.

First, some helpers. The names are self-explanatory, but we encourage you to read up on the DataFrames documentation so as to understand what exactly they do.

```julia
# internally using Base.getproperty directly so
# as to not break if the symbol values change
getEntityRow(ent::Entity) = @view ecs().df[getproperty(ecs().df, ENT) .== [ent], :]
function getEntityById(id::Number)
  arr = ecs().df[getproperty(ecs().df, ID) .== [id], ENT]
  if length(arr) > 0
    return arr[1]
  end
  return nothing
end
getEntityRowById(id::Number) = @view ecs().df[getproperty(ecs().df, ID) .== [id], :]
getDfRowProp(r, s) = r[!, s][1]
setDfRowProp!(r, s, x) = r[!, s][1] = x
```

Then a bit more custom-property boilerplate:

```julia
function Base.propertynames(ent::Entity)
  return (
    keys(components)...,
    ABSOLUTE_POSITION,
    ABSOLUTE_ROTATION,
    [n for n in keys(getproperty(ent, PROPS))]...
  )
end

function Base.hasproperty(ent::Entity, s::Symbol)
  return s in Base.propertynames(ent)
end
```

Then the fun part:

```julia
function accumulate_XYZ(r, s)
  acc = XYZ()
  while true
    inc = getDfRowProp(r, s)
    acc += inc
    r = getEntityRowById(getDfRowProp(r, PARENT))
    getDfRowProp(r, PARENT) != 0 || return acc
  end
end

function Base.getproperty(ent::Entity, s::Symbol)
  e = getEntityRow(ent)
  if s == ABSOLUTE_POSITION return accumulate_XYZ(e, POSITION)
  elseif s == ABSOLUTE_ROTATION return accumulate_XYZ(e, ROTATION)
  elseif s in keys(components) return getDfRowProp(e, s)
  elseif s in keys(getDfRowProp(e, PROPS)) return getDfRowProp(e, PROPS)[s]
  else return getfield(ent, s)
  end
end

function Base.setproperty!(ent::Entity, s::Symbol, x)
  e = getEntityRow(ent)
  if s in [
    ENT, # immutable
    TYPE, # automatically set
    ID, # automatically set
    ABSOLUTE_POSITION, # computed
    ABSOLUTE_ROTATION # computed
  ]
    error("cannot set property $(s) on Entity")
  end

  lock(ecs().lock)
  if s == PARENT
    par = getEntityById(getDfRowProp(e, PARENT))
    push!(getproperty(par, CHILDREN), getDfRowProp(e, ID))
  elseif s in keys(components) && s != PROPS
    setDfRowProp!(e, s, x)
  else
    getDfRowProp(e, PROPS)[s] = x
  end
  unlock(ecs().lock)
end
```

We just threw a lot at you. Take some time to digest it before moving on.

We're going to want to use `map` with `awake!` on entities, which means we need a custom iterator type for the `ECS` as well as a `length` function. Since we'll eventually want to iterate multiple different ways, we'll define special iterator types rather than just an iterator for `ECS`. The first one will be `Level`, i.e. traversing nodes by tree level, or in breadth-first order.

This is all we need to make that happen:

```julia
Base.length(e::ECS) = size(e.df)[1]

struct Level end 
Base.length(l::Level) = length(ecs())

mutable struct ECSIteratorState
  root::Number
  q::Queue{Number}
  root_visited::Bool
  index::Number
  ECSIteratorState(; root=0, q=Queue{Number}(), 
  root_visited=false, index=1) = new(root, q, root_visited, index)
end

function Base.iterate(l::Level, state::ECSIteratorState=ECSIteratorState())
  if isempty(state.q)
    if !state.root_visited # just started
      enqueue!(state.q, state.root)
      state.root_visited = true
    else # just finished
      return nothing
    end
  end

  ent = getEntityById(dequeue!(state.q))

  for c in getproperty(ent, CHILDREN) 
    enqueue!(state.q, c)
  end

  return (ent, state)
end
```

Now we can add `awake!` and `shutdown!`:

```julia
function awake!(e::ECS)
  e.awoken = true
  map(awake!, Level())
  listenFor(e, TICK)
end

function shutdown!(e::ECS)
  unlistenFrom(e, TICK)
  map(shutdown!, Level())
  e.awoken = false
end
```

And about that tick handler...having entities that call an update function every frame is a very common use case that we want to support. We could just define tick handlers for all new entity types, but that's a lot of boilerplate and doesn't allow us to ensure that entities are updated in a deterministic order, in case that becomes important. So we have the following:

```julia
update!(e, Δ) = nothing

function handleMessage!(e::ECS, m::TICK)
  map((ent) -> update!(ent, m.Δ), Level()) 
end
```

Now entities can simply define an `update!` method and it will be called every frame deterministically.

So we can work with entities and with the `ECS`, but how do we actually add and remove entities?

We have to handle assigning their ID's, keeping parent and child information updated, and also allow users to define any initial values for custom properties. Notice that we've been assuming that there is a "root" note with an ID of 0. This is the first entity that will be created, and we'll get to it in a moment.

But first, here's how you add a new entity instance to the `ECS`:

```julia
function instantiate!(e::Entity; kw...)
  lock(ecs().lock)

  id = ecs().next_id
  ecs().next_id += 1

  push!(ecs().df, Dict(
    ENT=>e,
    TYPE=>typeof(e),
    ID=>id,
    CHILDREN=>get(kw, CHILDREN, Set{Number}()),
    PARENT=>get(kw, PARENT, 0),
    POSITION=>get(kw, POSITION, XYZ()),
    ROTATION=>get(kw, ROTATION, XYZ()),
    HIDDEN=>get(kw, HIDDEN, false),
    PROPS=>merge(get(kw, PROPS, Dict{Symbol, Any}()), 
      Dict(k=>v for (k,v) in kw if k ∉ 
      [CHILDREN, PARENT, POSITION, ROTATION, HIDDEN, PROPS]))
  ))

  if id != 0
    par = getEntityById(get(kw, PARENT, 0))
    push!(getproperty(par, CHILDREN), id)
  end

  unlock(ecs().lock)

  if ecs().awoken awake!(e) end

  return e
end
```

And here's how you remove them:

```julia
function destroy!(e::Entity)
  shutdown!(e)

  lock(ecs().lock)

  p = getEntityById(getproperty(e, PARENT))

  # if not root
  if getproperty(p, ID) != getproperty(e, ID)
    # update parent
    delete!(getproperty(p, CHILDREN), getproperty(e, ID))
    # update dataframe
    deleteat!(ecs().df, getproperty(ecs().df, ENT) .== [e])
  end

  unlock(ecs().lock)
end

function destroy!(es...)
  map(destroy!, es)
end
```

And now we have a functioning entity component system.

And that's all so far as Starlight's core subsystems go. To do anything meaningful you'll need to hook up a backend for things like input, rendering, and physics, but that will be much easier now that we've established a means to create new subsystems and allow them to communicate and share objects.

This is also the end of the "framework from scratch" narrative. Everything else in the Starlight package is tailored for video games, which may not be your use case. The "framework" as such is pretty much complete at this point.

If you want to make video games or otherwise use Starlight's default backend, Telescope, read on. Otherwise you're better off reading the API docs, or even striking out on your own to extend Starlight for whatever your personal use case is.