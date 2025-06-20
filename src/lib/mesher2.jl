include("voxelizator.jl")
include("voxelize_internal.jl")
include("saveFiles.jl")
include("utility.jl")
include("check_topology.jl")
using MeshIO, FileIO, Meshes, MeshBridge, JSON, .SaveData, FLoops, JSON3

function find_mins_maxs(mesh_object::Mesh)
    bb = boundingbox(mesh_object)
    #@assert mesh_object isa Mesh
    minx = coordinates(minimum(bb))[1]
    maxx = coordinates(maximum(bb))[1]
    miny = coordinates(minimum(bb))[2]
    maxy = coordinates(maximum(bb))[2]
    minz = coordinates(minimum(bb))[3]
    maxz = coordinates(maximum(bb))[3]
    return minx, maxx, miny, maxy, minz, maxz
end


function find_box_dimensions(dict_meshes::Dict)
    global_min_x, global_min_y, global_min_z = prevfloat(typemax(Float64)), prevfloat(typemax(Float64)), prevfloat(typemax(Float64))
    global_max_x, global_max_y, global_max_z = -prevfloat(typemax(Float64)), -prevfloat(typemax(Float64)), -prevfloat(typemax(Float64))

    for (key, value) in dict_meshes
        value = value["mesh"]
        #println(dict_meshes)
        minx, maxx, miny, maxy, minz, maxz = find_mins_maxs(value)
        global_min_x = min(global_min_x, minx)
        global_min_y = min(global_min_y, miny)
        global_min_z = min(global_min_z, minz)
        global_max_x = max(global_max_x, maxx)
        global_max_y = max(global_max_y, maxy)
        global_max_z = max(global_max_z, maxz)
    end

    keeper_object = Dict()
    keeper_object["meshXmin"] = global_min_x
    keeper_object["meshXmax"] = global_max_x
    keeper_object["meshYmin"] = global_min_y
    keeper_object["meshYmax"] = global_max_y
    keeper_object["meshZmin"] = global_min_z
    keeper_object["meshZmax"] = global_max_z

    w = keeper_object["meshXmax"] - keeper_object["meshXmin"]
    l = keeper_object["meshYmax"] - keeper_object["meshYmin"]
    h = keeper_object["meshZmax"] - keeper_object["meshZmin"]

    return w, l, h, keeper_object
end


function find_sizes(number_of_cells_x::Int, number_of_cells_y::Int, number_of_cells_z::Int, geometry_descriptor::Dict)

    @assert number_of_cells_x isa Int
    @assert number_of_cells_y isa Int
    @assert number_of_cells_z isa Int
    @assert geometry_descriptor isa Dict
    @assert length(geometry_descriptor) == 6

    # minimum_vertex_coordinates = [geometry_descriptor['meshXmin'] * 1e-3, geometry_descriptor['meshYmin'] * 1e-3,
    #           geometry_descriptor['meshZmin'] * 1e-3]
    # # max_v = [minmax.meshXmax minmax.meshYmax minmax.meshZmax]*1e-3;
    xv = LinRange(geometry_descriptor["meshXmin"] * 1e-3, geometry_descriptor["meshXmax"] * 1e-3,
        number_of_cells_x + 1)
    yv = LinRange(geometry_descriptor["meshYmin"] * 1e-3, geometry_descriptor["meshYmax"] * 1e-3,
        number_of_cells_y + 1)
    zv = LinRange(geometry_descriptor["meshZmin"] * 1e-3, geometry_descriptor["meshZmax"] * 1e-3,
        number_of_cells_z + 1)

    return abs(xv[3] - xv[2]), abs(yv[3] - yv[2]), abs(zv[3] - zv[2])#, minimum_vertex_coordinates
end

function slicematrix(A::AbstractMatrix{T}) where {T}
    m, n = size(A)
    B = Vector{T}[Vector{T}(undef, n) for _ in 1:m]
    for i in 1:m
        B[i] .= A[i, :]
    end
    return B
