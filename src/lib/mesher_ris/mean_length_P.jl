function mean_length_P(barra1, dir)
    # Extract coordinates from barra1, corresponding to the four vertices
    xi1 = [barra1[1], barra1[4], barra1[7], barra1[10]]
    yi1 = [barra1[2], barra1[5], barra1[8], barra1[11]]
    zi1 = [barra1[3], barra1[6], barra1[9], barra1[12]]
    
    # Initialize the vectors pointing to the vertices of the psp
    ri = zeros(4, 3)  # 4x3 matrix to hold the coordinates
    ri[1, :] = [xi1[1], yi1[1], zi1[1]]
    ri[2, :] = [xi1[2], yi1[2], zi1[2]]
    ri[3, :] = [xi1[3], yi1[3], zi1[3]]
    ri[4, :] = [xi1[4], yi1[4], zi1[4]]

    # Compute the centroid and direction vectors
    rmi = 0.25 * sum(ri, dims=1)  # Centroid of the shape (mean of vertices)
    rai = 0.25 * (-ri[1, :] + ri[2, :] + ri[4, :] - ri[3, :])  # Direction vector a
    rbi = 0.25 * (-ri[1, :] - ri[2, :] + ri[4, :] + ri[3, :])  # Direction vector b
    rabi = 0.25 * (ri[1, :] - ri[2, :] + ri[4, :] - ri[3, :])  # Cross vector

    # Calculate the mean length depending on the direction
    if dir == 1
        mean_l = norm(ri[1, :] - ri[2, :], 2)  # Length of the edge between vertex 1 and 2
    else
        mean_l = norm(ri[1, :] - ri[3, :], 2)  # Length of the edge between vertex 1 and 3
    end

    return mean_l
end
