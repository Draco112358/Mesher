include("crea_regioni.jl")
include("genera_mesh.jl")
include("find_nodes_ports_or_le.jl")
using GZip, CodecZlib, JSON, Serialization

function doMeshingRis(input::Dict, id, density, freq_max, escal, aws_config, bucket_name)
    try
        bricks = []
        bricks_material = []
        materials = []
        for (index, key) in enumerate(input["bricks"])
            if length(filter(m -> m[:name] == input["bricks"][index]["material"]["name"], materials)) == 0
                push!(materials, Dict(:name => input["bricks"][index]["material"]["name"], :sigmar => input["bricks"][index]["material"]["conductivity"], :eps_re => input["bricks"][index]["material"]["permittivity"], :tan_D => haskey(input["bricks"][index]["material"], "tangent_delta_conductivity") ? input["bricks"][index]["material"]["tangent_delta_conductivity"] : 0.0, :mur => input["bricks"][index]["material"]["permeability"]))
                index_new_material = length(materials)
                for e in input["bricks"][index]["elements"]
                    push!(bricks_material, index_new_material)
                    push!(bricks, e)
                end
            end
        end
        rounded_bricks = zeros(length(bricks), 6)
        for (index, b) in enumerate(bricks)
            rounded_bricks[index, :] .= round.(b, digits=8)
        end
        Regioni = crea_regioni(rounded_bricks, bricks_material, materials)
        #publish_data(Dict("meshingStep" => 1, "id" => id), "mesher_feedback", chan)
        send_rabbitmq_feedback(Dict("meshingStep" => 1, "id" => id), "mesher_feedback")
        println("meshingStep1")
        use_escalings = true
        scalamento = escal
        den = density
        incidence_selection, volumi, superfici, nodi_coord, escalings = genera_mesh(Regioni, den, freq_max, scalamento, use_escalings, materials, id)
        if isnothing(incidence_selection) && isnothing(volumi) && isnothing(superfici) && isnothing(nodi_coord) && isnothing(escalings)
            println("Meshing $(id) interrotta per richiesta stop.")
            return nothing
        end
        println("size A: ", size(incidence_selection[:A]))
        #publish_data(Dict("meshingStep" => 2, "id" => id), "mesher_feedback", chan)
        send_rabbitmq_feedback(Dict("meshingStep" => 2, "id" => id), "mesher_feedback")
        println("meshingStep2")
        result = Dict(
            :mesh => Dict(
                :incidence_selection => incidence_selection,
                :volumi => volumi,
                :nodi_coord => nodi_coord,
                :escalings => escalings
            ),
            :surface => superfici
        )
        # println("result size : ", Base.summarysize(result)/ (1024^2))
        # io = IOBuffer()
        # # Serialize the variable into the IOBuffer.
        # Serialization.serialize(io, result)
        # # Get the bytes from the IOBuffer.
        # data_bytes = take!(io)
        # println("result size : ", Base.summarysize(data_bytes)/ (1024^2))

        # println("volumi size : ", Base.summarysize(volumi)/ (1024^2))
        # println("nodi_coord size : ", Base.summarysize(nodi_coord)/ (1024^2))
        # println("escalings size : ", Base.summarysize(escalings)/ (1024^2))
        # println("superfici size : ", Base.summarysize(superfici)/ (1024^2))

        #publish_data(Dict("compress" => true, "id" => id), "mesher_feedback", chan)
        send_rabbitmq_feedback(Dict("compress" => true, "id" => id), "mesher_feedback")
        (meshPath, surfacePath) = saveOnS3GZippedMeshRis(id, result, aws_config, bucket_name)
        #(meshPath, surfacePath) = saveOnS3MeshRis(id, result, aws_config, bucket_name)
        res = Dict("mesh" => meshPath, "surface" => surfacePath, "id" => id)
        # if !isnothing(chan)
        #     res = Dict("mesh" => meshPath, "surface" => surfacePath, "isValid" => true, "isStopped" => false, "validTopology" => true, "id" => id, "ASize" => [size(incidence_selection[:A])...])
        #     publish_data(res, "mesher_results", chan)
        # end
        res = Dict("mesh" => meshPath, "surface" => surfacePath, "isValid" => true, "isStopped" => false, "validTopology" => true, "id" => id, "ASize" => [size(incidence_selection[:A])...])
        send_rabbitmq_feedback(res, "mesher_results")
    catch e
        if e isa OutOfMemoryError
            res = Dict("mesh" => "", "grids" => "", "isValid" => false, "isStopped" => false, "validTopology" => false, "id" => id, "error" => "out of memory")
            #publish_data(res, "mesher_results", chan)
            send_rabbitmq_feedback(res, "mesher_results")
            # else
            #     res = Dict("mesh" => "", "grids" => "", "isValid" => false, "isStopped" => false, "id" => id, "error" => e)
            #     publish_data(res, "mesher_results", chan)
        end
        println(e)
    finally
        lock(stop_computation_lock) do
            if haskey(stopComputation, id)
                delete!(stopComputation, id)
                println("Flag di stop per meshing $(id) rimosso.")
            end
        end
    end
