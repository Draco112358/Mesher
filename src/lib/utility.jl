using AMQPClient, AWSS3, .SaveData

function publish_data(result::Dict, queue::String, chan)
    data = convert(Vector{UInt8}, codeunits(JSON.json(result)))
    message = Message(data, content_type="application/json", delivery_mode=PERSISTENT)
    basic_publish(chan, message; exchange="", routing_key=queue)
end

function is_stopped_computation(id::String, chan)
    if length(filter(i->i==id, stopComputation)) > 0
        filter!(i->i!=id, stopComputation)
        publish_data(Dict("id" => id, "isStopped" => true), "mesher_results", chan)
        return true
    end
    return false
end

function get_grids_from_s3(aws, aws_bucket_name::String, chan, data::Dict)
    if (s3_exists(aws, aws_bucket_name, data["grids_id"]))
        grids = download_json_gz(aws, aws_bucket_name, data["grids_id"])
        result = Dict("grids_id" => data["grids_id"], "grids" => grids, "grids_exist" => true)
      else
        result = Dict("grids_id" => data["grids_id"], "grids" => "", "grids_exist" => false)
      end
      publish_data(result, "mesher_grids", chan)
end