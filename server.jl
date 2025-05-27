using Pkg
Pkg.activate(".")

using PlutoSliderServer

PlutoSliderServer.run_notebook("notebooks/index.jl")
