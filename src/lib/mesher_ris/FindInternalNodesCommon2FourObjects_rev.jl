function FindInternalNodesCommon2FourObjects_rev(nodi_centri, NodiRed)
    NumNodesSup = size(NodiRed, 1)
    InternalNodes = []

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
                # If k is empty, proceed with adding to InternalNodes
                if isempty(InternalNodes)
                    push!(InternalNodes, NodiRed[m, :])
                else
                    l = findall(!iszero,
                        (abs.(NodiRed[m, 1] .- InternalNodes[:][1]) .<= 1e-10) .&&
                        (abs.(NodiRed[m, 2] .- InternalNodes[:][2]) .<= 1e-10) .&&
                        (abs,(NodiRed[m, 3] .- InternalNodes[:][3]) .<= 1e-10)
                    )
                    if isempty(l)
                        push!(InternalNodes, NodiRed[m, :])
                    end
                end
            end
        end
    end

    return InternalNodes
end
