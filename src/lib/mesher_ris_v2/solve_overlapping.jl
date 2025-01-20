include("split_overlapping.jl")

function solve_overlapping_new(barre, materiale, materiale_dominante)
    continua = 1

    while continua == 1
        continua = 0
        isOverlapped = 0

        for cont1 in 1:size(barre, 1)-1
            for cont2 in cont1+1:size(barre, 1)
                # Call to split_overlapping function
                barre_split, isOverlapped, materiale_split = split_overlapping(barre[cont1, :], barre[cont2, :], materiale[cont1], materiale[cont2], materiale_dominante)
                #println(size(barre_split))
                if isOverlapped == 1
                    continua = 1

                    # Find indices to keep (remove cont1 and cont2)
                    indici_to_keep = setdiff(1:size(barre, 1), [cont1, cont2])
                    # Concatenate the new split barre and materiale
                    barre = vcat(barre_split, barre[indici_to_keep, :])
                    
                    materiale = vcat(materiale_split, materiale[indici_to_keep])

                    break
                end
            end

            if isOverlapped == 1
                break
            end
        end
    end

    return barre, materiale
end
