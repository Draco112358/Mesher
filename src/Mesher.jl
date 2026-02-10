module Mesher

using Base.Threads, AMQPClient, AWS, AWSS3, DotEnv, Oxygen, Meshes, GeometryBasics, MeshBridge, FileIO, Distributed
using JSON, FLoops, JSON3, LinearAlgebra, OrderedCollections, SparseArrays, StaticArrays
using GZip, CodecZlib, Serialization, HTTP
include("./lib/utility.jl")
include("./lib/mesher_ris_v2/main2.jl")
include("./lib/voxelizator.jl")
include("./lib/voxelize_internal.jl")
include("./lib/saveFiles.jl")
include("./lib/check_topology.jl")
include("./lib/mesher2.jl")
include("./loadSTL.jl")

include("./lib/mesher_ris_v2/split_overlapping.jl")
include("./lib/mesher_ris_v2/round_ud.jl")
include("./lib/mesher_ris_v2/interpolating_vectors.jl")
include("./lib/mesher_ris_v2/squeeze.jl")
include("./lib/mesher_ris_v2/crea_regioni.jl")
include("./lib/mesher_ris_v2/genera_mesh.jl")
include("./lib/mesher_ris_v2/find_nodes_ports_or_le.jl")
include("./lib/mesher_ris_v2/interpolating_vectors_rev.jl")
include("./lib/mesher_ris_v2/discretizza_thermal_rev.jl")
include("./lib/mesher_ris_v2/matrice_R_rev.jl")
include("./lib/mesher_ris_v2/matrici_selettrici_rev.jl")
include("./lib/mesher_ris_v2/genera_parametri_diel_rec_con_rev.jl")
include("./lib/mesher_ris_v2/mean_length_rev.jl")
include("./lib/mesher_ris_v2/surfa_old.jl")
include("./lib/mesher_ris_v2/mean_length_P.jl")
include("./lib/mesher_ris_v2/mean_length_save.jl")
include("./lib/mesher_ris_v2/mean_cross_section_Lp.jl")
include("./lib/mesher_ris_v2/mean_length_Lp.jl")
include("./lib/mesher_ris_v2/distfcm.jl")
include("./lib/mesher_ris_v2/verifica_patches_coincidenti.jl")
include("./lib/mesher_ris_v2/discr_psp_nono_3D_vol_sup_save.jl")
include("./lib/mesher_ris_v2/genera_nodi_interni_rev.jl")
include("./lib/mesher_ris_v2/genera_nodi_interni_merged_non_ort.jl")
include("./lib/mesher_ris_v2/genera_estremi_lati_per_oggetto_rev.jl")
include("./lib/mesher_ris_v2/elimina_patches_interni_thermal_save.jl")
include("./lib/mesher_ris_v2/FindInternalNodesCommon2FourObjects_rev.jl")
include("./lib/mesher_ris_v2/matrice_incidenza_rev.jl")
include("./lib/mesher_ris_v2/genera_dati_Z_sup.jl")
include("./lib/mesher_ris_v2/genera_celle_capacitive_maglie_save.jl")
include("./lib/mesher_ris_v2/genera_celle_induttive_maglie_save.jl")
include("./lib/mesher_ris_v2/genera_celle_induttive_sup_maglie_save.jl")
include("./lib/mesher_ris_v2/sistema_coordinate.jl")
include("./lib/mesher_ris_v2/solve_overlapping.jl")

include("./mesher_start2.jl")

export julia_main

end # module Mesher
