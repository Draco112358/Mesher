using JSON, Base.Threads, AMQPClient, AWS, AWSS3, DotEnv
using Genie, Genie.Router, Genie.Renderer.Json, Genie.Requests
# include("lib/saveFiles.jl")
include("lib/mesher2.jl")
include("lib/utility.jl")
include("lib/mesher_ris_v2/main2.jl")

DotEnv.load!()

aws_access_key_id = ENV["AWS_ACCESS_KEY_ID"]
aws_secret_access_key = ENV["AWS_SECRET_ACCESS_KEY"]
aws_region = ENV["AWS_DEFAULT_REGION"]
aws_bucket_name = ENV["AWS_BUCKET_NAME"]
creds = AWSCredentials(aws_access_key_id, aws_secret_access_key)
aws = global_aws_config(; region=aws_region, creds=creds)

Genie.config.run_as_server = true
Genie.config.cors_headers["Access-Control-Allow-Origin"] = "*"
# This has to be this way - you should not include ".../*"
Genie.config.cors_headers["Access-Control-Allow-Headers"] = "Content-Type"
Genie.config.cors_headers["Access-Control-Allow-Methods"] ="GET,POST,PUT,DELETE,OPTIONS" 
Genie.config.cors_allowed_origins = ["*"]

const VIRTUALHOST = "/"
const HOST = "127.0.0.1"


# ==============================================================================
# Variabili condivise per lo stato del server e delle simulazioni
# Sarà necessario usare Locks per proteggere l'accesso a queste variabili
# se più thread/tasks le modificano contemporaneamente.
# In questo scenario, le modifiche provengono principalmente dai Tasks delle simulazioni
# e dalle API di Genie.
# ==============================================================================
const mesher_overall_status = Ref("ready") # ready, busy, error
const active_meshing = Dict{String, Dict{String, Any}}() # ID progetto -> {status, progress, start_time, etc.}
const meshing_lock = ReentrantLock() # Lock per proteggere `active_meshing`
# const stopComputation = []
const stopComputation = Dict{String, Ref{Bool}}() # ID progetto -> Ref{Bool} per il flag di stop
const stop_computation_lock = ReentrantLock() # Aggiungi un lock per proteggere stopComputation
const commentsEnabled = []


function force_compile2()
  println("------ Precompiling routes...wait for mesher to be ready ---------")
  data = open(JSON.parse, "first_run_data.json")
  doMeshing(data, "init", aws, aws_bucket_name)
  println("MESHER READY")
end


function send_rabbitmq_feedback(data::Dict, routing_key::String)
    try
        # 1. Create a connection to RabbitMQ (on-demand)
        connection(; virtualhost=VIRTUALHOST, host=HOST) do conn
            # 2. Create a channel to send messages
            AMQPClient.channel(conn, AMQPClient.UNUSED_CHANNEL, true) do chan
                # 3. Publish the message (make it persistent if it's critical)
                publish_data(data, routing_key, chan)
                println("Feedback RabbitMQ inviato a $(routing_key)")
            end # Channel is closed here
        end # Connection is closed here
    catch e
        println("Errore durante l'invio del feedback RabbitMQ: $(e)")
        # Implementa qui una logica di retry o di logging più sofisticata se necessario
        # (es. scrivere i messaggi non inviati in un log file per ritentarli dopo)
    end
end

