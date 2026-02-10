function FindInternalNodesCommon2FourObjects_rev(nodi_centri, NodiRed)
    NumNodesSup = size(NodiRed, 1)
    InternalNodesList = Vector{Vector{Float64}}()

    for m in 1:NumNodesSup
        # Find nodes in NodiRed that are very close to NodiRed(m,:)
        n = findall(!iszero,
            (abs.(NodiRed[:, 1] .- NodiRed[m, 1]) .<= 1e-10) .&&
            (abs.(NodiRed[:, 2] .- NodiRed[m, 2]) .<= 1e-10) .&&
            (abs.(NodiRed[:, 3] .- NodiRed[m, 3]) .<= 1e-10)
        )

        if length(n) >= 4
            # Check if NodiRed(m,:) is in nodi_centri
            k = findall(!iszero,
                (abs.(NodiRed[m, 1] .- nodi_centri[:, 1]) .<= 1e-10) .&&
                (abs.(NodiRed[m, 2] .- nodi_centri[:, 2]) .<= 1e-10) .&&
                (abs.(NodiRed[m, 3] .- nodi_centri[:, 3]) .<= 1e-10)
            )

            if isempty(k)
                # If k is empty, proceed with adding to InternalNodesList
                if isempty(InternalNodesList)
                    push!(InternalNodesList, NodiRed[m, :])
                else
                    # Correct slicing for list of vectors using comprehension
                    l = findall(!iszero,
                        (abs.(NodiRed[m, 1] .- [n[1] for n in InternalNodesList]) .<= 1e-10) .&&
                        (abs.(NodiRed[m, 2] .- [n[2] for n in InternalNodesList]) .<= 1e-10) .&&
                        (abs.(NodiRed[m, 3] .- [n[3] for n in InternalNodesList]) .<= 1e-10)
                    )

                    if isempty(l)
                        push!(InternalNodesList, NodiRed[m, :])
                    end
                end
            end
        end
    end

    # Convert list of vectors to Matrix{Float64}
    if isempty(InternalNodesList)
        InternalNodes = zeros(Float64, 0, 3)
    else
        InternalNodes = permutedims(reduce(hcat, InternalNodesList))
    end

    return InternalNodes
end
