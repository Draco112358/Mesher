function mean_length_save(barra1, curr_dir)
    # Computes the mean cross-section of the psp described by barra1 and curr_dir

    # Extract coordinates for xi1, yi1, zi1, xi2, yi2, zi2
    xi1 = [barra1[1], barra1[4], barra1[7], barra1[10]]
    yi1 = [barra1[2], barra1[5], barra1[8], barra1[11]]
    zi1 = [barra1[3], barra1[6], barra1[9], barra1[12]]
    xi2 = [barra1[13], barra1[16], barra1[19], barra1[22]]
    yi2 = [barra1[14], barra1[17], barra1[20], barra1[23]]
    zi2 = [barra1[15], barra1[18], barra1[21], barra1[24]]

    # Initialize the array for the vertices (ri)
    ri = zeros(8, 3)
    
    # Vectors pointing to the vertices of the psp
    ri[1, :] = [xi1[1], yi1[1], zi1[1]]
    ri[2, :] = [xi1[2], yi1[2], zi1[2]]
    ri[3, :] = [xi1[3], yi1[3], zi1[3]]
    ri[4, :] = [xi1[4], yi1[4], zi1[4]]
    ri[5, :] = [xi2[1], yi2[1], zi2[1]]
    ri[6, :] = [xi2[2], yi2[2], zi2[2]]
    ri[7, :] = [xi2[3], yi2[3], zi2[3]]
    ri[8, :] = [xi2[4], yi2[4], zi2[4]]

    # Calculate the points for the given direction
    if curr_dir == 1
        r1 = 0.25 * (ri[1, :] + ri[3, :] + ri[5, :] + ri[7, :])
        r2 = 0.25 * (ri[2, :] + ri[4, :] + ri[6, :] + ri[8, :])
    elseif curr_dir == 2
        r1 = 0.25 * (ri[1, :] + ri[2, :] + ri[5, :] + ri[6, :])
        r2 = 0.25 * (ri[3, :] + ri[4, :] + ri[7, :] + ri[8, :])
    else
        r1 = 0.25 * (ri[1, :] + ri[2, :] + ri[3, :] + ri[4, :])
        r2 = 0.25 * (ri[5, :] + ri[6, :] + ri[7, :] + ri[8, :])
    end

    # Compute the length between r1 and r2 (Euclidean norm)
    mean_l = norm(r1 - r2, 2)

    return mean_l
end
