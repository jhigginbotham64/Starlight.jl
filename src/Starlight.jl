module Starlight

using Reexport
@reexport using Pkg.Artifacts
@reexport using LazyArtifacts
@reexport using Colors
@reexport using SimpleDirectMediaLayer
@reexport using SimpleDirectMediaLayer.LibSDL2
@reexport using Telescope

include("ECS.jl")
include("Drawing.jl")
include("Input.jl")
include("Physics.jl")
include("Entities.jl")

end