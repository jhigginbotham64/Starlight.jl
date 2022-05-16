@reexport using SimpleDirectMediaLayer
@reexport using SimpleDirectMediaLayer.LibSDL2
@reexport using Telescope

include("Drawing.jl")
include("Entities.jl")
include("Input.jl")
include("Physics.jl")

function awake!(::Val{:telescope}, args::Dict{Symbol, Any}) 
  # TS_Init with flags from args
end

function shutdown!(::Val{:telescope}, args::Dict{Symbol, Any}) 
  TS_Quit() # with flags from args
end