end

function dump_json_data(filename, o_x::Float64, o_y::Float64, o_z::Float64, cs_x::Float64, cs_y::Float64, cs_z::Float64, nc_x, nc_y, nc_z, matr, id_to_material)

    #print("Serialization to:",filename)
    @assert cs_x isa Float64
    @assert cs_y isa Float64
    @assert cs_z isa Float64
    @assert o_x isa Float64
    @assert o_y isa Float64
    @assert o_z isa Float64

    origin = Dict("origin_x" => o_x, "origin_y" => o_y, "origin_z" => o_z)

    n_cells = Dict("n_cells_x" => convert(Float64, nc_x), "n_cells_y" => convert(Float64, nc_y), "n_cells_z" => convert(Float64, nc_z))

    # Controllare perché è necessaria questa moltiplicazione per 1000.
    cell_size = Dict("cell_size_x" => cs_x * 1000, "cell_size_y" => cs_y * 1000, "cell_size_z" => cs_z * 1000)

    mesher_matrices_dict = Dict()


    for c in range(1, length(id_to_material))
        x = []
        for i in range(1, nc_x)
            push!(x, slicematrix(matr[c, i, :, :]))
        end
        mesher_matrices_dict[id_to_material[c]["material"]] = x

        # for matrix in eachslice(matr2, dims=1)
        #     #@assert count in keys(id_to_material)
        #     println("->")
        #     display(matrix)
        #
        #     #display(mesher_matrices_dict[id_to_material[count]])
        #     #count += 1
        # end
    end

    mats = Dict()
    for (id, m) in id_to_material
        mats[id] = m["material"]
    end


    #@assert count == n_materials+1
    json_dict = Dict("n_materials" => length(id_to_material), "materials" => mats, "origin" => origin, "cell_size" => cell_size, "n_cells" => n_cells, "mesher_matrices" => mesher_matrices_dict)
    # open("copper_loop.json", "w") do f
    #     write(f, JSON.json(json_dict))
    # end
    return json_dict
end

function existsThisBrickWithMaterial(brick_coords::CartesianIndex, mesher_matrices::Dict, material)
    if 1 <= brick_coords[1] <= length(mesher_matrices[material]) &&
       1 <= brick_coords[2] <= length(mesher_matrices[material][brick_coords[1]]) &&
       1 <= brick_coords[3] <= length(mesher_matrices[material][brick_coords[1]][brick_coords[2]])
        return mesher_matrices[material][brick_coords[1]][brick_coords[2]][brick_coords[3]]
    end
    return false
end

function is_brick_valid(brick_coords::CartesianIndex, mesher_matrices::Dict, material)
    brickDown = existsThisBrickWithMaterial(CartesianIndex(brick_coords[1] - 1, brick_coords[2], brick_coords[3]), mesher_matrices, material)
    brickUp = existsThisBrickWithMaterial(CartesianIndex(brick_coords[1] + 1, brick_coords[2], brick_coords[3]), mesher_matrices, material)
    if (!brickDown && !brickUp)
        return Dict("valid" => false, "axis" => "x", "stopped" => false)
    end
    brickDown = existsThisBrickWithMaterial(CartesianIndex(brick_coords[1], brick_coords[2] - 1, brick_coords[3]), mesher_matrices, material)
    brickUp = existsThisBrickWithMaterial(CartesianIndex(brick_coords[1], brick_coords[2] + 1, brick_coords[3]), mesher_matrices, material)
    if (!brickDown && !brickUp)
        return Dict("valid" => false, "axis" => "y", "stopped" => false)
    end
    brickDown = existsThisBrickWithMaterial(CartesianIndex(brick_coords[1], brick_coords[2], brick_coords[3] - 1), mesher_matrices, material)
    brickUp = existsThisBrickWithMaterial(CartesianIndex(brick_coords[1], brick_coords[2], brick_coords[3] + 1), mesher_matrices, material)
    if (!brickDown && !brickUp)
        return Dict("valid" => false, "axis" => "z", "stopped" => false)
    end
    return Dict("valid" => true, "stopped" => false)
