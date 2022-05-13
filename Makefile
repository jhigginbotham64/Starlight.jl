.PHONY: repl clean_docs clean deps docs docs_deploy docs_view test build
SHELL:=/bin/bash

repl:
	julia --project=. -e "import Pkg; Pkg.instantiate(); using Starlight" -i

clean_docs:
	rm -rf docs/build/
	rm -rf docs/site/

clean: clean_docs
	rm -f deps/build.log
	rm -f Manifest.toml
	rm -f */Manifest.toml

# This includes Pkg.resolve() ~ which is ideologically mutually exclusive with
# committing the manifest, as resolve rebuilds the manifest from the project.
# Pkg.develop(Pkg.PackageSpec(path=pwd())) included in docs to add 'this' to it.
deps: clean
	julia -e "import Pkg; Pkg.Registry.update();"
	julia --project=. -e "import Pkg; Pkg.instantiate(); Pkg.resolve(); Pkg.instantiate();"
	julia --project=test -e "import Pkg; Pkg.instantiate(); Pkg.resolve(); Pkg.instantiate();"
	julia --project=docs -e "import Pkg; Pkg.develop(Pkg.PackageSpec(path=pwd())); Pkg.resolve(); Pkg.instantiate();"
	julia --project=docs/view -e "import Pkg; Pkg.instantiate(); Pkg.resolve(); Pkg.instantiate();"

docs: clean_docs
	julia --project=docs -e "using Pkg; Pkg.develop(PackageSpec(path=pwd())); Pkg.resolve(); Pkg.instantiate()"
	julia --project=docs --code-coverage=user docs/make.jl

docs_view: docs
	julia --project=docs/view -e "using LiveServer; serve(dir=\"docs/build\")"

test:
	julia --project=. -e "import Pkg; @time Pkg.precompile(); @time Pkg.test();"
