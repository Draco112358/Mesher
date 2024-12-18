function mean_cross_section_Lp(barra1, curr_dir)
    # Computes the mean-cross section of the psp described by barra1 and curr_dir

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

    # Precompute the direction-related vectors
    rmi = 0.125 * sum(ri, dims=1)
    rai = 0.125 * (-ri[1, :] + ri[2, :] + ri[4, :] - ri[3, :] - ri[5, :] + ri[6, :] + ri[8, :] - ri[7, :])
    rbi = 0.125 * (-ri[1, :] - ri[2, :] + ri[4, :] + ri[3, :] - ri[5, :] - ri[6, :] + ri[8, :] + ri[7, :])
    rci = 0.125 * (-ri[1, :] - ri[2, :] - ri[4, :] - ri[3, :] + ri[5, :] + ri[6, :] + ri[8, :] + ri[7, :])
    rabi = 0.125 * (ri[1, :] - ri[2, :] + ri[4, :] - ri[3, :] + ri[5, :] - ri[6, :] + ri[8, :] - ri[7, :])
    rbci = 0.125 * (ri[1, :] + ri[2, :] - ri[4, :] - ri[3, :] - ri[5, :] - ri[6, :] + ri[8, :] + ri[7, :])
    raci = 0.125 * (ri[1, :] - ri[2, :] - ri[4, :] + ri[3, :] - ri[5, :] + ri[6, :] + ri[8, :] - ri[7, :])
    rabci = 0.125 * (-ri[1, :] + ri[2, :] - ri[4, :] + ri[3, :] + ri[5, :] - ri[6, :] + ri[8, :] - ri[7, :])

    # Quadrature points and weights (assuming values are predefined or need to be set)
    rootx = [0]
    wex = [2]
    wey = wex
    rooty = rootx
    wez = wex
    rootz = rootx

    nlx = length(wex)
    nly = length(wey)
    nlz = length(wez)

    sum_a1 = 0.0
    for a1 in 1:nlx
        sum_b1 = 0.0
        for b1 in 1:nly
            sum_c1 = 0.0
            for c1 in 1:nlz
                drai = rai + rabi * rooty[b1] + raci * rootz[c1] + rabci * rooty[b1] * rootz[c1]
                drbi = rbi + rabi * rootx[a1] + rbci * rootz[c1] + rabci * rootx[a1] * rootz[c1]
                drci = rci + raci * rootx[a1] + rbci * rooty[b1] + rabci * rootx[a1] * rooty[b1]

                draim = norm(drai, 2)  # Euclidean norm
                drbim = norm(drbi, 2)
                drcim = norm(drci, 2)

                aversi = drai / draim
                bversi = drbi / drbim
                cversi = drci / drcim

                stetabi = cross(aversi, bversi)
                stetbci = cross(bversi, cversi)
                stetcai = cross(cversi, aversi)

                if curr_dir == 1
                    stetim = norm(stetbci, 2)
                    unitni = stetbci / stetim
                    ctetnormi = dot(unitni, aversi) / (norm(unitni, 2) * norm(aversi, 2))
                    f = drbim * drcim * stetim * ctetnormi / 2
                elseif curr_dir == 2
                    stetim = norm(stetcai, 2)
                    unitni = stetcai / stetim
                    ctetnormi = dot(unitni, bversi) / (norm(unitni, 2) * norm(bversi, 2))
                    f = draim * drcim * stetim * ctetnormi / 2
                else
                    stetim = norm(stetabi, 2)
                    unitni = stetabi / stetim
                    ctetnormi = dot(unitni, cversi) / (norm(unitni, 2) * norm(cversi, 2))
                    f = draim * drbim * stetim * ctetnormi / 2
                end

                sum_c1 += wez[c1] * f
            end  # (c1)
            sum_b1 += wey[b1] * sum_c1
        end  # (b1)
        sum_a1 += wex[a1] * sum_b1
    end  # (a1)

    mean_cr_sect = sum_a1
    return mean_cr_sect
end
