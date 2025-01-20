using SparseArrays

function matrice_incidenza_rev(LatiInd, nodi_centri, nodi_nodi_interni_coordinate)
    NodiCap1 = nodi_centri[1:(size(nodi_centri, 1) - size(nodi_nodi_interni_coordinate, 1)), :]
    NumLatiInd = size(LatiInd[1], 1)
    NumNodiCap = size(NodiCap1, 1)

    # Riduzione nodi capacitivi
    Rv = sparse(1:2, 1:2, ones(2))
    
    if NumNodiCap > 2
        ncr = NodiCap1[1:2, :]
        for k in 3:NumNodiCap
            m = findall(!iszero,
                (abs.(ncr[:, 1] .- NodiCap1[k, 1]) .<= 1e-8) .&&
                (abs.(ncr[:, 2] .- NodiCap1[k, 2]) .<= 1e-8) .&&
                (abs.(ncr[:, 3] .- NodiCap1[k, 3]) .<= 1e-8)
            )
            if isempty(m)
                ncr=[ncr; transpose(NodiCap1[k, :])]
                Rv_updated = spzeros(k,size(ncr,1))
                Rv_updated[1:k-1, 1:size(ncr,1)-1] = Rv
                Rv_updated[k,size(ncr,1)] = 1
                Rv = Rv_updated
                #Rv = sparse(1:size(ncr,1), 1:size(ncr,1), ones(size(ncr,1)))
            else
                #Rv = sparse(1:m[1], 1:m[1], ones(m[1]))
                Rv_updated = spzeros(k,size(Rv,2))
                Rv_updated[1:k-1, 1:size(Rv,2)] = Rv[1:k-1, 1:size(Rv,2)]
                Rv_updated[k,m[1]] = 1
                Rv = Rv_updated
            end
        end
    end

    nr = size(ncr, 1)
    NodiCap2 = vcat(ncr, nodi_nodi_interni_coordinate)  # [ncr; nodi_nodi_interni_coordinate]

    A = spzeros(NumLatiInd, size(NodiCap2, 1))
    estremi_lati1 = Array{Vector{Int}}(undef, NumLatiInd)
    estremi_lati2 = Array{Vector{Int}}(undef, NumLatiInd)
    estremi_lati = Array{Matrix{Int}}(undef, NumLatiInd)
    
    for k in 1:NumLatiInd
        # First endpoint
        nc = findall(!iszero,
            (abs.(LatiInd[1][k, 1] .- NodiCap2[:, 1]) .<= 1e-8) .&&
            (abs.(LatiInd[1][k, 2] .- NodiCap2[:, 2]) .<= 1e-8) .&&
            (abs.(LatiInd[1][k, 3] .- NodiCap2[:, 3]) .<= 1e-8)
        )
        A[k, nc] .= -ones(size(nc,1))
        estremi_lati1[k] = nc
        
        # Second endpoint
        nc = findall(!iszero,
            (abs.(LatiInd[2][k, 1] .- NodiCap2[:, 1]) .<= 1e-8) .&&
            (abs.(LatiInd[2][k, 2] .- NodiCap2[:, 2]) .<= 1e-8) .&&
            (abs.(LatiInd[2][k, 3] .- NodiCap2[:, 3]) .<= 1e-8)
        )
        A[k, nc] .= ones(size(nc,1))
        estremi_lati2[k] = nc
        
        estremi_lati[k] = hcat(estremi_lati1[k], estremi_lati2[k])
    end

    nodi_centri = NodiCap2

    return estremi_lati, Rv, nodi_centri, A
end
