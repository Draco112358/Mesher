using Pkg
ENV["JULIA_APP_BUILD"] = "true"
const JULIA_PROJECT_DIR = pwd()
Pkg.activate(JULIA_PROJECT_DIR)
Pkg.instantiate()
using PackageCompiler

 # CAMBIA QUESTO CON IL VERO PERCORSO
const PRECOMPILE_SCRIPT_PATH = joinpath(JULIA_PROJECT_DIR, "precompile_script.jl")
const OUTPUT_APP_DIR = joinpath(JULIA_PROJECT_DIR, "MesherExecutable") # Dove verrà creata la tua app standalone

# ----------------------------------------------------------------------------------
# Crea l'applicazione standalone
# Questa funzione raggruppa l'eseguibile di Julia, la sysimage e le dipendenze.
# create_app(
#     JULIA_PROJECT_DIR,
#     OUTPUT_APP_DIR,
#     precompile_execution_file=PRECOMPILE_SCRIPT_PATH,
#     filter_stdlibs=true, # Rimuove librerie standard non utilizzate per ridurre la dimensione
#     force=true # Sovrascrive la directory di output se esiste già
# )

create_app(
        JULIA_PROJECT_DIR,
        OUTPUT_APP_DIR,
        force=true,
        precompile_execution_file=PRECOMPILE_SCRIPT_PATH,
)

println("Eseguibile Julia creato in: $(OUTPUT_APP_DIR)")

# ----------------------------------------------------------------------------------
# Nel caso in cui volessi creare un azione github per creare l'eseguibile per i diversi sistemi operativi
# .github/workflows/build.yml
# name: Build Executables

# on: [push]

# jobs:
#   build:
#     strategy:
#       matrix:
#         os: [ubuntu-latest, windows-latest, macos-latest]
#     runs-on: ${{ matrix.os }}
    
#     steps:
#       - uses: actions/checkout@v3
#       - uses: julia-actions/setup-julia@v1
#         with:
#           version: '1.11.6'
#       - name: Build executable
#         run: julia scripts/build_executable.jl
#       - name: Upload artifact
#         uses: actions/upload-artifact@v3
#         with:
#           name: mesher-${{ matrix.os }}
#           path: MesherExecutable/
# 