end

function is_mesh_valid(mesher_matrices::Dict, id::String; chan=nothing)
    m = collect(keys(mesher_matrices))[1]
    checkLength = length(mesher_matrices[m]) * length(mesher_matrices[m][1]) * length(mesher_matrices[m][1][1]) * length(keys(mesher_matrices))
    if !isnothing(chan)
        publish_data(Dict("length" => checkLength, "id" => id), "mesher_feedback", chan)
    end
    index = 1
    for material in keys(mesher_matrices)
        for brick_coords in CartesianIndices((1:length(mesher_matrices[material]), 1:length(mesher_matrices[material][1]), 1:length(mesher_matrices[material][1][1])))
            if index % ceil(checkLength / 100) == 0
                if !isnothing(chan)
                    publish_data(Dict("index" => index, "id" => id), "mesher_feedback", chan)
                end
            end
            if (mesher_matrices[material][brick_coords[1]][brick_coords[2]][brick_coords[3]])
                brick_valid = is_brick_valid(brick_coords, mesher_matrices, material)
                if (!brick_valid["valid"])
                    return brick_valid
                end
            end
            index += 1
        end
    end
    return Dict("valid" => true)
end

function is_mesh_valid_parallel(mesher_matrices::Dict, id::String)
    connection(; virtualhost=VIRTUALHOST, host=HOST) do conn
        # 2. Create a channel to send messages
        AMQPClient.channel(conn, AMQPClient.UNUSED_CHANNEL, true) do chan
            m = collect(keys(mesher_matrices))[1]
            checkLength = length(mesher_matrices[m]) * length(mesher_matrices[m][1]) * length(mesher_matrices[m][1][1]) * length(keys(mesher_matrices))
            if !isnothing(chan)
                publish_data(Dict("length" => checkLength, "id" => id), "mesher_feedback", chan)
            end
            #send_rabbitmq_feedback(Dict("length" => checkLength, "id" => id), "mesher_feedback")
    
            index = Threads.Atomic{Int64}(1)
            isValid = Threads.Atomic{Int64}(0)
            axis = Threads.Atomic{Int64}(0)
            for material in keys(mesher_matrices)
                if isValid[] > 0
                    break
                end
                if is_stop_requested(id)
                    println("Meshing $(id) interrotta per richiesta stop.")
                    return nothing # O un altro valore che indica interruzione
                end
                @floop for brick_coords in CartesianIndices((1:length(mesher_matrices[material]), 1:length(mesher_matrices[material][1]), 1:length(mesher_matrices[material][1][1])))
                    if isValid[] > 0
                        break
                    end
                    if index[] % ceil(checkLength / 100) in 0:3
                        if !isnothing(chan)
                            publish_data(Dict("index" => index[], "id" => id), "mesher_feedback", chan)
                        end
                    end
                    if (mesher_matrices[material][brick_coords[1]][brick_coords[2]][brick_coords[3]])
                        brick_valid = is_brick_valid(brick_coords, mesher_matrices, material)
                        if (!brick_valid["valid"])
                            if brick_valid["axis"] == "x"
                                Threads.atomic_add!(isValid, 1)
                            elseif brick_valid["axis"] == "y"
                                Threads.atomic_add!(isValid, 2)
                            else
                                Threads.atomic_add!(isValid, 3)
                            end
                            break
                        end
                    end
                    Threads.atomic_add!(index, 1)
                end
            end
            return Dict("valid" => isValid[] == 0, "axis" => isValid[] == 1 ? "x" : (isValid[] == 2 ? "y" : "z"), "stopped" => false)
        end
    end
    
end

