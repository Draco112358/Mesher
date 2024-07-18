using JSON, Base.Threads, AMQPClient, AWS, AWSS3, DotEnv
# include("lib/saveFiles.jl")
include("lib/mesher.jl")
include("lib/utility.jl")

DotEnv.load!()

aws_access_key_id = ENV["AWS_ACCESS_KEY_ID"]
aws_secret_access_key = ENV["AWS_SECRET_ACCESS_KEY"]
aws_region = ENV["AWS_DEFAULT_REGION"]
aws_bucket_name = ENV["AWS_BUCKET_NAME"]
creds = AWSCredentials(aws_access_key_id, aws_secret_access_key)
aws = global_aws_config(; region=aws_region, creds=creds)

const stopComputation = []


function force_compile2()
  println("------ Precompiling routes...wait for mesher to be ready ---------")
  data = open(JSON.parse, "first_run_data.json")
  doMeshing(data, "init", aws, aws_bucket_name)
  println("MESHER READY")
end

const VIRTUALHOST = "/"
const HOST = "127.0.0.1"
const stop_condition = Ref{Float64}(0.0)

function receive()
  # 1. Create a connection to the localhost or 127.0.0.1 of virtualhost '/'
  connection(; virtualhost=VIRTUALHOST, host=HOST) do conn
    # 2. Create a channel to send messages
    AMQPClient.channel(conn, AMQPClient.UNUSED_CHANNEL, true) do chan
      publish_data(Dict("target" => "mesher", "status" => "starting"), "server_init", chan)
      force_compile2()
      # EXCG_DIRECT = "MyDirectExcg"
      # @assert exchange_declare(chan1, EXCG_DIRECT, EXCHANGE_TYPE_DIRECT)
      println(" [*] Waiting for messages. To exit press CTRL+C")
      # 3. Declare a queue
      management_queue = "management"
      #queue_bind(chan, "mesher_results", EXCG_DIRECT, "mesher_results")

      # 4. Setup function to receive message
      on_receive_management = (msg) -> begin
        basic_ack(chan, msg.delivery_tag)
        data = JSON.parse(String(msg.data))
        #data = String(msg.data)
        println(data["message"])
        if (data["message"] == "compute suggested quantum")
          Threads.@spawn quantumAdvice(data["body"]; chan)
          # res = quantumAdvice(data["body"])
          # result = Dict("quantum" => JSON.json(res), "id" => data["body"]["id"])
          # publish_data(result, "mesh_advices", chan)
        elseif data["message"] == "compute mesh"
          Threads.@spawn doMeshing(data["body"], data["body"]["fileName"], aws, aws_bucket_name; chan)
          # result = doMeshing(data["body"], data["body"]["fileName"], chan)
          # if result["isValid"] == true
          #   (meshPath, gridsPath) = saveMeshAndGrids(data["body"]["fileName"], result)
          #   results = Dict("mesh" => meshPath, "grids" => gridsPath, "isValid" => result["mesh"]["mesh_is_valid"], "isStopped" => false, "id" => data["body"]["fileName"])
          #   publish_data(results, "mesher_results", chan)
          # elseif result["isValid"] == false
          #   results = Dict("mesh" => "", "grids" => "", "isValid" => result["mesh"]["mesh_is_valid"], "isStopped" => result["mesh"]["mesh_is_valid"]["stopped"], "id" => data["body"]["fileName"])
          #   publish_data(results, "mesher_results", chan)
          # end
        elseif data["message"] == "stop"
          stop_condition[] = 1.0
        elseif data["message"] == "stop computation"
          push!(stopComputation, data["id"])
        elseif data["message"] == "get grids"
          Threads.@spawn get_grids_from_s3(aws, aws_bucket_name, chan, data)
        end
      end

      # 5. Configure Quality of Service
      basic_qos(chan, 0, 1, false)
      success_management, consumer_tag = basic_consume(chan, management_queue, on_receive_management)

      @assert success_management == true
      publish_data(Dict("target" => "mesher", "status" => "ready"), "server_init", chan)
      while stop_condition[] != 1.0
        sleep(1)
      end
      # 5. Close the connection
      publish_data(Dict("target" => "mesher", "status" => "idle"), "server_init", chan)
      sleep(3)
    end
  end
end


# Don't exit on Ctrl-C
Base.exit_on_sigint(false)
try
  receive()
catch ex
  if ex isa InterruptException
    println("Interrupted")
  else
    println("Exception: $ex")
  end
end