# Funzione wrapper per le tue funzioni di meshing originali
# Questa funzione gestirà il ciclo di vita di un'operazione di meshing
# e invierà feedback su RabbitMQ.
function run_meshing_task(
    project_id::String,
    mesher_function::Function, # es. doMeshing, doMeshingRis
    args...; # Argomenti specifici per la funzione mesher
    meshing_type::String
)
    lock(meshing_lock) do
        active_meshing[project_id] = Dict(
            "status" => "running",
            "progress" => 0,
            "start_time" => time(),
            "type" => meshing_type
        )
    end
    #send_rabbitmq_feedback(Dict("id" => project_id, "status" => "running", "type" => meshing_type), "mesher_results")

    try
        # Precompila, se non lo hai già fatto in fase di avvio del server
        # force_compile2() # Potresti volerlo fare una volta all'avvio del server Julia

        # Esegui la Meshing
        # La funzione solver_function DOVRA' essere modificata per accettare
        # un callback o un canale per il progresso, e per i feedback intermedi.
        # Per ora, si assume che pubblichi solo il risultato finale.
        results = mesher_function(args...)

        # Meshing completata
        lock(meshing_lock) do
            active_meshing[project_id]["status"] = "completed"
            active_meshing[project_id]["progress"] = 100
            active_meshing[project_id]["end_time"] = time()
        end
        #send_rabbitmq_feedback(Dict("id" => project_id, "status" => "completed", "type" => meshing_type, "results" => results), "mesher_results")

    catch e
        println("Errore critico nella Meshing $(project_id): $(e)")
        lock(meshing_lock) do
            active_meshing[project_id]["status"] = "failed"
            active_meshing[project_id]["error_message"] = string(e)
            active_meshing[project_id]["end_time"] = time()
        end
        #send_rabbitmq_feedback(Dict("id" => project_id, "status" => "failed", "type" => meshing_type, "message" => string(e)), "mesher_results")
    finally
        # Rimuovi la Meshing dalla lista delle attive dopo un po'
        # o sposta in una lista di "simulate terminate"
        Threads.@spawn begin
            sleep(60) # Mantieni i risultati per 1 minut0
            lock(meshing_lock) do
                if haskey(active_meshing, project_id) && active_meshing[project_id]["status"] in ["completed", "failed"]
                    delete!(active_meshing, project_id)
                    println("Meshing $(project_id) rimossa dalla lista attiva.")
                end
            end
        end
        # Aggiorna lo stato generale del solver se non ci sono altre simulazioni attive
        lock(meshing_lock) do
            if isempty(active_meshing)
                mesher_overall_status[] = "ready"
                send_rabbitmq_feedback(Dict("target" => "solver", "status" => mesher_overall_status[]), "server_init")
            end
        end
    end
end

function setup_genie_routes()
  route("/meshing", method = "POST") do 
    try
      req_data = jsonpayload() # Assume JSON body
      project_id = get(req_data, "id", "randomid") # Genera ID se non fornito
      meshing_type = get(req_data, "meshingType", "Strandard") # 'Standard', 'Ris'
      lock(meshing_lock) do
          if haskey(active_meshing, project_id)
              return JSON.json(Dict("error" => "Meshing con ID $project_id già in corso"))
          end
          active_meshing[project_id] = Dict(
              "status" => "pending",
              "progress" => 0,
              "type" => meshing_type
          )
      end
      if meshing_type == "Standard"
        Threads.@spawn run_meshing_task(
          project_id,
          doMeshing,
          deep_symbolize_keys(req_data),
          project_id,
          aws, aws_bucket_name;
          meshing_type
        )
      end
      if meshing_type == "Ris"
        input = get_risGeometry_from_s3(aws, aws_bucket_name, req_data["fileNameRisGeometry"])
        Threads.@spawn run_meshing_task(
          project_id,
          doMeshingRis,
          input,
          project_id,
          req_data["density"],
          req_data["freqMax"],
          req_data["escal"],
          aws, aws_bucket_name;
          meshing_type
        )
      end
      JSON.json(Dict("message" => "Meshing started", "id" => project_id, "status" => "accepted"))
    catch e 
      println("Errore nell'avvio della meshing: $(e)")
      JSON.json(Dict("error" => "Failed to start meshing: $(e)"))
    end
  end
  route("/quantumAdvice", method = "POST") do 
    try
      req_data = jsonpayload()
      project_id = get(req_data, "id", "randomid") # Genera ID se non fornito
      Threads.@spawn quantumAdvice(req_data)
      JSON.json(Dict("message" => "Compute suggested quantum started", "id" => project_id, "status" => "accepted"))
    catch e
      println("Errore nel calcolo del quanto suggerito: $(e)")
      JSON.json(Dict("error" => "Failed to compute suggested quantum: $(e)"))
    end
  end
  route("/getGrids", method = "POST") do 
    try
      req_data = jsonpayload()
      project_id = get(req_data, "id", "randomid")
      Threads.@spawn get_grids_from_s3(aws, aws_bucket_name, req_data)
      JSON.json(Dict("message" => "get grids started", "id" => project_id, "status" => "accepted"))
    catch e
      println("Errore nel recuperare le griglie: $(e)")
      JSON.json(Dict("error" => "Failed to get grids: $(e)"))
    end
  end
  route("/stop_computation", method = "POST") do
      meshing_id = params(:meshing_id)
      lock(stop_computation_lock) do
          if haskey(active_meshing, meshing_id)
              if !haskey(stopComputation, meshing_id) # Crea il Ref{Bool} se non esiste
                  stopComputation[meshing_id] = Ref(false)
              end
              stopComputation[meshing_id][] = true # Imposta il flag di stop su true
              println("Richiesta di stop per meshing $(meshing_id) ricevuta. Flag impostato su $(stopComputation[meshing_id][]).")
              
              # Opzionale: Invia un feedback immediato al client via RabbitMQ che la richiesta è stata accettata
              #send_rabbitmq_feedback(Dict("id" => meshing_id, "status" => "stopping", "type" => active_meshing[meshing_id]["type"]), "solver_results")

              return JSON.json(Dict("message" => "Stop request for meshing $(meshing_id) acknowledged.", "status" => "stopping"))
          else
              println("Richiesta di stop per meshing $(meshing_id) ma la meshing non è attiva.")
              return JSON.json(Dict("error" => "Meshing $meshing_id not found or already completed/stopped."))
          end
      end
    end