end


function saveOnS3GZippedMeshRis(fileName::String, data::Dict, aws_config, bucket_name)
    mesh_id = fileName*"_mesh.serialized"
    surface = fileName*"_surface.json.gz"
    if(s3_exists(aws_config, bucket_name, mesh_id))
        s3_delete(aws_config, bucket_name, mesh_id)
    end
    if(s3_exists(aws_config, bucket_name, surface))
        s3_delete(aws_config, bucket_name, surface)
    end
    upload_serialized_data(aws_config, bucket_name, mesh_id, data[:mesh])
    upload_json_gz(aws_config, bucket_name, surface, data[:surface])
    return mesh_id, surface
end
  
function upload_json_gz(aws_config, bucket_name, file_name, data_to_save)
    println("Uploading ", file_name)
    dato_compresso = transcode(GzipCompressor, JSON.json(data_to_save))
    s3_put(aws_config, bucket_name, file_name, dato_compresso)
end

function upload_serialized_data(aws_config, bucket_name, file_name, data_to_save)
    println("Uploading ", file_name)
    io = IOBuffer()
    # Serialize the variable into the IOBuffer.
    Serialization.serialize(io, data_to_save)
    
    # Get the bytes from the IOBuffer.
    data_bytes = take!(io)
    s3_put(aws_config, bucket_name, file_name, data_bytes)
end

function saveOnS3MeshRis(fileName::String, data::Dict, aws_config, bucket_name)
    mesh_id = fileName*"_mesh.json"
    surface = fileName*"_surface.json"
    if(s3_exists(aws_config, bucket_name, mesh_id))
        s3_delete(aws_config, bucket_name, mesh_id)
    end
    if(s3_exists(aws_config, bucket_name, surface))
        s3_delete(aws_config, bucket_name, surface)
    end
    upload_json_data(aws_config, bucket_name, mesh_id, data[:mesh])
    upload_json_data(aws_config, bucket_name, surface, data[:surface])
end

function upload_json_data(aws_config, bucket_name, file_name, data_to_save)
    println("Uploading ", file_name)
    s3_put(aws_config, bucket_name, file_name, JSON.json(data_to_save))
end
# DotEnv.load!()

# aws_access_key_id = ENV["AWS_ACCESS_KEY_ID"]
# aws_secret_access_key = ENV["AWS_SECRET_ACCESS_KEY"]
# aws_region = ENV["AWS_DEFAULT_REGION"]
# aws_bucket_name = ENV["AWS_BUCKET_NAME"]
# creds = AWSCredentials(aws_access_key_id, aws_secret_access_key)
# aws = global_aws_config(; region=aws_region, creds=creds)
# input = get_risGeometry_from_s3(aws, aws_bucket_name, "p4rEB4dKF4p5EoCtr3K9v9.json")
# doMeshingRis(input, "test", aws, aws_bucket_name)

function getBytes(x)
    total = 0;
    fieldNames = fieldnames(typeof(x));
    if fieldNames == []
       return sizeof(x);
    else
      for fieldName in fieldNames
         total += getBytes(getfield(x,fieldName));
      end
      return total;
    end
 end