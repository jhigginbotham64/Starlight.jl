using Documenter
using Starlight

makedocs(
    sitename = "Starlight",
    format = Documenter.HTML(),
    modules = [Starlight]
)

# Documenter can also automatically deploy documentation to gh-pages.
# See "Hosting Documentation" and deploydocs() in the Documenter manual
# for more information.
#=deploydocs(
    repo = "<repository url>"
)=#
