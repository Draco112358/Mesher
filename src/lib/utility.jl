function publish_data(result::Dict, queue::String, chan)
    data = convert(Vector{UInt8}, codeunits(JSON.json(result)))
    message = Message(data, content_type="application/json", delivery_mode=PERSISTENT)
    basic_publish(chan, message; exchange="", routing_key=queue)
end

function is_stopped_computation(id::String)
    if length(filter(i->i==id, stopComputation)) > 0
        filter!(i->i!=id, stopComputation)
        return true
    end
    return false
end

function get_grids_from_s3(aws, aws_bucket_name::String, data)
    println(data["grids_id"])
    if (s3_exists(aws, aws_bucket_name, data["grids_id"]))
        grids = download_json_gz(aws, aws_bucket_name, data["grids_id"])
        result = Dict("grids_id" => data["grids_id"], "grids" => grids, "grids_exist" => true, "id" => data["id"])
      else
        result = Dict("grids_id" => data["grids_id"], "grids" => "", "grids_exist" => false, "id" => data["id"])
      end
      #publish_data(result, "mesher_grids", chan)
      send_rabbitmq_feedback(result, "mesher_grids")
end

function get_risGeometry_from_s3(aws, aws_bucket_name::String, fileName::String)
    resposnse_dict = Dict()
    if (s3_exists(aws, aws_bucket_name, fileName))
        response = s3_get(aws, aws_bucket_name, fileName)
        resposnse_dict = to_standard_dict(response)
    end
    return resposnse_dict
end

function to_standard_dict(data)
    if isa(data, OrderedCollections.LittleDict)
        # Convert the LittleDict to Dict, applying the function recursively
        return Dict(k => to_standard_dict(v) for (k, v) in data)
    elseif isa(data, AbstractArray)
        # If it's an array, apply the function to each element
        return map(to_standard_dict, data)
    else
        # For other types, return as is
        return data
    end
end

function deep_symbolize_keys(x)
    if x isa AbstractDict
        # Create a new Dict with Symbol keys and recursively converted values.
        return Dict(String(k) => deep_symbolize_keys(v) for (k, v) in x)
    elseif x isa AbstractVector
        # Recursively process arrays in case they contain dictionaries.
        return [deep_symbolize_keys(item) for item in x]
    else
        # Return any other value unchanged.
        return x
    end
end