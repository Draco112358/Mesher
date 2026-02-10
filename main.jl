using Pkg
ENV["JULIA_APP_BUILD"] = "true"
Pkg.activate(".")
Pkg.instantiate()
ENV["JULIA_APP_BUILD"] = "false"

using Mesher
Mesher.julia_main()
