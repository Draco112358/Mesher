include("round_ud.jl")
include("squeeze.jl")
include("discr_psp_nono_3D_vol_sup_save.jl")
include("genera_nodi_interni_rev.jl")
include("genera_nodi_interni_merged_non_ort.jl")
include("genera_estremi_lati_per_oggetto_rev.jl")
include("elimina_patches_interni_thermal_save.jl")
include("FindInternalNodesCommon2FourObjects_rev.jl")
include("matrice_incidenza_rev.jl")
include("genera_dati_Z_sup.jl")

function discretizza_thermal_rev(Regioni)
    println("Start discretization")

    weights_five = [0.2369268850, 0.4786286705, 0.5688888889, 0.4786286705, 0.2369268850]
    roots_five = [0.9061798459, 0.5384693101, 0.0, -0.5384693101, -0.9061798459]

    Regioni[:vertici] = zeros(size(Regioni[:coordinate], 1), 8, 3)
    for k = 1:size(Regioni[:coordinate], 1)
        Regioni[:vertici][k, :, :] = [Regioni[:coordinate][k, 1:3];
                                         Regioni[:coordinate][k, 4:6];
                                         Regioni[:coordinate][k, 7:9];
                                         Regioni[:coordinate][k, 10:12];
                                         Regioni[:coordinate][k, 13:15];
                                         Regioni[:coordinate][k, 16:18];
                                         Regioni[:coordinate][k, 19:21];
                                         Regioni[:coordinate][k, 22:24]]
    end

    Regioni[:spigoli] = zeros(size(Regioni[:coordinate], 1), 12, 2, 3)
    for k = 1:size(Regioni[:coordinate], 1)
        Regioni[:spigoli][k, 1, 1, :] .= Regioni[:coordinate][k, 1:3]   # p1-p2
        Regioni[:spigoli][k, 1, 2, :] .= Regioni[:coordinate][k, 4:6]
        Regioni[:spigoli][k, 2, 1, :] .= Regioni[:coordinate][k, 7:9]   # p3-p4
        Regioni[:spigoli][k, 2, 2, :] .= Regioni[:coordinate][k, 10:12]
        Regioni[:spigoli][k, 3, 1, :] .= Regioni[:coordinate][k, 1:3]   # p1-p3
        Regioni[:spigoli][k, 3, 2, :] .= Regioni[:coordinate][k, 7:9]
        Regioni[:spigoli][k, 4, 1, :] .= Regioni[:coordinate][k, 4:6]   # p2-p4
        Regioni[:spigoli][k, 4, 2, :] .= Regioni[:coordinate][k, 10:12]
        Regioni[:spigoli][k, 5, 1, :] .= Regioni[:coordinate][k, 13:15]  # p5-p6
        Regioni[:spigoli][k, 5, 2, :] .= Regioni[:coordinate][k, 16:18]
        Regioni[:spigoli][k, 6, 1, :] .= Regioni[:coordinate][k, 19:21]  # p7-p8
        Regioni[:spigoli][k, 6, 2, :] .= Regioni[:coordinate][k, 22:24]
        Regioni[:spigoli][k, 7, 1, :] .= Regioni[:coordinate][k, 13:15]  # p5-p7
        Regioni[:spigoli][k, 7, 2, :] .= Regioni[:coordinate][k, 19:21]
        Regioni[:spigoli][k, 8, 1, :] .= Regioni[:coordinate][k, 16:18]  # p6-p8
        Regioni[:spigoli][k, 8, 2, :] .= Regioni[:coordinate][k, 22:24]
        Regioni[:spigoli][k, 9, 1, :] .= Regioni[:coordinate][k, 1:3]   # p1-p5
        Regioni[:spigoli][k, 9, 2, :] .= Regioni[:coordinate][k, 13:15]
        Regioni[:spigoli][k, 10, 1, :] .= Regioni[:coordinate][k, 4:6]   # p2-p6
        Regioni[:spigoli][k, 10, 2, :] .= Regioni[:coordinate][k, 16:18]
        Regioni[:spigoli][k, 11, 1, :] .= Regioni[:coordinate][k, 7:9]   # p3-p7
        Regioni[:spigoli][k, 11, 2, :] .= Regioni[:coordinate][k, 19:21]
        Regioni[:spigoli][k, 12, 1, :] .= Regioni[:coordinate][k, 7:9]   # p3-p8
        Regioni[:spigoli][k, 12, 2, :] .= Regioni[:coordinate][k, 22:24]
    end
    
    # Arrays and structs initialization

    celle_mag = []
    barra = []
    nodi = Dict(
        :estremi_celle => [],
        :centri => [],
        :l => [],
        :w => [],
        :S_non_rid => [],
        :nodi_i => [],
        :num_nodi_interni => 0,
        :sigma => [],
        :epsr => [],
        :mur => [],
        :InternalNodesCommon2FourObjects => [],
        :nodi_esterni_coordinate => [],
        :nodi_interni_coordinate => [],
        :num_nodi_esterni => 0,
        :materials => []
    )

    induttanze = Dict(
        :estremi_celle => [],
        :versori => [],
        :coordinate => [],
        :t => [],
        :S => [],
        :l => [],
        :w => [],
        :indici => Dict(:x => [], :y => [], :z => []),
        :dir_curr => [],
        :epsr => [],
        :sigma => [],
        :mu_m => [],
        :mu_m_eq => [],
        :celle_ind_per_oggetto => [],
        :estremi_lati_oggetti => [],
        :Cp => []
    )

    celle_sup = []
    lati1 = []
    lati2 = []
    vers_m = []
    norm_m = []
    NodiRed = []
    l_m = []
    width_m = []
    sup_celle_sup = []
    sigma_c = []
    mu_m=[]
    mu_m_eq=[]
    lati_m = []
    objects = []

    # Superfici celle induttive (sono celle di volume)
    celle_ind_sup = []
    Sup_sup = []
    normale_sup = []
    dir_curr_sup = []
    rc_sup = []
    w_sup = []
    indici_sup = []
    sup_celle_mag=[]

    # Discretizzazione uniforme
    discrUnif = 0
    for k = 1:size(Regioni[:coordinate], 1)
        # Call function to get various variables
        barra_k, celle_cap_k, celle_ind_k, celle_sup_k, lati_k, lati_m_k, vers_k, Nodi_k, spessore_i_k, sup_celle_cap_k, sup_celle_ind_k, sup_celle_sup_k, l_i_k, l_c_k, l_m_k, width_i_k, width_c_k, width_m_k, dir_curr_k, vers_m_k, norm_m_k, celle_ind_sup_k, Sup_sup_k, indici_sup_k, normale_sup_k, dir_curr_sup_k, rc_sup_k, w_sup_k, NodiRed_k = 
            discr_psp_nono_3D_vol_sup_save(Regioni[:coordinate][k, :], Int64(Regioni[:Nx][k]), Int64(Regioni[:Ny][k]), Int64(Regioni[:Nz][k]), discrUnif, weights_five, roots_five)
        
        if k == 1
            #induttanze[:celle_ind_per_oggetto][k] = 1:size(lati_k, 2)
            push!(induttanze[:celle_ind_per_oggetto], 1:size(lati_k, 2))
        else
            #induttanze[:celle_ind_per_oggetto][k] = induttanze[:celle_ind_per_oggetto][k-1][end] + 1 : induttanze[:celle_ind_per_oggetto][k-1][end] + size(lati_k, 2)
            push!(induttanze[:celle_ind_per_oggetto], induttanze[:celle_ind_per_oggetto][k-1][end] + 1 : induttanze[:celle_ind_per_oggetto][k-1][end] + size(lati_k, 2))
        end
    
        # Generate internal nodes
        Nodi_interni = genera_nodi_interni_rev(Regioni[:coordinate][k, :], Regioni[:Nx][k], Regioni[:Ny][k], Regioni[:Nz][k])
        nodi[:num_nodi_interni] += size(Nodi_interni, 1)
        if k == 1
            nodi[:nodi_i] = Nodi_interni
        else
            nodi[:nodi_i] = [nodi[:nodi_i]; Nodi_interni]
        end
        
        
        Nodi_interni_m = genera_nodi_interni_merged_non_ort(Regioni, Nodi_k, k, nodi[:nodi_i])
        
        for conta = range(1, size(celle_ind_k, 1))
            l_i_k[conta], width_i_k[conta], spessore_i_k[conta], sup_celle_ind_k[conta], vers_k[conta, :] = creaVersore(celle_ind_k[conta, :], dir_curr_k[conta])
            
            l_i_k[conta] = round_ud(l_i_k[conta], 12)
            width_i_k[conta] = round_ud(width_i_k[conta], 12)
            spessore_i_k[conta] = round_ud(spessore_i_k[conta], 12)
            sup_celle_ind_k[conta] = round_ud(sup_celle_ind_k[conta], 12)
            vers_k[conta, :] = round_ud(vers_k[conta, :], 12)
        end
        
        nodi[:num_nodi_interni] += size(Nodi_interni_m, 1)
        if k==1
            nodi[:nodi_i] = Nodi_interni_m
            # Append to the main variables
            barra = barra_k
            celle_mag = celle_ind_k
            nodi[:estremi_celle] = celle_cap_k
            induttanze[:estremi_celle] = celle_ind_k
            celle_sup = celle_sup_k
            nodi[:centri] = Nodi_k
            NodiRed = NodiRed_k
            lati1 = squeeze(lati_k[1, :, :])
            lati2 = squeeze(lati_k[2, :, :])
            induttanze[:t] = spessore_i_k
            induttanze[:S] = sup_celle_ind_k
            sup_celle_mag = sup_celle_ind_k
            induttanze[:l] = l_i_k
            nodi[:l] = l_c_k
            l_m = l_m_k
            induttanze[:w] = width_i_k
            nodi[:w] = width_c_k
            width_m = width_m_k
            induttanze[:versori] = vers_k
            vers_m = vers_m_k
            norm_m = norm_m_k
            lati_m = lati_m_k
            nodi[:S_non_rid] = sup_celle_cap_k
            sup_celle_sup = sup_celle_sup_k
            induttanze[:dir_curr] = dir_curr_k
            induttanze[:epsr] = Regioni[:epsr][k] * ones(size(celle_ind_k, 1))
            induttanze[:sigma] = Regioni[:cond][k] * ones(size(celle_ind_k, 1))
            nodi[:sigma] = Regioni[:cond][k] * ones(size(celle_cap_k, 1))
            nodi[:epsr] = Regioni[:epsr][k] * ones(size(celle_cap_k, 1))
            nodi[:materials] = [Regioni[:materials][k] for i in 1:size(celle_cap_k, 1)]
            sigma_c = Regioni[:cond][k] * ones(size(celle_cap_k, 1))
            nodi[:mur] = Regioni[:mur][k] * ones(size(celle_cap_k, 1))
            mu_m_eq = Regioni[:mu][k] * ones(size(celle_sup_k, 1))
            mu_m = Regioni[:mu][k] * ones(size(celle_ind_k, 1))
            objects = k * ones(size(celle_cap_k, 1))
            # Inductive cell surfaces
            celle_ind_sup = celle_ind_sup_k
            Sup_sup = Sup_sup_k
            normale_sup = normale_sup_k
            dir_curr_sup = dir_curr_sup_k
            rc_sup = rc_sup_k
            w_sup = w_sup_k
            indici_sup = indici_sup_k
        else
            nodi[:nodi_i] = [nodi[:nodi_i]; Nodi_interni_m]
            # Append to the main variables
            barra = [barra; barra_k]
            celle_mag = [celle_mag; celle_ind_k]
            nodi[:estremi_celle] = [nodi[:estremi_celle]; celle_cap_k]
            induttanze[:estremi_celle] = [induttanze[:estremi_celle]; celle_ind_k]
            celle_sup = [celle_sup; celle_sup_k]
            nodi[:centri] = [nodi[:centri]; Nodi_k]
            NodiRed = [NodiRed; NodiRed_k]
            lati1 = [lati1; squeeze(lati_k[1, :, :])]
            lati2 = [lati2; squeeze(lati_k[2, :, :])]
            induttanze[:t] = [induttanze[:t]; spessore_i_k]
            induttanze[:S] = [induttanze[:S]; sup_celle_ind_k]
            sup_celle_mag = [sup_celle_mag sup_celle_ind_k]
            induttanze[:l] = [induttanze[:l]; l_i_k]
            nodi[:l] = [nodi[:l]; l_c_k]
            l_m = [l_m l_m_k]
            induttanze[:w] = [induttanze[:w] width_i_k]
            nodi[:w] = [nodi[:w]; width_c_k]
            width_m = [width_m width_m_k]
            induttanze[:versori] = [induttanze[:versori]; vers_k]
            vers_m = [vers_m; vers_m_k]
            norm_m = [norm_m; norm_m_k]
            lati_m = [lati_m lati_m_k]
            nodi[:S_non_rid] = [nodi[:S_non_rid]; sup_celle_cap_k]
            sup_celle_sup = [sup_celle_sup sup_celle_sup_k]
            induttanze[:dir_curr] = [induttanze[:dir_curr]; dir_curr_k]
            induttanze[:epsr] = [induttanze[:epsr]; Regioni[:epsr][k] * ones(size(celle_ind_k, 1))]
            induttanze[:sigma] = [induttanze[:sigma]; Regioni[:cond][k] * ones(size(celle_ind_k, 1))]
            nodi[:sigma] = [nodi[:sigma]; Regioni[:cond][k] * ones(size(celle_cap_k, 1))]
            nodi[:epsr] = [nodi[:epsr]; Regioni[:epsr][k] * ones(size(celle_cap_k, 1))]
            nodi[:materials] = [nodi[:materials]; [Regioni[:materials][k] for i in 1:size(celle_cap_k, 1)]]
            sigma_c = [sigma_c; Regioni[:cond][k] * ones(size(celle_cap_k, 1))]
            nodi[:mur] = [nodi[:mur]; Regioni[:mur][k] * ones(size(celle_cap_k, 1))]
            mu_m_eq = [mu_m_eq; Regioni[:mu][k] * ones(size(celle_sup_k, 1))]
            mu_m = [mu_m; Regioni[:mu][k] * ones(size(celle_ind_k, 1))]
            objects = [objects; k * ones(size(celle_cap_k, 1))]
            # Inductive cell surfaces
            celle_ind_sup = [celle_ind_sup; celle_ind_sup_k]
            Sup_sup = [Sup_sup; Sup_sup_k]
            normale_sup = [normale_sup; normale_sup_k]
            dir_curr_sup = [dir_curr_sup; dir_curr_sup_k]
            rc_sup = [rc_sup; rc_sup_k]
            w_sup = [w_sup; w_sup_k]
            indici_sup = [indici_sup indici_sup_k]
        end
        
        offset = size(NodiRed, 1)
        
        # Update boundary cells
        induttanze[:estremi_lati_oggetti] = genera_estremi_lati_per_oggetto_rev(induttanze[:estremi_lati_oggetti], NodiRed_k, nodi[:nodi_i], squeeze(lati_k[1, :, :]), squeeze(lati_k[2, :, :]), offset)
    end
    # Inductive volume faces
    induttanze[:facce_estremi_celle] = celle_ind_sup
    induttanze[:facce_superfici] = Sup_sup
    induttanze[:facce_normale] = normale_sup
    induttanze[:facce_dir_curr_sup] = dir_curr_sup
    induttanze[:facce_centri] = rc_sup
    induttanze[:facce_w] = w_sup

    offsetNodiInt = size(NodiRed, 1)

    # Update the extreme edges of objects based on coordinates
    index = findall(x -> x < 0, induttanze[:estremi_lati_oggetti][:, 1])
    induttanze[:estremi_lati_oggetti][index, 1] .= abs.(induttanze[:estremi_lati_oggetti][index, 1]) .+ offsetNodiInt

    index = findall(x -> x < 0, induttanze[:estremi_lati_oggetti][:, 2])
    induttanze[:estremi_lati_oggetti][index, 2] .= abs.(induttanze[:estremi_lati_oggetti][index, 2]) .+ offsetNodiInt

    # Set coordinates
    #induttanze[:coordinate][1, :, :] .= lati1
    #induttanze[:coordinate][2, :, :] .= lati2
    push!(induttanze[:coordinate], lati1)
    push!(induttanze[:coordinate], lati2)

    # Find indices based on direction
    induttanze[:indici][:x] = findall(x -> x == 1, induttanze[:dir_curr])
    induttanze[:indici][:y] = findall(x -> x == 2, induttanze[:dir_curr])
    induttanze[:indici][:z] = findall(x -> x == 3, induttanze[:dir_curr])
    # Calculate centers
    induttanze[:centri] = hcat(
        sum(induttanze[:estremi_celle][:, 1:3:24], dims=2) / 8,
        sum(induttanze[:estremi_celle][:, 2:3:24], dims=2) / 8,
        sum(induttanze[:estremi_celle][:, 3:3:24], dims=2) / 8
    )


    # Define internal nodes
    nodi[:nodi_interni] = size(nodi[:centri], 1) - nodi[:num_nodi_interni] + 1 : size(nodi[:centri], 1)

    # Transpose length
    nodi[:l] = transpose(nodi[:l])
    nodi[:potenziali] = []

    # Non-reduced centers and normal vectors
    nodi[:centri_non_rid] = nodi[:centri]
    a = nodi[:estremi_celle][:, 4:6] .- nodi[:estremi_celle][:, 1:3]
    b = nodi[:estremi_celle][:, 7:9] .- nodi[:estremi_celle][:, 1:3]
    C = zeros(size(a))
    for i in range(1, size(a,1))
        C[ i, :] = cross(a[i, :], b[i, :])
    end
    nodi[:normale] = C
    nodi[:normale] .= nodi[:normale] .÷ sqrt.(nodi[:normale][:, 1].^2 .+ nodi[:normale][:, 2].^2 .+ nodi[:normale][:, 3].^2)

    # If no internal nodes, initialize with zeros
    if nodi[:num_nodi_interni] == 0
        nodi[:nodi_i] = zeros(1, 3)
    end

    # Call function to remove internal patches
    nodi[:centri], nodi[:centri_non_rid], nodi[:estremi_celle], nodi[:w], nodi[:l], nodi[:S_non_rid], nodi[:epsr], nodi[:materials], nodi[:sigma], nodi[:mur], nodi[:nodi_interni_coordinate], nodi[:num_nodi_interni], nodi[:nodi_esterni], nodi[:normale] = 
        elimina_patches_interni_thermal_save(
            nodi[:centri], nodi[:centri_non_rid], nodi[:estremi_celle], nodi[:epsr], nodi[:materials], nodi[:mur], nodi[:sigma], nodi[:nodi_i], nodi[:w], nodi[:l], nodi[:S_non_rid], nodi[:num_nodi_interni], nodi[:normale], 1
        )
    # If no internal nodes, clear internal nodes
    if nodi[:num_nodi_interni] == 0
        nodi[:nodi_i] = []
    end

    # Find common internal nodes between 4 objects
    InternalNodesCommon2FourObjects = FindInternalNodesCommon2FourObjects_rev(nodi[:centri], NodiRed)
    # Update center and external/internal nodes
    nodi[:centri_sup_non_rid] = nodi[:centri]
    nodi[:InternalNodesCommon2FourObjects] = InternalNodesCommon2FourObjects
    if length(InternalNodesCommon2FourObjects) != 0
        nodi[:centri] = [nodi[:centri]; InternalNodesCommon2FourObjects]
        nodi[:nodi_esterni_coordinate] = [NodiRed; nodi[:InternalNodesCommon2FourObjects]]
        nodi[:nodi_interni_coordinate] = [nodi[:nodi_interni_coordinate]; nodi[:InternalNodesCommon2FourObjects]]
    else
        nodi[:nodi_esterni_coordinate] = NodiRed
    end
    # Update the number of external and internal nodes
    nodi[:num_nodi_esterni] = size(nodi[:nodi_esterni_coordinate], 1)
    nodi[:num_nodi_interni] += size(InternalNodesCommon2FourObjects, 1)

    # Compute incidence matrix and other data
    induttanze[:estremi_lati], nodi[:Rv], nodi[:centri], 
    A = matrice_incidenza_rev(induttanze[:coordinate], nodi[:centri], nodi[:nodi_interni_coordinate])
    # Update indices based on epsr
    indexes = findall(x -> x > 1, induttanze[:epsr])
    induttanze[:indici_Nd] = indexes

    # Compute surfaces
    nodi[:superfici] = nodi[:l] .* nodi[:w]

    # Update surface properties
    induttanze[:celle_superficie_w] = width_m
    induttanze[:celle_superficie_l] = l_m
    induttanze[:celle_superficie_estremi_celle] = celle_sup

    # Assign face indices for association
    induttanze[:facce_indici_associazione] = zeros(Int, size(A, 1), 6)
    for cont in 1:size(A, 1)
        induttanze[:facce_indici_associazione][cont, :] .= ((cont - 1) * 6 + 1):(cont * 6)
    end

    # Call function to generate data for inductive surfaces
    induttanze = genera_dati_Z_sup(induttanze)

    dump(nodi[:materials])

    println("End discretization")
    return induttanze, nodi, A
