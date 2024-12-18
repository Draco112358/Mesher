function matrice_R_rev(induttanze)

    # Initialize R as a zeros array
    induttanze[:R] = zeros(size(induttanze[:estremi_celle], 1))

    # Calculate R for each cell
    for k in 1:size(induttanze[:estremi_celle], 1)
        if induttanze[:sigma][k] > 0
            induttanze[:R][k] = 1.0 / induttanze[:sigma][k] * induttanze[:l][k] / induttanze[:S][k]
        end
    end

    # Set R values for dielectric indices
    nc = size(induttanze[:estremi_celle], 1) - length(induttanze[:indici_Nd])
    induttanze[:R][nc+1:size(induttanze[:estremi_celle],1)] = zeros(length(induttanze[:indici_Nd]),1)

    return induttanze
end