end

function is_stop_requested(meshing_id::String)
    lock(stop_computation_lock) do
        return haskey(stopComputation, meshing_id) && stopComputation[meshing_id][]
    end
end

# ==============================================================================
# Main execution flow
# ==============================================================================

function main()
    # Invia lo stato iniziale del solver tramite RabbitMQ
    send_rabbitmq_feedback(Dict("target" => "mesher", "status" => "starting"), "server_init")
    mesher_overall_status[] = "starting"

    # Precompilazione del solver (se lunga, farla qui prima di servire richieste)
    # force_compile2() # Scommenta se vuoi precompilare all'avvio

    println("Configurazione delle rotte Genie...")
    setup_genie_routes()

    println("Avvio del server Genie...")


    try
        up(8002, async = true) #con async a true non blocca il thread principale
        # Invia lo stato "ready" dopo aver avviato Genie e precompilato
        send_rabbitmq_feedback(Dict("target" => "mesher", "status" => "ready"), "server_init")
        mesher_overall_status[] = "ready"
        while true
          sleep(1)
        end
    catch ex
        if ex isa InterruptException
            println("Server Genie interrotto da Ctrl-C.")
        else
            println("Eccezione durante l'esecuzione del server Genie: $(ex)")
        end
    finally
        println("Server Genie sta per spegnersi. Invio stato 'idle' a RabbitMQ.")
        send_rabbitmq_feedback(Dict("target" => "mesher", "status" => "idle"), "server_init")
        mesher_overall_status[] = "idle"
        exit() # Chiude il processo Julia
    end
end

# Punto di ingresso principale del tuo server
Base.exit_on_sigint(false) # Non uscire su Ctrl-C immediatamente
try
    main()
catch ex
    if ex isa InterruptException
        println("Catturato Ctrl-C nel blocco principale. Chiusura pulita.")
        send_rabbitmq_feedback(Dict("target" => "mesher", "status" => "idle"), "server_init")
        exit()
    else
        println("Eccezione non gestita nel server principale: $(ex)")
        send_rabbitmq_feedback(Dict("target" => "mesher", "status" => "error", "message" => string(ex)), "server_init")
        exit()
    end
end