include("crea_regioni.jl")
include("genera_mesh.jl")
include("find_nodes_ports_or_le.jl")

function doMeshingRis(input::Dict, id, aws_config, bucket_name; chan=nothing)
    bricks = []
    bricks_material = []
    materials = []
    for key in input
        if length(filter!(m -> m[:name] == input[key]["material"]["name"], materials)) == 0
            push!(materials, Dict(:sigmar => input[key]["material"]["conductivity"], :eps_re => input[key]["material"]["permittivity"], :tan_D => haskey(input[key]["material"], "tangent_delta_conductivity") ? input[key]["material"]["tangent_delta_conductivity"] : 0.0, :mur => input[key]["material"]["permeability"]))
            index_new_material = length(materials)
            for e in input[key]["elements"]
                push!(bricks_material, index_new_material)
                push!(bricks, e)
            end
        end
    end
    Regioni = crea_regioni(bricks, bricks_material, materials)
    incidence_selection, volumi, superfici, nodi_coord, escalings = genera_mesh(Regioni, den, freq_max, scalamento, use_escalings)
    publish_data(Dict("mesh completed" => true, "id" => id), "mesher_feedback", chan)
    result = Dict(
        :mesh => Dict(
            :incidence_selection => incidence_selection,
            :volumi => volumi,
            :nodi_coord => nodi_coord,
            :escalings => escalings
        ),
        :surface => superfici
    )
    (meshPath, surfacePath) = saveOnS3GZippedMeshRis(id, result, aws_config, bucket_name)
    if !isnothing(chan)
        res = Dict("mesh" => meshPath, "surface" => surfacePath, "id" => id)
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
    dato_compresso = transcode(GzipCompressor, JSON.json(data_to_save))
    s3_put(aws_config, bucket_name, file_name, dato_compresso)
end

DotEnv.load!()

aws_access_key_id = ENV["AWS_ACCESS_KEY_ID"]
aws_secret_access_key = ENV["AWS_SECRET_ACCESS_KEY"]
aws_region = ENV["AWS_DEFAULT_REGION"]
aws_bucket_name = ENV["AWS_BUCKET_NAME"]
creds = AWSCredentials(aws_access_key_id, aws_secret_access_key)
aws = global_aws_config(; region=aws_region, creds=creds)
input = get_risGeometry_from_s3(aws, aws_bucket_name, "p4rEB4dKF4p5EoCtr3K9v9.json")
doMeshingRis(input, "", aws, aws_bucket_name)