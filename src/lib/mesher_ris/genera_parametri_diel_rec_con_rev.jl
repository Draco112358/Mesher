function genera_parametri_diel_rec_con_rev(induttanze::Dict)

    eps0 = 8.854187816997944e-12  # Permittivity of free space

    if induttanze[:Nd] > 0
        # Compute Cp for non-zero dielectric elements
        induttanze[:Cp] = eps0 * (induttanze[:epsr] .- 1) .* induttanze[:S] ./ induttanze[:l]
    else
        # Initialize Cp with zeros if Nd is zero
        induttanze[:Cp] = zeros(Float64, induttanze[:ncelle_ind_d])
    end

    return induttanze
end