end

function creaVersore(barra, dir_curr)
    if dir_curr == 1
        x1 = 1/4 * sum(barra[[1, 7, 13, 19]])
        x2 = 1/4 * sum(barra[[4, 10, 16, 22]])
        y1 = 1/4 * sum(barra[[2, 8, 14, 20]])
        y2 = 1/4 * sum(barra[[5, 11, 17, 23]])
        z1 = 1/4 * sum(barra[[3, 9, 15, 21]])
        z2 = 1/4 * sum(barra[[6, 12, 18, 24]])

        v1 = [x1 y1 z1]
        v2 = [x2 y2 z2]

        vers = (v2 - v1) ./ norm(v2 - v1, 2)
        l = norm(v2 - v1, 2)

        x1 = 1/4 * sum(barra[[1, 4, 13, 16]])
        x2 = 1/4 * sum(barra[[7, 10, 19, 22]])
        y1 = 1/4 * sum(barra[[2, 5, 14, 17]])
        y2 = 1/4 * sum(barra[[8, 11, 20, 23]])
        z1 = 1/4 * sum(barra[[3, 6, 15, 18]])
        z2 = 1/4 * sum(barra[[9, 12, 21, 24]])

        v1 = [x1 y1 z1]
        v2 = [x2 y2 z2]

        w = norm(v2 - v1, 2)

        x1 = 1/4 * sum(barra[[1, 4, 7, 10]])
        x2 = 1/4 * sum(barra[[13, 16, 19, 22]])
        y1 = 1/4 * sum(barra[[2, 5, 8, 11]])
        y2 = 1/4 * sum(barra[[14, 17, 20, 23]])
        z1 = 1/4 * sum(barra[[3, 6, 9, 12]])
        z2 = 1/4 * sum(barra[[15, 18, 21, 24]])

        v1 = [x1 y1 z1]
        v2 = [x2 y2 z2]

        t = norm(v2 - v1, 2)
        S = w * t

    elseif dir_curr == 2
        x1 = 1/4 * sum(barra[[1, 7, 13, 19]])
        x2 = 1/4 * sum(barra[[4, 10, 16, 22]])
        y1 = 1/4 * sum(barra[[2, 8, 14, 20]])
        y2 = 1/4 * sum(barra[[5, 11, 17, 23]])
        z1 = 1/4 * sum(barra[[3, 9, 15, 21]])
        z2 = 1/4 * sum(barra[[6, 12, 18, 24]])

        v1 = [x1 y1 z1]
        v2 = [x2 y2 z2]

        t = norm(v2 - v1, 2)

        x1 = 1/4 * sum(barra[[1, 4, 13, 16]])
        x2 = 1/4 * sum(barra[[7, 10, 19, 22]])
        y1 = 1/4 * sum(barra[[2, 5, 14, 17]])
        y2 = 1/4 * sum(barra[[8, 11, 20, 23]])
        z1 = 1/4 * sum(barra[[3, 6, 15, 18]])
        z2 = 1/4 * sum(barra[[9, 12, 21, 24]])

        v1 = [x1 y1 z1]
        v2 = [x2 y2 z2]

        vers = (v2 - v1) ./ norm(v2 - v1, 2)
        l = norm(v2 - v1, 2)

        x1 = 1/4 * sum(barra[[1, 4, 7, 10]])
        x2 = 1/4 * sum(barra[[13, 16, 19, 22]])
        y1 = 1/4 * sum(barra[[2, 5, 8, 11]])
        y2 = 1/4 * sum(barra[[14, 17, 20, 23]])
        z1 = 1/4 * sum(barra[[3, 6, 9, 12]])
        z2 = 1/4 * sum(barra[[15, 18, 21, 24]])

        v1 = [x1 y1 z1]
        v2 = [x2 y2 z2]

        w = norm(v2 - v1, 2)
        S = w * t

    else
        x1 = 1/4 * sum(barra[[1, 7, 13, 19]])
        x2 = 1/4 * sum(barra[[4, 10, 16, 22]])
        y1 = 1/4 * sum(barra[[2, 8, 14, 20]])
        y2 = 1/4 * sum(barra[[5, 11, 17, 23]])
        z1 = 1/4 * sum(barra[[3, 9, 15, 21]])
        z2 = 1/4 * sum(barra[[6, 12, 18, 24]])

        v1 = [x1 y1 z1]
        v2 = [x2 y2 z2]

        t = norm(v2 - v1, 2)

        x1 = 1/4 * sum(barra[[1, 4, 13, 16]])
        x2 = 1/4 * sum(barra[[7, 10, 19, 22]])
        y1 = 1/4 * sum(barra[[2, 5, 14, 17]])
        y2 = 1/4 * sum(barra[[8, 11, 20, 23]])
        z1 = 1/4 * sum(barra[[3, 6, 15, 18]])
        z2 = 1/4 * sum(barra[[9, 12, 21, 24]])

        v1 = [x1 y1 z1]
        v2 = [x2 y2 z2]

        w = norm(v2 - v1, 2)

        x1 = 1/4 * sum(barra[[1, 4, 7, 10]])
        x2 = 1/4 * sum(barra[[13, 16, 19, 22]])
        y1 = 1/4 * sum(barra[[2, 5, 8, 11]])
        y2 = 1/4 * sum(barra[[14, 17, 20, 23]])
        z1 = 1/4 * sum(barra[[3, 6, 9, 12]])
        z2 = 1/4 * sum(barra[[15, 18, 21, 24]])

        v1 = [x1 y1 z1]
        v2 = [x2 y2 z2]

        vers = (v2 - v1) ./ norm(v2 - v1, 2)
        l = norm(v2 - v1, 2)
        S = w * t
    end

    return l, w, t, S, vers
end