function brick_touches_the_main_bounding_box(brick_coords::CartesianIndex, mesher_matrices::Dict, material)::Bool
    Nx = size(mesher_matrices[material], 1)
    Ny = size(mesher_matrices[material], 2)
    Nz = size(mesher_matrices[material], 3)
    if brick_coords[1] == 1 || brick_coords[1] == Nx || brick_coords[2] == 1 || brick_coords[2] == Ny || brick_coords[3] == 1 || brick_coords[3] == Nz
        return true
    end
    return false
end

function existABrickInThisPosition(position_coords::CartesianIndex, mesher_matrices::Dict)::Bool
    for mat in keys(mesher_matrices)
        if (existsThisBrickWithMaterial(position_coords, mesher_matrices, mat))
            return true
        end
    end
    return false
end

function brick_is_on_surface(brick_coords::CartesianIndex, mesher_matrices::Dict, material)::Bool
    if brick_touches_the_main_bounding_box(brick_coords, mesher_matrices, material)
        return true
    end
    if !existABrickInThisPosition(CartesianIndex(brick_coords[1] - 1, brick_coords[2], brick_coords[3]), mesher_matrices)
        return true
    end
    if !existABrickInThisPosition(CartesianIndex(brick_coords[1] + 1, brick_coords[2], brick_coords[3]), mesher_matrices)
        return true
    end
    if !existABrickInThisPosition(CartesianIndex(brick_coords[1], brick_coords[2] - 1, brick_coords[3]), mesher_matrices)
        return true
    end
    if !existABrickInThisPosition(CartesianIndex(brick_coords[1], brick_coords[2] + 1, brick_coords[3]), mesher_matrices)
        return true
    end
    if !existABrickInThisPosition(CartesianIndex(brick_coords[1], brick_coords[2], brick_coords[3] - 1), mesher_matrices)
        return true
    end
    if !existABrickInThisPosition(CartesianIndex(brick_coords[1], brick_coords[2], brick_coords[3] + 1), mesher_matrices)
        return true
    end
    return false
end



function create_grids_externals(grids::Dict, id::String; chan=nothing)
    OUTPUTgrids = Dict()
    m = collect(keys(grids))[1]
    gridsCreationLength = length(grids[m]) * length(grids[m][1]) * length(grids[m][1][1]) * length(keys(grids))
    if !isnothing(chan)
        publish_data(Dict("gridsCreationLength" => gridsCreationLength, "id" => id), "mesher_feedback", chan)
    end
    index = 1
    for (material, mat) in grids
        str = ""
        for cont in CartesianIndices((length(mat), length(mat[1]), length(mat[1][1])))
            # se il brick esiste e si affaccia su una superficie, lo aggiungiamo alla griglia
            if mat[cont[1]][cont[2]][cont[3]]
                if brick_is_on_surface(cont, grids, material)
                    str = str * "$(cont[1])-$(cont[2])-$(cont[3])A"
                end
                if index % ceil(gridsCreationLength / 100) == 0
                    if !isnothing(chan)
                        publish_data(Dict("gridsCreationValue" => index, "id" => id), "mesher_feedback", chan)
                    end
                end
            end
            index += 1
        end
        OUTPUTgrids[material] = str[1:end-1]
    end
    return OUTPUTgrids
end

