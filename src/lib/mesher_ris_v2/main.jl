include("crea_regioni.jl")
include("genera_mesh.jl")
include("find_nodes_ports_or_le.jl")
using GZip, CodecZlib, JSON

function doMeshingRis(input::Dict, id, density, aws_config, bucket_name; chan=nothing)
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
        rounded_bricks[index, :] .= round.(b, digits=2)
    end
    Regioni = crea_regioni(rounded_bricks, bricks_material, materials)
    publish_data(Dict("meshingStep" => 1, "id" => id), "mesher_feedback", chan)
    println("meshingStep1")
    use_escalings = true
    scalamento = 1e-3
    den = density
    freq_max = 10e9
    incidence_selection, volumi, superfici, nodi_coord, escalings = genera_mesh(Regioni, den, freq_max, scalamento, use_escalings, materials)
    println("size A: ", size(incidence_selection[:A]))
    publish_data(Dict("meshingStep" => 2, "id" => id), "mesher_feedback", chan)
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
    publish_data(Dict("compress" => true, "id" => id), "mesher_feedback", chan)
    (meshPath, surfacePath) = saveOnS3GZippedMeshRis(id, result, aws_config, bucket_name)
    res = Dict("mesh" => meshPath, "surface" => surfacePath, "id" => id)
    if !isnothing(chan)
        res = Dict("mesh" => meshPath, "surface" => surfacePath, "isValid" => true, "isStopped" => false, "validTopology" => true, "id" => id)
        publish_data(res, "mesher_results", chan)
    end
end

function saveOnS3GZippedMeshRis(fileName::String, data::Dict, aws_config, bucket_name)
    mesh_id = fileName*"_mesh.json.gz"
    surface = fileName*"_surface.json.gz"
    if(s3_exists(aws_config, bucket_name, mesh_id))
        s3_delete(aws_config, bucket_name, mesh_id)
    end
    if(s3_exists(aws_config, bucket_name, surface))
        s3_delete(aws_config, bucket_name, surface)
    end
    upload_json_gz(aws_config, bucket_name, mesh_id, data[:mesh])
    upload_json_gz(aws_config, bucket_name, surface, data[:surface])
    return mesh_id, surface
end
  
function upload_json_gz(aws_config, bucket_name, file_name, data_to_save)
    println("Uploading ", file_name)
    dato_compresso = transcode(GzipCompressor, JSON.json(data_to_save))
    s3_put(aws_config, bucket_name, file_name, dato_compresso)
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