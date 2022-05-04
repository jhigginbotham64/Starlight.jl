# API

```@docs
Starlight
```

## Core

### App and Events
```@docs
awake!(::Any)
shutdown!(::Any)
listeners
messages
listener_lock
handleMessage!(::Any, ::Any)
sendMessage(::Any)
listenFor(::Any, ::DataType)
unlistenFrom(::Any, ::DataType)
handleException
dispatchMessage
App
on
off
system!
clk
ecs
inp
ts
phys
scn
systemAwakeOrder
systemShutdownOrder
awake!(::App)
shutdown!(::App)
run!
```

### Clock

```@docs
Clock
TICK
SLEEP_SEC
SLEEP_NSEC
sleep(::SLEEP_SEC)
sleep(::SLEEP_NSEC)
tick
job!
oneshot!
awake!(::Clock)
shutdown!(::Clock)
```

### ECS and Scene

```@docs

```

## Telescope Backend

### Rendering

```@docs

```

### Entities

```@docs

```

### Input

```@docs

```

### Physics

```@docs

```