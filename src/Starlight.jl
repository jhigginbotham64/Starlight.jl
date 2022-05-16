module Starlight

using Reexport
@reexport using Pkg.Artifacts
@reexport using Distributed
@reexport using LazyArtifacts
@reexport using Colors
@reexport using DataStructures: DefaultDict
@reexport using Actors
@reexport import Actors: spawn, exit!, cast
@reexport using Guards

export awake!, shutdown!

awake!(a) = nothing
shutdown!(a) = nothing

include("EntityComponentSystem.jl")
include("System.jl")
include("App.jl")

include("backends/telescope/Telescope.jl")

end

