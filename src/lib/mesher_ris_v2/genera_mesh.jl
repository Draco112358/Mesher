include("discretizza_thermal_rev.jl")
include("matrice_R_rev.jl")
include("matrici_selettrici_rev.jl")
include("genera_parametri_diel_rec_con_rev.jl")
include("mean_length_rev.jl")

function genera_mesh(Regioni, den, freq_max, scalamento, use_escalings, materials)

    # Initialize the scaling factors
    escalings = Dict(
        :Lp => 1.0,
        :P => 1.0,
        :R => 1.0,
        :Cd => 1.0,
        :Is => 1.0,
        :Yle => 1.0,
        :freq => 1.0,
        :time => 1.0
    )

    if use_escalings == 1
        escalings[:Lp] = 1e6
        escalings[:P] = 1e-12
        escalings[:R] = 1e-3
        escalings[:Cd] = 1e12
        escalings[:Is] = 1e3
        escalings[:Yle] = 1e3
        escalings[:freq] = 1e-9
        escalings[:time] = 1e9
    end

    c0 = 3e8
    lambda = c0 ./ freq_max

    indx = 1:3:24
    indy = indx .+ 1
    indz = indy .+ 1

    N_reg = size(Regioni[:coordinate], 1)
    Regioni[:Nx] = zeros(N_reg)
    Regioni[:Ny] = zeros(N_reg)
    Regioni[:Nz] = zeros(N_reg)
    Regioni[:centri] = zeros(N_reg, 3)
    for p in 1:N_reg
        len = abs(mean_length_rev(Regioni[:coordinate][p, :], 1))
        thickness = abs(mean_length_rev(Regioni[:coordinate][p, :], 3))
        width = abs(mean_length_rev(Regioni[:coordinate][p, :], 2))

        Regioni[:Nx][p] = ceil(Int, len * scalamento / (lambda / den))
        Regioni[:Nx][p] = max(Regioni[:Nx][p], 2)

        Regioni[:Ny][p] = ceil(Int, width * scalamento / (lambda / den))
        Regioni[:Ny][p] = max(Regioni[:Ny][p], 2)

        Regioni[:Nz][p] = ceil(Int, thickness * scalamento / (lambda / den))
        Regioni[:Nz][p] = max(Regioni[:Nz][p], 2)

        Regioni[:centri] = [
            sum(Regioni[:coordinate][p, indx]),
            sum(Regioni[:coordinate][p, indy]),
            sum(Regioni[:coordinate][p, indz])
        ] / 8
    end
    #debug ok
    # Call discretizzazione function
    induttanze, nodi, A = discretizza_thermal_rev(Regioni, materials)

    induttanze[:indici_celle_indx] = findall(x -> x == 1, induttanze[:dir_curr])
    induttanze[:indici_celle_indy] = findall(x -> x == 2, induttanze[:dir_curr])
    induttanze[:indici_celle_indz] = findall(x -> x == 3, induttanze[:dir_curr])

    induttanze = matrice_R_rev(induttanze)
    induttanze = matrici_selettrici_rev(induttanze)
    induttanze = genera_parametri_diel_rec_con_rev(induttanze)

    transpose_nodi_Rv = transpose(nodi[:Rv])
    transpose_nodi_Rv_csc = SparseMatrixCSC(transpose_nodi_Rv)
    i, j, k = findnz(transpose_nodi_Rv_csc)

    incidence_selection = Dict(
        :Gamma => sparse(i,j,k,size(A,2),size(nodi[:Rv],1)),
        :mx => length(induttanze[:indici_celle_indx]),
        :my => length(induttanze[:indici_celle_indy]),
        :mz => length(induttanze[:indici_celle_indz])
    )

    perm = vcat(induttanze[:indici_celle_indx], induttanze[:indici_celle_indy], induttanze[:indici_celle_indz])

    volumi = Dict(
        :coordinate => induttanze[:estremi_celle][perm, :] * scalamento,
        :S => induttanze[:S][perm] * scalamento^2,
        :l => induttanze[:l][perm] * scalamento,
        :R => induttanze[:R][perm] / scalamento * escalings[:R],
        :Cd => !isempty(induttanze[:Cp]) ? induttanze[:Cp][perm] * scalamento * escalings[:Cd] : [],
        :centri => induttanze[:centri][perm, :] * scalamento
    )

    volumi[:indici_dielettrici] = zeros(length(induttanze[:indici_Nd]))
    for k in 1:length(induttanze[:indici_Nd])
        volumi[:indici_dielettrici][k] = findfirst(x -> x == induttanze[:indici_Nd][k], perm)
    end

    volumi[:Zs_part] = induttanze[:Zs_part][perm] / scalamento * escalings[:R]

    incidence_selection[:A] = A[perm, :]

    superfici = Dict(
        :estremi_celle => nodi[:estremi_celle] * scalamento,
        :centri => hcat(
            sum(nodi[:estremi_celle][:, 1:3:12]* scalamento, dims=2),
            sum(nodi[:estremi_celle][:, 2:3:12]* scalamento, dims=2),
            sum(nodi[:estremi_celle][:, 3:3:12]* scalamento, dims=2)
         ) / 4,
        :S => nodi[:superfici] * scalamento^2,
        :normale => nodi[:normale],
        :mur => nodi[:mur],
        :sigma => nodi[:sigma],
        :epsr => nodi[:epsr],
        :materials => nodi[:materials],
    )

    nodi_coord = nodi[:centri] * scalamento

    return incidence_selection, volumi, superfici, nodi_coord, escalings
end
