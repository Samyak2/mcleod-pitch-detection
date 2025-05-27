using Pkg
Pkg.activate(".")

using PlutoSliderServer

PlutoSliderServer.run_notebook(
    "notebooks/index.jl";
    SliderServer_host="0.0.0.0",
    SliderServer_port=2345,
)
