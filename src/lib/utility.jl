using AMQPClient

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