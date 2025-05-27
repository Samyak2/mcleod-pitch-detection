using Pkg

Pkg.activate(".")
Pkg.instantiate()

using PlutoSliderServer

PlutoSliderServer.run_notebook("notebooks/index.jl")