function create_grids_externals_parallel(grids::Dict, id::String; chan=nothing)
    OUTPUTgrids = Dict()
    index = Threads.Atomic{Int64}(1)
    m = collect(keys(grids))[1]
    gridsCreationLength = length(grids[m]) * length(grids[m][1]) * length(grids[m][1][1]) * length(keys(grids))
    # if !isnothing(chan)
    #     publish_data(Dict("gridsCreationLength" => gridsCreationLength, "id" => id), "mesher_feedback", chan)
    # end
    send_rabbitmq_feedback(Dict("gridsCreationLength" => gridsCreationLength, "id" => id), "mesher_feedback")
    function task_function(chunk, mat, material, gridsCreationLength, index, chan)
        str = ""
        for cont in chunk
            # se il brick esiste e si affaccia su una superficie, lo aggiungiamo alla griglia
            if mat[cont[1]][cont[2]][cont[3]]
                if brick_is_on_surface(cont, grids, material)
                    str = str * "$(cont[1])-$(cont[2])-$(cont[3])A"
                end
                if index[] % ceil(gridsCreationLength / 10) == 0
                    if !isnothing(chan)
                        publish_data(Dict("gridsCreationValue" => index[], "id" => id), "mesher_feedback", chan)
                    end
                end
            end
            Threads.atomic_add!(index, 1)
        end
        return str
    end
    connection(; virtualhost=VIRTUALHOST, host=HOST) do conn
        # 2. Create a channel to send messages
        AMQPClient.channel(conn, AMQPClient.UNUSED_CHANNEL, true) do chan
            for (material, mat) in grids
                if is_stop_requested(id)
                    println("Meshing $(id) interrotta per richiesta stop.")
                    return nothing # O un altro valore che indica interruzione
                end
                cartesian_indices = CartesianIndices((length(mat), length(mat[1]), length(mat[1][1])))
                index_chunks = Iterators.partition(cartesian_indices, length(cartesian_indices) ÷ Threads.nthreads())
                tasks = map(index_chunks) do chunk
                    Threads.@spawn task_function(chunk, mat, material, gridsCreationLength, index, chan)
                end
                chunk_sums = fetch.(tasks)
                OUTPUTgrids[material] = join(chunk_sums)[1:end-1]
            end
        end
    end
    return OUTPUTgrids
end


