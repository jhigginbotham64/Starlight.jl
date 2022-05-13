using Documenter
using Starlight

makedocs(
    sitename = "Starlight",
    format = Documenter.HTML(prettyurls = !("local" in ARGS)),
    modules = [Starlight],
    strict = true,
    pages = [
      "Home" => "index.md",
      "Guide" => Any[
        "Walkthrough" => Any[
          "guide/walkthrough/intro.md",
          "guide/walkthrough/getting-started.md",
          "guide/walkthrough/app-lifecycle.md",
          "guide/walkthrough/message-passing.md",
          "guide/walkthrough/clock.md",
          "guide/walkthrough/ecs.md"
        ],
        "Telescope" => Any[
          "guide/telescope/intro.md",
          "guide/telescope/rendering.md",
          "guide/telescope/input.md",
          "guide/telescope/physics.md"
        ]
      ],
      "Examples" => Any[
        "examples/pong.md"
      ],
      "API" => "api.md"
    ]
)

# Documenter can also automatically deploy documentation to gh-pages.
# See "Hosting Documentation" and deploydocs() in the Documenter manual
# for more information.
deploydocs(
    repo = "github.com/jhigginbotham64/Starlight.jl.git",
    devbranch = "main"
)
