function genera_dati_Z_sup(induttanze)

    associazione = induttanze[:facce_indici_associazione]
    tutte_le_facce = zeros(size(induttanze[:facce_estremi_celle], 1), 6)

    X2 = induttanze[:facce_estremi_celle][:, [1, 4, 7, 10]]
    Y2 = induttanze[:facce_estremi_celle][:, [1, 4, 7, 10] .+ 1]
    Z2 = induttanze[:facce_estremi_celle][:, [1, 4, 7, 10] .+ 2]
    #println("start first parallel loop")
    Threads.@threads for cont in range(1, size(tutte_le_facce, 1))
        tutte_le_facce[cont, :] .= [minimum(X2[cont, :]), maximum(X2[cont, :]), 
                                     minimum(Y2[cont, :]), maximum(Y2[cont, :]),
                                     minimum(Z2[cont, :]), maximum(Z2[cont, :])]
    end

    celle_sup = induttanze[:celle_superficie_estremi_celle]

    X = celle_sup[:, [1, 4, 7, 10]]
    Y = celle_sup[:, [1, 4, 7, 10] .+ 1]
    Z = celle_sup[:, [1, 4, 7, 10] .+ 2]

    N = size(celle_sup, 1)
    M = size(induttanze[:estremi_celle], 1)
    indici_asso_celle_sup = zeros(M, 2)
    #println("start second parallel loop")
    y = zeros(N)
    j = 0
    Threads.@spawn for cont in 1:N
        j += 1
        #println(j)
        cella = [minimum(X[cont, :]), maximum(X[cont, :]),
                minimum(Y[cont, :]), maximum(Y[cont, :]),
                minimum(Z[cont, :]), maximum(Z[cont, :])]
        for x in range(1, size(tutte_le_facce, 1))
            #push!(y, sum(abs.(cella .- tutte_le_facce[x, :]))/12)
            y[cont] = sum(abs.(cella .- tutte_le_facce[x, :]))/12
        end
        lato = findall(!iszero, y .< 1e-8)
        r = findall(!iszero, lato[1] .== associazione)
        idx = r[1][1]
        if !iszero(abs.(indici_asso_celle_sup[idx, 1]) .> 1e-8)
            indici_asso_celle_sup[idx, 2] = cont
        else
            indici_asso_celle_sup[idx, 1] = cont
        end
    end

    induttanze[:Zs_part] = zeros(M)
    #println("start third parallel loop")
    Threads.@threads for cont in 1:M
        if abs.(induttanze[:sigma][cont]) .> 1e-8 && indici_asso_celle_sup[cont, 1] .> 1e-8
            l = induttanze[:celle_superficie_l][Int64(indici_asso_celle_sup[cont, 1])]
            w1 = induttanze[:celle_superficie_w][Int64(indici_asso_celle_sup[cont, 1])]
            
            if abs.(indici_asso_celle_sup[cont, 2]) .> 1e-8
                w2 = induttanze[:celle_superficie_w][Int64(indici_asso_celle_sup[cont, 2])]
                induttanze[:Zs_part][cont] = l / (w1 + w2) * sqrt(4 * π * 1e-7 / induttanze[:sigma][cont])
            else
                induttanze[:Zs_part][cont] = l / w1 * sqrt(4 * π * 1e-7 / induttanze[:sigma][cont])
            end
        end
    end

    return induttanze
end
