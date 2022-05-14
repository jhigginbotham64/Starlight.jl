"""
Main module for Starlight.jl - a greedy framework for greedy developers.

  # Reexports

  - Pkg.Artifacts
  - LazyArtifacts
  - DataStructures: DefaultDict
  - Colors
  - SimpleDirectMediaLayer
  - SimpleDirectMediaLayer.LibSDL2
  - Telescope
"""
module Starlight

using Reexport
@reexport using Pkg.Artifacts
@reexport using LazyArtifacts
@reexport using DataStructures: DefaultDict
@reexport using Colors
@reexport using Guards
@reexport using SimpleDirectMediaLayer
@reexport using SimpleDirectMediaLayer.LibSDL2
@reexport using Telescope

include("Clock.jl")
include("ECS.jl")
include("Drawing.jl")
include("Input.jl")
include("Physics.jl")
include("Entities.jl")

mutable struct App
  
  function App()
    
  end
end


end