function doMeshing(dictData::Dict, id::String, aws_config, bucket_name)
    try
        result = Dict()
        meshes = Dict()
        meshes_stl_converted = []
        for geometry in dictData["STLList"]
            #@assert geometry isa Dict
            mesh_id = geometry["material"]["name"]
            mesh_stl = geometry["STL"]
            #@assert mesh_id not in meshes
            open("stl.stl", "w") do write_file
                write(write_file, mesh_stl)
            end
            mesh_stl = load("stl.stl")
            mesh_stl_converted = convert(Meshes.Mesh, mesh_stl)
            push!(meshes_stl_converted, mesh_stl_converted)
            #mesh_stl_converted = Meshes.Polytope(3,3,mesh_stl)
            #@assert mesh_stl_converted isa Mesh
            meshes[mesh_id] = Dict("mesh" => mesh_stl_converted, "conductivity" => geometry["material"]["conductivity"])

            Base.Filesystem.rm("stl.stl", force=true)
        end
        if is_stop_requested(id)
            println("Meshing $(id) interrotta per richiesta stop.")
            return nothing # O un altro valore che indica interruzione
        end

        geometry_x_bound, geometry_y_bound, geometry_z_bound, geometry_data_object = find_box_dimensions(meshes)
        println("meshingStep 1")
        send_rabbitmq_feedback(Dict("meshingStep" => 1, "id" => id), "mesher_feedback")
        #publish_data(Dict("meshingStep" => 1, "id" => id), "mesher_feedback", chan)

        if is_stop_requested(id)
            println("Meshing $(id) interrotta per richiesta stop.")
            return nothing # O un altro valore che indica interruzione
        end

        # grids grainx
        # assert type(dictData['quantum'])==list
        quantum_x, quantum_y, quantum_z = dictData["quantum"]

        # if (geometry_x_bound < quantum_x)
        #     result = Dict("x" => "too large", "max_x" => geometry_x_bound)
        # elseif (geometry_y_bound < quantum_y)
        #     result = Dict("y" => "too large", "max_y" => geometry_y_bound)
        # elseif (geometry_z_bound < quantum_z)
        #     result = Dict("z" => "too large", "max_z" => geometry_z_bound)
        # else
        # quantum_x, quantum_y, quantum_z = 1, 1e-2, 1e-2 #per Test 1
        # # quantum_x, quantum_y, quantum_z = 1e-1, 1, 1e-2  # per Test 2
        # # quantum_x, quantum_y, quantum_z = 1e-1, 1e-1, 1e-2  # per Test 3
        # # quantum_x, quantum_y, quantum_z = 2, 1, 1e-2  # per Test 4
        # # quantum_x, quantum_y, quantum_z = 1, 1, 1e-2  # per Test 5

        #print("QUANTA:",quantum_x, quantum_y, quantum_z)

        n_of_cells_x = ceil(Int, geometry_x_bound / quantum_x)
        n_of_cells_y = ceil(Int, geometry_y_bound / quantum_y)
        n_of_cells_z = ceil(Int, geometry_z_bound / quantum_z)



        #print("GRID:",n_of_cells_x, n_of_cells_y, n_of_cells_z)

        cell_size_x, cell_size_y, cell_size_z = find_sizes(n_of_cells_x, n_of_cells_y, n_of_cells_z, geometry_data_object)
        println("meshingStep 2")
        #publish_data(Dict("meshingStep" => 2, "id" => id), "mesher_feedback", chan)
        send_rabbitmq_feedback(Dict("meshingStep" => 2, "id" => id), "mesher_feedback")
        if is_stop_requested(id)
            println("Meshing $(id) interrotta per richiesta stop.")
            return nothing # O un altro valore che indica interruzione
        end
        #precision = 0.1
        #print("CELL SIZE AFTER ADJUSTEMENTS:",(cell_size_x), (cell_size_y), (cell_size_z))
        # if __debug__:

        #     for size,quantum in zip([cell_size_x,cell_size_y,cell_size_z],[quantum_x,quantum_y,quantum_z]):
        #         print(abs(size*(1/precision) - quantum),precision)
        #         assert abs(size*(1/precision) - quantum)<=precision


        mesher_output = fill(false, (length(dictData["STLList"]), n_of_cells_x, n_of_cells_y, n_of_cells_z))

        if is_stop_requested(id)
            println("Meshing $(id) interrotta per richiesta stop.")
            return nothing # O un altro valore che indica interruzione
        end

        mapping_ids_to_materials = Dict()

        counter_stl_files = 1
        for (material, value) in meshes
            #@assert meshes[mesh_id] isa Mesh
            mesher_output[counter_stl_files, :, :, :] = voxelize(n_of_cells_x, n_of_cells_y, n_of_cells_z, value["mesh"], geometry_data_object)
            #mapping dei materiali su id e impostazione priorità per i conduttori in overlapping.
            mapping_ids_to_materials[counter_stl_files] = Dict("material" => material, "toKeep" => (value["conductivity"] != 0.0) ? true : false)
            counter_stl_files += 1
        end
        println("meshingStep 3")
        send_rabbitmq_feedback(Dict("meshingStep" => 3, "id" => id), "mesher_feedback")
        #publish_data(Dict("meshingStep" => 3, "id" => id), "mesher_feedback", chan)

        if is_stop_requested(id)
            println("Meshing $(id) interrotta per richiesta stop.")
            return nothing # O un altro valore che indica interruzione
        end


        solve_overlapping(n_of_cells_x, n_of_cells_y, n_of_cells_z, mapping_ids_to_materials, mesher_output)
        println("meshingStep 4")
        send_rabbitmq_feedback(Dict("meshingStep" => 4, "id" => id), "mesher_feedback")
        # publish_data(Dict("meshingStep" => 4, "id" => id), "mesher_feedback", chan)
        origin_x = geometry_data_object["meshXmin"] * 1e-3
        origin_y = geometry_data_object["meshYmin"] * 1e-3
        origin_z = geometry_data_object["meshZmin"] * 1e-3


        # assert(isinstance(mesher_output, np.ndarray))
        # @assert cell_size_x isa Float64
        # @assert cell_size_y isa Float64
        # @assert cell_size_z isa Float64
        # @assert origin_x isa Float64
        # @assert origin_y isa Float64
        # @assert origin_z isa Float64

        # Writing to data.json
        json_file_name = "outputMesher.json"
        mesh_result = dump_json_data(json_file_name, origin_x, origin_y, origin_z, cell_size_x, cell_size_y, cell_size_z,
            n_of_cells_x, n_of_cells_y, n_of_cells_z, mesher_output, mapping_ids_to_materials)

        
        if is_stop_requested(id)
            println("Meshing $(id) interrotta per richiesta stop.")
            return nothing # O un altro valore che indica interruzione
        end


        mesh_result["mesh_is_valid"] = is_mesh_valid_parallel(mesh_result["mesher_matrices"], id)

        if is_stop_requested(id) || isnothing(mesh_result["mesh_is_valid"])
            println("Meshing $(id) interrotta per richiesta stop.")
            return nothing # O un altro valore che indica interruzione
        end

        send_rabbitmq_feedback(Dict("gridsCreation" => true, "id" => id), "mesher_feedback")
        #publish_data(Dict("gridsCreation" => true, "id" => id), "mesher_feedback", chan)
        println("create grids")
        externalGrids = Dict()
        if (mesh_result["mesh_is_valid"]["valid"])
            externalGrids = Dict(
                "externalGrids" => create_grids_externals_parallel(mesh_result["mesher_matrices"], id),
                "origin" => "$(mesh_result["origin"]["origin_x"])-$(mesh_result["origin"]["origin_y"])-$(mesh_result["origin"]["origin_z"])",
                "n_cells" => "$(mesh_result["n_cells"]["n_cells_x"])-$(mesh_result["n_cells"]["n_cells_y"])-$(mesh_result["n_cells"]["n_cells_z"])",
                # ricordarsi di dividere per 1000 la cell_size quando la importi su esymia, così che il meshedElement la ridivida, per il solito problema di visualizzazione strano.
                "cell_size" => "$(mesh_result["cell_size"]["cell_size_x"])-$(mesh_result["cell_size"]["cell_size_y"])-$(mesh_result["cell_size"]["cell_size_z"])"
            )
        end
        println("end create grids")

        if is_stop_requested(id) || isnothing(externalGrids["externalGrids"])
            println("Meshing $(id) interrotta per richiesta stop.")
            return nothing # O un altro valore che indica interruzione
        end

        result = Dict("mesh" => mesh_result, "grids" => externalGrids, "isValid" => mesh_result["mesh_is_valid"]["valid"])
        #end
        if result["isValid"] == true
            # (meshPath, gridsPath) = saveGZippedMeshAndPlainGrids(id, result)
            println("compress")
            #publish_data(Dict("compress" => true, "id" => id), "mesher_feedback", chan)
            send_rabbitmq_feedback(Dict("compress" => true, "id" => id), "mesher_feedback")
            (meshPath, gridsPath) = saveOnS3GZippedMeshAndGrids(id, result, aws_config, bucket_name)
            # if !isnothing(chan)
            #     res = Dict("mesh" => meshPath, "grids" => gridsPath, "isValid" => result["mesh"]["mesh_is_valid"], "isStopped" => false, "validTopology" => checkTopology(meshes_stl_converted, mesh_result), "id" => id)
            #     publish_data(res, "mesher_results", chan)
            # end
            res = Dict("mesh" => meshPath, "grids" => gridsPath, "isValid" => result["mesh"]["mesh_is_valid"], "isStopped" => false, "validTopology" => checkTopology(meshes_stl_converted, mesh_result), "id" => id)
            send_rabbitmq_feedback(res, "mesher_results")
        elseif result["isValid"] == false
            # if !isnothing(chan)
            #     res = Dict("mesh" => "", "grids" => "", "isValid" => result["mesh"]["mesh_is_valid"], "isStopped" => result["mesh"]["mesh_is_valid"]["stopped"], "validTopology" => false, "id" => id)
            #     publish_data(res, "mesher_results", chan)
            # end
            res = Dict("mesh" => "", "grids" => "", "isValid" => result["mesh"]["mesh_is_valid"], "isStopped" => result["mesh"]["mesh_is_valid"]["stopped"], "validTopology" => false, "id" => id)
            send_rabbitmq_feedback(res, "mesher_results")
        end
    catch e
        if e isa OutOfMemoryError
            res = Dict("mesh" => "", "grids" => "", "isValid" => false, "isStopped" => false, "validTopology" => false, "id" => id, "error" => "out of memory")
            #publish_data(res, "mesher_results", chan)
            send_rabbitmq_feedback(res, "mesher_results")
            # else
            #     res = Dict("mesh" => "", "grids" => "", "isValid" => false, "isStopped" => false, "id" => id, "error" => e)
            #     publish_data(res, "mesher_results", chan)
        end
    finally
        lock(stop_computation_lock) do
            if haskey(stopComputation, id)
                delete!(stopComputation, id)
                println("Flag di stop per meshing $(id) rimosso.")
            end
        end
    end
