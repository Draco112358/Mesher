if get(ENV, "CI_COMPILATION", "false") == "true"
    # Non esegue DotEnv.load!()
    println("Ambiente CI rilevato...")
else
    # Esegue DotEnv.load!() (solo in locale)
    DotEnv.load!()
end

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
    return function (req::HTTP.Request)
        # determine if this is a pre-flight request from the browser
        if HTTP.method(req) == "OPTIONS"
            return HTTP.Response(200, CORS_HEADERS)
        else
            return handler(req) # passes the request to the Application
        end
    end
end

const VIRTUALHOST = "/"
#const HOST = "rabbitmq"
const HOST = "127.0.0.1"
const PORT = 5672


# ==============================================================================
# Variabili condivise per lo stato del server e delle simulazioni
# Sarà necessario usare Locks per proteggere l'accesso a queste variabili
# se più thread/tasks le modificano contemporaneamente.
# In questo scenario, le modifiche provengono principalmente dai Tasks delle simulazioni
# e dalle API di Oxygen.
# ==============================================================================
const mesher_overall_status = Ref("ready") # ready, busy, error
const active_meshing = Dict{String,Dict{String,Any}}() # ID progetto -> {status, progress, start_time, etc.}
const meshing_lock = ReentrantLock() # Lock per proteggere `active_meshing`
# const stopComputation = Dict{String,Ref{Bool}}() # Rimosso polling
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

function run_meshing_on_worker(mesher_type::String, args...)
    if mesher_type == "Standard"
        doMeshing(args..., aws, aws_bucket_name)
    elseif mesher_type == "Ris"
        doMeshingRis(args..., aws, aws_bucket_name)
    else
        error("Tipo di meshing sconosciuto: $(mesher_type)")
    end
end

# ==============================================================================
# Spawn di una meshing su un worker Distributed
# ==============================================================================
function spawn_worker_meshing(project_id::String, meshing_type::String, args...)
    # Crea un worker process dedicato
    worker_id = addprocs(1)[1]
    println("Worker $(worker_id) creato per meshing $(project_id)")

    # Carica il modulo Mesher sul worker
    Distributed.remotecall_eval(Main, worker_id, :(using Mesher))

    # Traccia la simulazione
    is_already_stopped = lock(meshing_lock) do
        if haskey(active_meshing, project_id)
            active_meshing[project_id]["worker_id"] = worker_id
            active_meshing[project_id]["status"] = "running"
            active_meshing[project_id]["start_time"] = time()
            active_meshing[project_id]["progress"] = 0
            return get(active_meshing[project_id], "stopped", false)
        end
        return false
    end

    if is_already_stopped
        println("Meshing $(project_id) fermata prima ancora di iniziare. Rimuovo worker $(worker_id).")
        rmprocs(worker_id)
        lock(meshing_lock) do
            if haskey(active_meshing, project_id)
                active_meshing[project_id]["status"] = "stopped"
                active_meshing[project_id]["end_time"] = time()
            end
        end
        # Pulizia accelerata per permettere il riavvio immediato
        Threads.@spawn begin
            sleep(2)
            lock(meshing_lock) do
                if haskey(active_meshing, project_id) && active_meshing[project_id]["status"] == "stopped"
                    delete!(active_meshing, project_id)
                end
            end
        end
        return
    end

    # Lancia la computazione sul worker
    future = remotecall(run_meshing_on_worker, worker_id, meshing_type, args...)

    # Monitora in background
    Threads.@spawn monitor_worker_meshing(project_id, meshing_type, worker_id, future)
end

