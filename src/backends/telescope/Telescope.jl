@reexport using SimpleDirectMediaLayer
@reexport using SimpleDirectMediaLayer.LibSDL2
@reexport using Telescope

include("Drawing.jl")
include("Entities.jl")
include("Input.jl")
include("Physics.jl")

"""
  we're getting closer, but no cigar just yet.
  the current single-stage awake/shutdown doesn't
  allow for managing multiple windows, much less
  for intelligently associating resources with 
  different windows. both Starlight's and Telescope's
  API's will need to be revised yet again for this.
"""

# awake!(::Val{:telescope}) = TS_Init()

# shutdown!(::Val{:telescope}) = TS_Quit()