end

function quantumAdvice(mesherInput::Dict; chan=nothing)
    meshes = Dict()
    for geometry in Array{Any}(mesherInput["STLList"])
        #@assert geometry isa Dict
        mesh_id = geometry["material"]["name"]
        mesh_stl = geometry["STL"]
        #@assert mesh_id not in meshes
        open("stl.stl", "w") do write_file
            write(write_file, mesh_stl)
        end
        mesh_stl = load("stl.stl")
        mesh_stl_converted = convert(Meshes.Mesh, mesh_stl)
        meshes[mesh_id] = mesh_stl_converted
        Base.Filesystem.rm("stl.stl", force=true)
    end
    q_x = 100
    q_y = 100
    q_z = 100
    for (key, mesh) in meshes
        for c = 1:nelements(mesh)

            #% t1, t2 e t3 sono i vertici di un triangolo
            t1 = coordinates(vertices(mesh[c])[1])
            t2 = coordinates(vertices(mesh[c])[2])
            t3 = coordinates(vertices(mesh[c])[3])

            sx = abs(t1[1] - t2[1])
            if sx > 1e-10 && q_x > sx
                q_x = sx
            end

            sx = abs(t1[1] - t3[1])
            if sx > 1e-10 && q_x > sx
                q_x = sx
            end

            sx = abs(t2[1] - t3[1])
            if sx > 1e-10 && q_x > sx
                q_x = sx
            end

            sy = abs(t1[2] - t2[2])
            if sy > 1e-10 && q_y > sy
                q_y = sy
            end

            sy = abs(t1[2] - t3[2])
            if sy > 1e-10 && q_y > sy
                q_y = sy
            end

            sy = abs(t2[2] - t3[2])
            if sy > 1e-10 && q_y > sy
                q_y = sy
            end

            sz = abs(t1[3] - t2[3])
            if sz > 1e-10 && q_z > sz
                q_z = sz
            end

            sz = abs(t1[3] - t3[3])
            if sz > 1e-10 && q_z > sz
                q_z = sz
            end

            sz = abs(t2[3] - t3[3])
            if sz > 1e-10 && q_z > sz
                q_z = sz
            end

        end

    end
    q_x = 0.5 * q_x
    q_y = 0.5 * q_y
    q_z = 0.5 * q_z

    # if !isnothing(chan)
    #     result = Dict("quantum" => JSON.json([q_x, q_y, q_z]), "id" => mesherInput["id"])
    #     publish_data(result, "mesh_advices", chan)
    # end
    result = Dict("quantum" => JSON.json([q_x, q_y, q_z]), "id" => mesherInput["id"])
    send_rabbitmq_feedback(result, "mesh_advices")
    # return [q_x, q_y, q_z]
end
