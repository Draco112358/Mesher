DotEnv.load!()

aws_access_key_id = ENV["AWS_ACCESS_KEY_ID"]
aws_secret_access_key = ENV["AWS_SECRET_ACCESS_KEY"]
aws_region = ENV["AWS_DEFAULT_REGION"]
aws_bucket_name = ENV["AWS_BUCKET_NAME"]
creds = AWSCredentials(aws_access_key_id, aws_secret_access_key)
aws = global_aws_config(; region=aws_region, creds=creds)

const CORS_HEADERS = [
    "Access-Control-Allow-Origin" => "*",
    "Access-Control-Allow-Headers" => "*",
    "Access-Control-Allow-Methods" => "POST, GET, OPTIONS"
]

# https://juliaweb.github.io/HTTP.jl/stable/examples/#Cors-Server
function CorsMiddleware(handler)
    return function(req::HTTP.Request)
        # determine if this is a pre-flight request from the browser
        if HTTP.method(req)=="OPTIONS"
            return HTTP.Response(200, CORS_HEADERS)  
        else 
            return handler(req) # passes the request to the Application
        end
    end
end

const VIRTUALHOST = "/"
const HOST = "rabbitmq"
const PORT = 5672


# ==============================================================================
# Variabili condivise per lo stato del server e delle simulazioni
# Sarà necessario usare Locks per proteggere l'accesso a queste variabili
# se più thread/tasks le modificano contemporaneamente.
# In questo scenario, le modifiche provengono principalmente dai Tasks delle simulazioni
# e dalle API di Oxygen.
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
        connection(; virtualhost=VIRTUALHOST, host=HOST, port=PORT) do conn
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

function setup_Oxygen_routes()
  @post "/meshing" function(req) 
    try
      req_data = Oxygen.json(req) # Assume JSON body
      project_id = get(req_data, "id", "randomid") # Genera ID se non fornito
      meshing_type = get(req_data, "meshingType", "Strandard") # 'Standard', 'Ris'
      lock(meshing_lock) do
          if haskey(active_meshing, project_id)
              return HTTP.Response(500, CORS_HEADERS)
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
      HTTP.Response(200, CORS_HEADERS)
    catch e 
      println("Errore nell'avvio della meshing: $(e)")
      HTTP.Response(500, CORS_HEADERS)
    end
  end
  @post "/quantumAdvice" function(req) 
    try
      req_data = Oxygen.json(req)
      project_id = get(req_data, "id", "randomid") # Genera ID se non fornito
      Threads.@spawn quantumAdvice(req_data)
      HTTP.Response(200, CORS_HEADERS)
    catch e
      println("Errore nel calcolo del quanto suggerito: $(e)")
      HTTP.Response(500, CORS_HEADERS)
    end
  end
  @post "/getGrids" function(req) 
    try
      req_data = Oxygen.json(req)
      get_grids_from_s3(aws, aws_bucket_name, req_data)
      HTTP.Response(200, CORS_HEADERS)
    catch e
      println("Errore nel recuperare le griglie: $(e)")
      HTTP.Response(500, CORS_HEADERS)
    end
  end
  @post "/stop_computation" function(req)
      meshing_id = queryparams(req)["meshing_id"]
      lock(stop_computation_lock) do
          if haskey(active_meshing, meshing_id)
              if !haskey(stopComputation, meshing_id) # Crea il Ref{Bool} se non esiste
                  stopComputation[meshing_id] = Ref(false)
              end
              stopComputation[meshing_id][] = true # Imposta il flag di stop su true
              println("Richiesta di stop per meshing $(meshing_id) ricevuta. Flag impostato su $(stopComputation[meshing_id][]).")
              
              # Opzionale: Invia un feedback immediato al client via RabbitMQ che la richiesta è stata accettata
              #send_rabbitmq_feedback(Dict("id" => meshing_id, "status" => "stopping", "type" => active_meshing[meshing_id]["type"]), "solver_results")

              return HTTP.Response(200, CORS_HEADERS)
          else
              println("Richiesta di stop per meshing $(meshing_id) ma la meshing non è attiva.")
              return HTTP.Response(500, CORS_HEADERS)
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

function julia_main()
    println("Threads disponibili: ", Threads.nthreads())
    is_building_app = get(ENV, "JULIA_APP_BUILD", "false") == "true"
    if !is_building_app
        send_rabbitmq_feedback(Dict("target" => "mesher", "status" => "starting"), "server_init")
        mesher_overall_status[] = "starting"

        # Precompilazione del solver (se lunga, farla qui prima di servire richieste)
        # force_compile2() # Scommenta se vuoi precompilare all'avvio

        println("Configurazione delle rotte Oxygen...")
        setup_Oxygen_routes()

        println("Avvio del server Oxygen...")
    end

    if !is_building_app
        try
            serve(middleware=[CorsMiddleware],port=8002, host="0.0.0.0", async=true) #con async a true non blocca il thread principale
            # Invia lo stato "ready" dopo aver avviato Oxygen e precompilato
            send_rabbitmq_feedback(Dict("target" => "mesher", "status" => "ready"), "server_init")
            mesher_overall_status[] = "ready"
            while true
                sleep(1)
            end
        catch ex
            if ex isa InterruptException
                println("Server Oxygen interrotto da Ctrl-C.")
            else
                println("Eccezione durante l'esecuzione del server Oxygen: $(ex)")
            end
        finally
            println("Server Oxygen sta per spegnersi. Invio stato 'idle' a RabbitMQ.")
            send_rabbitmq_feedback(Dict("target" => "mesher", "status" => "idle"), "server_init")
            mesher_overall_status[] = "idle"
            exit() # Chiude il processo Julia
        end
    else
        println("Processo di PackageCompiler.jl in corso (generazione output). Il mesher non verrà avviato.")
    end
    
end

# Punto di ingresso principale del tuo server
Base.exit_on_sigint(false) # Non uscire su Ctrl-C immediatamente
try
    julia_main()
catch ex
    if ex isa InterruptException
        println("Catturato Ctrl-C nel blocco principale. Chiusura pulita.")
        if get(ENV, "JULIA_APP_BUILD", "false") != "true"
            send_rabbitmq_feedback(Dict("target" => "mesher", "status" => "idle"), "server_init")
        end
        exit()
    else
        println("Eccezione non gestita nel server principale: $(ex)")
        if get(ENV, "JULIA_APP_BUILD", "false") != "true"
            send_rabbitmq_feedback(Dict("target" => "mesher", "status" => "error", "message" => string(ex)), "server_init")
        end
        exit()
    end
end