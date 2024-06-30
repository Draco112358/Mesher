using Pkg

Pkg.activate(".")
Pkg.instantiate()

include("src/mesher_start.jl")
