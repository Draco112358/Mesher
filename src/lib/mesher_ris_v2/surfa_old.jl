function surfa_old(barra1, weights_five, roots_five)
    # Computes the surface area of the patch described by barra1

    # Extract coordinates for xi1, yi1, zi1
    xi1 = [barra1[1], barra1[4], barra1[7], barra1[10]]
    yi1 = [barra1[2], barra1[5], barra1[8], barra1[11]]
    zi1 = [barra1[3], barra1[6], barra1[9], barra1[12]]
    
    # Initialize the array for the vertices (ri)
    ri = zeros(8, 3)
    
    # Vectors pointing to the vertices of the quadrilateral
    ri[1, :] = [xi1[1], yi1[1], zi1[1]]
    ri[2, :] = [xi1[2], yi1[2], zi1[2]]
    ri[3, :] = [xi1[3], yi1[3], zi1[3]]
    ri[4, :] = [xi1[4], yi1[4], zi1[4]]

    # Calculating midpoints and direction vectors
    rmi = 0.25 * sum(ri, dims=1)
    rai = 0.25 * (-ri[1, :] + ri[2, :] + ri[4, :] - ri[3, :])
    rbi = 0.25 * (-ri[1, :] - ri[2, :] + ri[4, :] + ri[3, :])
    rabi = 0.25 * (ri[1, :] - ri[2, :] + ri[4, :] - ri[3, :])

    # Assigning weights and roots
    wex = weights_five
    rootx = roots_five

    wey = wex
    rooty = rootx
    nlx = length(wex)
    nly = length(wey)

    # Initialize the sum for surface area
    sum_a1 = 0.0

    # Loop over the weight and root arrays
    for a1 in 1:nlx
        sum_b1 = 0.0
        for b1 in 1:nly
            # Compute the vectors for the integrand
            drai = rai .+ rabi .* rooty[b1]
            drbi = rbi .+ rabi .* rootx[a1]

            draim = sqrt(drai[1]^2 + drai[2]^2 + drai[3]^2)
            drbim = sqrt(drbi[1]^2 + drbi[2]^2 + drbi[3]^2)

            # Normalize the vectors
            aversi = drai ./ draim
            bversi = drbi ./ drbim

            # Compute the cross product and its magnitude
            steti = cross(aversi, bversi)
            stetim = sqrt(steti[1]^2 + steti[2]^2 + steti[3]^2)

            # Compute the differential area element
            f = draim * drbim * stetim

            # Sum up the contributions
            sum_b1 += wey[b1] * f
        end
        sum_a1 += wex[a1] * sum_b1
    end

    # Return the integral value
    return sum_a1
end
