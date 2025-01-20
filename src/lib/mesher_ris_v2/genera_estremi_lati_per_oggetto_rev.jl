function genera_estremi_lati_per_oggetto_rev(lati_per_oggetto_inp, NodiRed, Nodi_i, lato1, lato2, offset)
    numlati = size(lato1, 1)
    latiprec = size(lati_per_oggetto_inp, 1)
    if size(lati_per_oggetto_inp, 1) == 0
        lati_per_oggetto = zeros(numlati, 2)
    else
        lati_per_oggetto = vcat(lati_per_oggetto_inp, zeros(numlati, 2))
    end
    lato = [0, 0]

    for k in 1:numlati
        # Primo estremo
        index = findall(!iszero,
            abs.(lato1[k, 1] .- NodiRed[:, 1]) .<= 1e-8 .&&
            abs.(lato1[k, 2] .- NodiRed[:, 2]) .<= 1e-8 .&&
            abs.(lato1[k, 3] .- NodiRed[:, 3]) .<= 1e-12
        )
        
        if isempty(index)
            index = findall(!iszero,
                abs.(lato1[k, 1] .- Nodi_i[:, 1]) .<= 1e-8 .&&
                abs.(lato1[k, 2] .- Nodi_i[:, 2]) .<= 1e-8 .&&
                abs.(lato1[k, 3] .- Nodi_i[:, 3]) .<= 1e-12
            )
            lato[1] = -index[1]
        else
            lato[1] = index[1] + offset
        end

        # Secondo estremo
        index = findall(!iszero,
            abs.(lato2[k, 1] .- NodiRed[:, 1]) .<= 1e-8 .&&
            abs.(lato2[k, 2] .- NodiRed[:, 2]) .<= 1e-8 .&&
            abs.(lato2[k, 3] .- NodiRed[:, 3]) .<= 1e-12
        )

        if isempty(index)
            index = findall(!iszero,
                abs.(lato2[k, 1] .- Nodi_i[:, 1]) .<= 1e-8 .&&
                abs.(lato2[k, 2] .- Nodi_i[:, 2]) .<= 1e-8 .&&
                abs.(lato2[k, 3] .- Nodi_i[:, 3]) .<= 1e-12
            )
            lato[2] = -index[1]
        else
            lato[2] = index[1] + offset
        end

        lati_per_oggetto[k + latiprec, :] = lato
    end

    return lati_per_oggetto
end
