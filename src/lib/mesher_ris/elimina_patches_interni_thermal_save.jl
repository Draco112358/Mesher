include("verifica_patches_coincidenti.jl")

function elimina_patches_interni_thermal_save(nodi_centri, nodi_centri_non_rid, nodi_estremi_celle, nodi_epsr, nodi_mur, nodi_sigma, nodi_nodi_i, nodi_w, nodi_l, nodi_S_non_rid, nodi_num_nodi_interni, nodi_normale, Vettaux)
    ncelle_cap = size(nodi_estremi_celle, 1)  # size(nodi_centri, 1)
    ncelle_cap_non_rid = ncelle_cap  # size(nodi_centri_non_rid, 1)
    da_scartare_sup_term = []
    interfacce_cond_diel_mag = []
    da_scartare = []

    if nodi_num_nodi_interni == 0
        nodi_nodi_i = nodi_nodi_i[1:end-1, :]
    end

    for k in 1:ncelle_cap
        n_nodi_coinc = transpose(findall(!iszero,
            abs.(nodi_centri_non_rid[:, 1] .- nodi_centri[k, 1]) .<= 1e-12 .&&
            abs.(nodi_centri_non_rid[:, 2] .- nodi_centri[k, 2]) .<= 1e-12 .&&
            abs.(nodi_centri_non_rid[:, 3] .- nodi_centri[k, 3]) .<= 1e-12
        ))
        
        if !isempty(n_nodi_coinc)
            lN = length(n_nodi_coinc)
            for cont1 in 1:lN
                n = n_nodi_coinc[cont1]
                aux = setdiff(sort(vec(n_nodi_coinc)), [n])
                lM = length(aux)

                for cont2 in 1:lM
                    m = aux[cont2]
                    if verifica_patches_coincidenti(nodi_estremi_celle[[m, n], :])
                        if !(m in da_scartare_sup_term)
                            push!(da_scartare_sup_term, m)  # added for thermal problem
                        end
                        if !(n in da_scartare_sup_term)
                            push!(da_scartare_sup_term, n)  # added for thermal problem
                        end
                        if nodi_epsr[m] == nodi_epsr[n] && nodi_mur[m] == nodi_mur[n]
                            da_scartare = [da_scartare..., setdiff(sort([m, n]), sort(da_scartare))...]
                        else
                            if isempty(interfacce_cond_diel_mag)
                                interfacce_cond_diel_mag = [m n]
                            else
                                app1 = setdiff3([m, n], interfacce_cond_diel_mag)
                                app2 = setdiff3([n, m], interfacce_cond_diel_mag)
                                if app1 == 1 && app2 == 1
                                    interfacce_cond_diel_mag=[interfacce_cond_diel_mag; [m n]]
                                end
                            end
                        end
                    end
                end
            end
        end  # if
    end  # for k

    if !isempty(interfacce_cond_diel_mag)
        #println(interfacce_cond_diel_mag)
        interfacce_cond_diel_mag = interfacce_cond_diel_mag[:, 1]
        da_scartare = [da_scartare..., transpose(interfacce_cond_diel_mag)...]
    end

    da_conservare = setdiff(sort(1:ncelle_cap_non_rid), sort(da_scartare))

    nodi_new_centri = [nodi_centri_non_rid[da_conservare, :]; nodi_nodi_i]
    nodi_new_centri_non_rid = [nodi_centri_non_rid[da_conservare, :]; nodi_nodi_i]
    nodi_new_estremi_celle = nodi_estremi_celle[da_conservare, :]
    nodi_new_w = nodi_w[da_conservare]
    nodi_new_l = nodi_l[da_conservare]
    nodi_new_normale = nodi_normale[da_conservare, :]
    nodi_new_S_non_rid = nodi_S_non_rid[da_conservare]
    nodi_new_sigma = nodi_sigma[da_conservare]
    nodi_new_mur = nodi_mur[da_conservare]
    nodi_new_epsr = nodi_epsr[da_conservare]
    nodi_new_nodi_interni_coordinate = nodi_nodi_i
    nodi_new_num_nodi_interni = nodi_num_nodi_interni
    nodi_new_nodi_esterni = 1:length(da_conservare)

    return nodi_new_centri, nodi_new_centri_non_rid, nodi_new_estremi_celle, nodi_new_w, nodi_new_l, nodi_new_S_non_rid, nodi_new_epsr, nodi_new_sigma, nodi_new_mur, nodi_new_nodi_interni_coordinate, nodi_new_num_nodi_interni, nodi_new_nodi_esterni, nodi_new_normale
end

function setdiff3(m, n)
    app = 1
    for cont in range(1,size(n, 1))
        if isequal(m, n[cont, :])
            app = 0
            break
        end
    end
    return app
end
