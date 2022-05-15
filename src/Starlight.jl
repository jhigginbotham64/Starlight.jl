module Starlight

using Reexport
@reexport using Pkg.Artifacts
@reexport using LazyArtifacts
@reexport using Colors
@reexport using DataStructures: DefaultDict
@reexport using Guards
@reexport using SimpleDirectMediaLayer
@reexport using SimpleDirectMediaLayer.LibSDL2
@reexport using Telescope

export awake!, shutdown!

awake!(a) = nothing
shutdown!(a) = nothing

include("EntityComponentSystem.jl")
include("System.jl")
include("App.jl")

include("backends/telescope/Telescope.jl")