# ==============================================================================
# Monitoraggio del worker: gestisce completamento, errore, stop
# ==============================================================================
function monitor_worker_meshing(project_id::String, meshing_type::String, worker_id::Int, future::Future)
    try
        fetch(future)
        # Completata con successo
        lock(meshing_lock) do
            if haskey(active_meshing, project_id)
                active_meshing[project_id]["status"] = "completed"
                active_meshing[project_id]["progress"] = 100
                active_meshing[project_id]["end_time"] = time()
            end
        end
    catch e
        was_stopped = lock(meshing_lock) do
            haskey(active_meshing, project_id) && get(active_meshing[project_id], "stopped", false)
        end
        if was_stopped || e isa ProcessExitedException
            lock(meshing_lock) do
                if haskey(active_meshing, project_id)
                    active_meshing[project_id]["status"] = "stopped"
                    active_meshing[project_id]["end_time"] = time()
                end
            end
            println("Meshing $(project_id) fermata dall'utente.")
        else
            println("Errore nella Meshing $(project_id): $(e)")
            lock(meshing_lock) do
                if haskey(active_meshing, project_id)
                    active_meshing[project_id]["status"] = "failed"
                    active_meshing[project_id]["error_message"] = string(e)
                    active_meshing[project_id]["end_time"] = time()
                end
            end
        end
    finally
        # Rimuovi il worker
        try
            rmprocs(worker_id)
            println("Worker $(worker_id) terminato.")
        catch
        end
        # Pulizia dopo un delay
        Threads.@spawn begin
            sleep(60)
            lock(meshing_lock) do
                if haskey(active_meshing, project_id) && active_meshing[project_id]["status"] in ["completed", "failed", "stopped"]
                    delete!(active_meshing, project_id)
                    println("Meshing $(project_id) rimossa dalla lista attiva.")
                end
            end
        end
        # Aggiorna lo stato generale
        lock(meshing_lock) do
            running = any(v -> v["status"] == "running", values(active_meshing))
            if !running
                mesher_overall_status[] = "ready"
                send_rabbitmq_feedback(Dict("target" => "mesher", "status" => mesher_overall_status[]), "server_init")
            end
        end
    end
end

function setup_Oxygen_routes()
    @post "/meshing" function (req)
        try
            req_data = Oxygen.json(req) # Assume JSON body
            project_id = get(req_data, "id", "randomid") # Genera ID se non fornito
            meshing_type = get(req_data, "meshingType", "Strandard") # 'Standard', 'Ris'
            # Utilizzo una variabile per catturare l'errore ed uscire dal lock
            err_response = lock(meshing_lock) do
                if haskey(active_meshing, project_id)
                    status = active_meshing[project_id]["status"]
                    if status in ["running", "pending"]
                        println("Negato avvio meshing $(project_id): già in corso (stato: $(status))")
                        return HTTP.Response(400, CORS_HEADERS, body="Meshing already in progress")
                    end
                end
                active_meshing[project_id] = Dict(
                    "status" => "pending",
                    "progress" => 0,
                    "type" => meshing_type
                )
                return nothing
            end

            if !isnothing(err_response)
                return err_response
            end
            if meshing_type == "Standard"
                spawn_worker_meshing(
                    project_id,
                    "Standard",
                    deep_symbolize_keys(req_data),
                    project_id
                )
            end
            if meshing_type == "Ris"
                input = get_risGeometry_from_s3(aws, aws_bucket_name, req_data["fileNameRisGeometry"])
                spawn_worker_meshing(
                    project_id,
                    "Ris",
                    input,
                    project_id,
                    req_data["density"],
                    req_data["freqMax"],
                    req_data["escal"]
                )
            end
            HTTP.Response(200, CORS_HEADERS)
        catch e
            println("Errore nell'avvio della meshing: $(e)")
            HTTP.Response(500, CORS_HEADERS)
        end
    end
    @post "/quantumAdvice" function (req)
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
    @post "/getGrids" function (req)
        try
            req_data = Oxygen.json(req)
            get_grids_from_s3(aws, aws_bucket_name, req_data)
            HTTP.Response(200, CORS_HEADERS)
        catch e
            println("Errore nel recuperare le griglie: $(e)")
            HTTP.Response(500, CORS_HEADERS)
        end
    end
    @post "/stop_computation" function (req)
        meshing_id = queryparams(req)["meshing_id"]
        worker_id = lock(meshing_lock) do
            if haskey(active_meshing, meshing_id)
                status = active_meshing[meshing_id]["status"]
                if status in ["running", "pending"]
                    active_meshing[meshing_id]["stopped"] = true
                    val = get(active_meshing[meshing_id], "worker_id", nothing)
                    println("Richiesta stop per meshing $(meshing_id) (stato: $(status), worker: $(val))")
                    return val
                end
            end
            return nothing
        end

        if !isnothing(worker_id)
            try
                println("Terminazione worker $(worker_id) per meshing $(meshing_id)...")
                rmprocs(worker_id)
                println("Worker $(worker_id) terminato.")
            catch e
                println("Errore nella terminazione del worker $(worker_id): $(e)")
            end
            return HTTP.Response(200, CORS_HEADERS)
        else
            println("Meshing $(meshing_id) non ancora avviata su un worker o già completata. Flag stop impostato.")
            return HTTP.Response(200, CORS_HEADERS)
        end
    end
end

# Rimosso is_stop_requested - non più usato col sistema process-based

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

    if !is_building_app && myid() == 1
        try
            serve(middleware=[CorsMiddleware], port=8002, host="0.0.0.0", async=true) #con async a true non blocca il thread principale
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