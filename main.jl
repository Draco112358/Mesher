using Pkg

Pkg.activate(".")
Pkg.instantiate()

include("src/Mesher.jl")
