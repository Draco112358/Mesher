function genera_celle_induttive_sup_maglie_save(rp, Npuntix, Npuntiy, Npuntiz, weights_five, roots_five)
    #----------------------------------------------------------------------
    # Discretizzazione delle celle di superficie per le correnti magnetiche
    # per discretizzazione uniforme

    s = 1
    sizeA = (Npuntiy)*(Npuntix-1)*2 + (Npuntiy-1)*(Npuntix)*2 +
            (Npuntiz)*(Npuntix-1)*2 + (Npuntiz-1)*(Npuntix)*2 +
            (Npuntiz)*(Npuntiy-1)*2 + (Npuntiz-1)*(Npuntiy)*2

    lati_m = zeros(2, sizeA, 3)
    celle_mag = zeros(sizeA, 12)
    Sup_m = zeros(1, sizeA)
    l_m = zeros(1, sizeA)
    width_m = zeros(1, sizeA)
    vers_m = zeros(sizeA, 3)
    norm_m = zeros(sizeA, 3)
    lato_vett_m = zeros(sizeA, 3)
    lato_vett_m_p = zeros(1, 3)

    # Celle x sui piani xy
    for n = 1:Npuntiy
        for m = 1:Npuntix-1
            # Faccia I (xy, z=zmin)
            o = 1
            if n == 1
                r1 = transpose(squeeze(rp[m, n, o, :]))
                r2 = transpose(squeeze(rp[m+1, n, o, :]))
                lato_vett_m_p = r2 - r1
            else
                r1 = transpose(squeeze(0.5 * (rp[m, n, o, :] + rp[m, n-1, o, :])))
                r2 = transpose(squeeze(0.5 * (rp[m+1, n, o, :] + rp[m+1, n-1, o, :])))
            end
            if n == Npuntiy
                r3 = transpose(squeeze(rp[m, n, o, :]))
                r4 = transpose(squeeze(rp[m+1, n, o, :]))
                lato_vett_m_p = r4 - r3
            else
                r3 = transpose(squeeze(0.5 * (rp[m, n, o, :] + rp[m, n+1, o, :])))
                r4 = transpose(squeeze(0.5 * (rp[m+1, n, o, :] + rp[m+1, n+1, o, :])))
            end

            celle_mag_p = [r1 r2 r3 r4]
            Sup_m_p = surfa_old(celle_mag_p, weights_five, roots_five)
            l_m_p = abs(mean_length_P(celle_mag_p, 1))
            width_m_p = abs(mean_length_P(celle_mag_p, 2))
            vers_m_p = lato_vett_m_p / norm(lato_vett_m_p, 2)
            norm_m_p = [0 0 -1]

            celle_mag[s, :] = celle_mag_p
            Sup_m[1, s] = Sup_m_p
            l_m[1, s] = l_m_p
            width_m[1, s] = width_m_p
            vers_m[s, :] = vers_m_p
            norm_m[s, :] = norm_m_p
            lato_vett_m[s, :] = lato_vett_m_p
            lati_m[1, s, :] = transpose(squeeze(rp[m, n, o, :]))
            lati_m[2, s, :] = transpose(squeeze(rp[m+1, n, o, :]))
            s += 1

            # Faccia II (xy, z=zmax)
            o = Npuntiz
            if n == 1
                r1 = transpose(squeeze(rp[m, n, o, :]))
                r2 = transpose(squeeze(rp[m+1, n, o, :]))
                lato_vett_m_p = r2 - r1
            else
                r1 = transpose(squeeze(0.5 * (rp[m, n, o, :] + rp[m, n-1, o, :])))
                r2 = transpose(squeeze(0.5 * (rp[m+1, n, o, :] + rp[m+1, n-1, o, :])))
            end
            if n == Npuntiy
                r3 = transpose(squeeze(rp[m, n, o, :]))
                r4 = transpose(squeeze(rp[m+1, n, o, :]))
                lato_vett_m_p = r4 - r3
            else
                r3 = transpose(squeeze(0.5 * (rp[m, n, o, :] + rp[m, n+1, o, :])))
                r4 = transpose(squeeze(0.5 * (rp[m+1, n, o, :] + rp[m+1, n+1, o, :])))
            end

            celle_mag_p = [r1 r2 r3 r4]
            Sup_m_p = surfa_old(celle_mag_p, weights_five, roots_five)
            l_m_p = abs(mean_length_P(celle_mag_p, 1))
            width_m_p = abs(mean_length_P(celle_mag_p, 2))
            vers_m_p = lato_vett_m_p / norm(lato_vett_m_p, 2)
            norm_m_p = [0 0 1]

            celle_mag[s, :] = celle_mag_p
            Sup_m[1, s] = Sup_m_p
            l_m[1, s] = l_m_p
            width_m[1, s] = width_m_p
            vers_m[s, :] = vers_m_p
            norm_m[s, :] = norm_m_p
            lato_vett_m[s, :] = lato_vett_m_p
            lati_m[1, s, :] = transpose(squeeze(rp[m, n, o, :]))
            lati_m[2, s, :] = transpose(squeeze(rp[m+1, n, o, :]))
            s += 1
        end
    end
    # Assuming relevant functions and variables (e.g., surfa_old, mean_length_P) are defined elsewhere in the code

    # Loop over the 'n' index (for rows in the xy-plane)
    for n in 1:Npuntiy-1
        # Loop over the 'm' index (for columns in the xy-plane)
        for m in 1:Npuntix
            # Face III (xy, z=zmin)
            o = 1
            if m == 1
                r1 = transpose(squeeze(rp[m, n, o, :]))
                r3 = transpose(squeeze(rp[m, n+1, o, :]))
                lato_vett_m_p = r3 - r1
            else
                r1 = transpose(squeeze(0.5 * (rp[m, n, o, :] + rp[m-1, n, o, :])))
                r3 = transpose(squeeze(0.5 * (rp[m, n+1, o, :] + rp[m-1, n+1, o, :])))
            end

            if m == Npuntix
                r2 = transpose(squeeze(rp[m, n, o, :]))
                r4 = transpose(squeeze(rp[m, n+1, o, :]))
                lato_vett_m_p = r4 - r2
            else
                r2 = transpose(squeeze(0.5 * (rp[m, n, o, :] + rp[m+1, n, o, :])))
                r4 = transpose(squeeze(0.5 * (rp[m, n+1, o, :] + rp[m+1, n+1, o, :])))
            end

            celle_mag_p = hcat(r1, r2, r3, r4)
            Sup_m_p = surfa_old(celle_mag_p, weights_five, roots_five)
            l_m_p = abs(mean_length_P(celle_mag_p, 2))
            width_m_p = abs(mean_length_P(celle_mag_p, 1))
            vers_m_p = lato_vett_m_p / norm(lato_vett_m_p, 2)
            norm_m_p = [0, 0, -1]

            celle_mag[s, :] = celle_mag_p
            Sup_m[1, s] = Sup_m_p
            l_m[1, s] = l_m_p
            width_m[1, s] = width_m_p
            vers_m[s, :] = vers_m_p
            norm_m[s, :] = norm_m_p
            lato_vett_m[s, :] = lato_vett_m_p
            lati_m[1, s, :] = transpose(squeeze(rp[m, n, o, :]))
            lati_m[2, s, :] = transpose(squeeze(rp[m, n+1, o, :]))
            s += 1

            # Face IV (xy, z=zmax)
            o = Npuntiz
            if m == 1
                r1 = transpose(squeeze(rp[m, n, o, :]))
                r3 = transpose(squeeze(rp[m, n+1, o, :]))
            else
                r1 = transpose(squeeze(0.5 * (rp[m, n, o, :] + rp[m-1, n, o, :])))
                r3 = transpose(squeeze(0.5 * (rp[m, n+1, o, :] + rp[m-1, n+1, o, :])))
            end

            if m == Npuntix
                r2 = transpose(squeeze(rp[m, n, o, :]))
                r4 = transpose(squeeze(rp[m, n+1, o, :]))
            else
                r2 = transpose(squeeze(0.5 * (rp[m, n, o, :] + rp[m+1, n, o, :])))
                r4 = transpose(squeeze(0.5 * (rp[m, n+1, o, :] + rp[m+1, n+1, o, :])))
            end

            celle_mag_p = hcat(r1, r2, r3, r4)
            Sup_m_p = surfa_old(celle_mag_p, weights_five, roots_five)
            l_m_p = abs(mean_length_P(celle_mag_p, 2))
            width_m_p = abs(mean_length_P(celle_mag_p, 1))
            vers_m_p = lato_vett_m_p / norm(lato_vett_m_p, 2)
            norm_m_p = [0, 0, 1]
            norm_m_p = cross(r2.parent - r1.parent, r3.parent - r1.parent) / norm(cross(r2.parent - r1.parent, r3.parent - r1.parent))

            celle_mag[s, :] = celle_mag_p
            Sup_m[1, s] = Sup_m_p
            l_m[1, s] = l_m_p
            width_m[1, s] = width_m_p
            vers_m[s, :] = vers_m_p
            norm_m[s, :] = norm_m_p
            lato_vett_m[s, :] = lato_vett_m_p
            lati_m[1, s, :] = transpose(squeeze(rp[m, n, o, :]))
            lati_m[2, s, :] = transpose(squeeze(rp[m, n+1, o, :]))
            s += 1
        end # end of 'm' loop
    end # end of 'n' loop
    # Loop over the 'm' index (for columns in the xz-plane)
    for m in 1:Npuntix
        # Loop over the 'o' index (for the z-coordinate)
        for o in 1:Npuntiz-1
            # Face V (xz, y=ymin)
            
            n = 1
            if m == 1
                r1 = transpose(squeeze(rp[m, n, o, :]))
                r3 = transpose(squeeze(rp[m, n, o+1, :]))
                lato_vett_m_p = r3 - r1
            else
                r1 = transpose(squeeze(0.5 * (rp[m, n, o, :] + rp[m-1, n, o, :])))
                r3 = transpose(squeeze(0.5 * (rp[m, n, o+1, :] + rp[m-1, n, o+1, :])))
            end

            if m == Npuntix
                r2 = transpose(squeeze(rp[m, n, o, :]))
                r4 = transpose(squeeze(rp[m, n, o+1, :]))
                lato_vett_m_p = r4 - r2
            else
                r2 = transpose(squeeze(0.5 * (rp[m, n, o, :] + rp[m+1, n, o, :])))
                r4 = transpose(squeeze(0.5 * (rp[m, n, o+1, :] + rp[m+1, n, o+1, :])))
            end

            celle_mag_p = hcat(r1, r2, r3, r4)
            Sup_m_p = surfa_old(celle_mag_p, weights_five, roots_five)
            l_m_p = abs(mean_length_P(celle_mag_p, 3))
            width_m_p = abs(mean_length_P(celle_mag_p, 1))
            vers_m_p = lato_vett_m_p / norm(lato_vett_m_p, 2)
            norm_m_p = [0, -1, 0]  # Cross product not needed since it's directly given
            
            celle_mag[s, :] = celle_mag_p
            Sup_m[1, s] = Sup_m_p
            l_m[1, s] = l_m_p
            width_m[1, s] = width_m_p
            vers_m[s, :] = vers_m_p
            norm_m[s, :] = norm_m_p
            lato_vett_m[s, :] = lato_vett_m_p
            lati_m[1, s, :] = transpose(squeeze(rp[m, n, o, :]))
            lati_m[2, s, :] = transpose(squeeze(rp[m, n, o+1, :]))
            s += 1

            # Face VI (xz, y=ymax)
            n = Npuntiy
            if m == 1
                r1 = transpose(squeeze(rp[m, n, o, :]))
                r3 = transpose(squeeze(rp[m, n, o+1, :]))
                lato_vett_m_p = r3 - r1
            else
                r1 = transpose(squeeze(0.5 * (rp[m, n, o, :] + rp[m-1, n, o, :])))
                r3 = transpose(squeeze(0.5 * (rp[m, n, o+1, :] + rp[m-1, n, o+1, :])))
            end

            if m == Npuntix
                r2 = transpose(squeeze(rp[m, n, o, :]))
                r4 = transpose(squeeze(rp[m, n, o+1, :]))
                lato_vett_m_p = r4 - r2
            else
                r2 = transpose(squeeze(0.5 * (rp[m, n, o, :] + rp[m+1, n, o, :])))
                r4 = transpose(squeeze(0.5 * (rp[m, n, o+1, :] + rp[m+1, n, o+1, :])))
            end

            celle_mag_p = hcat(r1, r2, r3, r4)
            Sup_m_p = surfa_old(celle_mag_p, weights_five, roots_five)
            l_m_p = abs(mean_length_P(celle_mag_p, 3))
            width_m_p = abs(mean_length_P(celle_mag_p, 1))
            vers_m_p = lato_vett_m_p / norm(lato_vett_m_p, 2)
            norm_m_p = [0, 1, 0]  # Cross product not needed since it's directly given
            
            celle_mag[s, :] = celle_mag_p
            Sup_m[1, s] = Sup_m_p
            l_m[1, s] = l_m_p
            width_m[1, s] = width_m_p
            vers_m[s, :] = vers_m_p
            norm_m[s, :] = norm_m_p
            lato_vett_m[s, :] = lato_vett_m_p
            lati_m[1, s, :] = transpose(squeeze(rp[m, n, o, :]))
            lati_m[2, s, :] = transpose(squeeze(rp[m, n, o+1, :]))
            s += 1

        end # End of 'o' loop
    end # End of 'm' loop
    # Loop over the 'o' index (for the z-coordinate)
    for o in 1:Npuntiz
        # Loop over the 'm' index (for columns in the xz-plane)
        for m in 1:Npuntix-1
            # Face VII (xz, y=ymin)
            
            n = 1
            if o == 1
                r1 = transpose(squeeze(rp[m, n, o, :]))
                r2 = transpose(squeeze(rp[m+1, n, o, :]))
                lato_vett_m_p = r2 - r1
            else
                r1 = transpose(squeeze(0.5 * (rp[m, n, o, :] + rp[m, n, o-1, :])))
                r2 = transpose(squeeze(0.5 * (rp[m+1, n, o, :] + rp[m+1, n, o-1, :])))
            end

            if o == Npuntiz
                r3 = transpose(squeeze(rp[m, n, o, :]))
                r4 = transpose(squeeze(rp[m+1, n, o, :]))
                lato_vett_m_p = r4 - r3
            else
                r3 = transpose(squeeze(0.5 * (rp[m, n, o, :] + rp[m, n, o+1, :])))
                r4 = transpose(squeeze(0.5 * (rp[m+1, n, o, :] + rp[m+1, n, o+1, :])))
            end

            celle_mag_p = hcat(r1, r2, r3, r4)
            Sup_m_p = surfa_old(celle_mag_p, weights_five, roots_five)
            l_m_p = abs(mean_length_P(celle_mag_p, 1))
            width_m_p = abs(mean_length_P(celle_mag_p, 3))
            vers_m_p = lato_vett_m_p / norm(lato_vett_m_p, 2)
            norm_m_p = [0, -1, 0]  # Cross product not needed since it's directly given
            
            celle_mag[s, :] = celle_mag_p
            Sup_m[1, s] = Sup_m_p
            l_m[1, s] = l_m_p
            width_m[1, s] = width_m_p
            vers_m[s, :] = vers_m_p
            norm_m[s, :] = norm_m_p
            lato_vett_m[s, :] = lato_vett_m_p
            lati_m[1, s, :] = transpose(squeeze(rp[m, n, o, :]))
            lati_m[2, s, :] = transpose(squeeze(rp[m+1, n, o, :]))
            s += 1

            # Face VIII (xz, y=ymax)
            n = Npuntiy
            if o == 1
                r1 = transpose(squeeze(rp[m, n, o, :]))
                r2 = transpose(squeeze(rp[m+1, n, o, :]))
                lato_vett_m_p = r2 - r1
            else
                r1 = transpose(squeeze(0.5 * (rp[m, n, o, :] + rp[m, n, o-1, :])))
                r2 = transpose(squeeze(0.5 * (rp[m+1, n, o, :] + rp[m+1, n, o-1, :])))
            end

            if o == Npuntiz
                r3 = transpose(squeeze(rp[m, n, o, :]))
                r4 = transpose(squeeze(rp[m+1, n, o, :]))
                lato_vett_m_p = r4 - r3
            else
                r3 = transpose(squeeze(0.5 * (rp[m, n, o, :] + rp[m, n, o+1, :])))
                r4 = transpose(squeeze(0.5 * (rp[m+1, n, o, :] + rp[m+1, n, o+1, :])))
            end

            celle_mag_p = hcat(r1, r2, r3, r4)
            Sup_m_p = surfa_old(celle_mag_p, weights_five, roots_five)
            l_m_p = abs(mean_length_P(celle_mag_p, 1))
            width_m_p = abs(mean_length_P(celle_mag_p, 3))
            vers_m_p = lato_vett_m_p / norm(lato_vett_m_p, 2)
            norm_m_p = [0, 1, 0]  # Cross product not needed since it's directly given
            
            celle_mag[s, :] = celle_mag_p
            Sup_m[1, s] = Sup_m_p
            l_m[1, s] = l_m_p
            width_m[1, s] = width_m_p
            vers_m[s, :] = vers_m_p
            norm_m[s, :] = norm_m_p
            lato_vett_m[s, :] = lato_vett_m_p
            lati_m[1, s, :] = transpose(squeeze(rp[m, n, o, :]))
            lati_m[2, s, :] = transpose(squeeze(rp[m+1, n, o, :]))
            s += 1

        end # End of 'm' loop
    end # End of 'o' loop
    # Initialize variables (adjust this according to your actual dimensions)
    # Assuming Npuntiz, Npuntix, Npuntiy, rp, weights_five, roots_five, etc. are predefined
    # celle y sui piani yz
    for o in 1:Npuntiz
        for n in 1:Npuntiy-1
            # Faccia IX (yz, x=xmin)

            m = 1
            if o == 1
                r1 = transpose(squeeze(rp[m, n, o, :]))
                r2 = transpose(squeeze(rp[m, n+1, o, :]))
                lato_vett_m_p = r2 - r1
            else
                r1 = transpose(squeeze(0.5 * (rp[m, n, o, :] + rp[m, n, o-1, :])))
                r2 = transpose(squeeze(0.5 * (rp[m, n+1, o, :] + rp[m, n+1, o-1, :])))
            end
            if o == Npuntiz
                r3 = transpose(squeeze(rp[m, n, o, :]))
                r4 = transpose(squeeze(rp[m, n+1, o, :]))
                lato_vett_m_p = r4 - r3
            else
                r3 = transpose(squeeze(0.5 * (rp[m, n, o, :] + rp[m, n, o+1, :])))
                r4 = transpose(squeeze(0.5 * (rp[m, n+1, o, :] + rp[m, n+1, o+1, :])))
            end

            celle_mag_p = [r1 r2 r3 r4]
            Sup_m_p = surfa_old(celle_mag_p, weights_five, roots_five)
            l_m_p = abs(mean_length_P(celle_mag_p, 1))
            width_m_p = abs(mean_length_P(celle_mag_p, 3))
            vers_m_p = lato_vett_m_p / norm(lato_vett_m_p, 2)
            norm_m_p = [-1 0 0]

            celle_mag[s, :] = celle_mag_p
            Sup_m[s] = Sup_m_p
            l_m[s] = l_m_p
            width_m[s] = width_m_p
            vers_m[s, :] = vers_m_p
            norm_m[s, :] = norm_m_p
            lato_vett_m[s, :] = lato_vett_m_p
            lati_m[1, s, :] = transpose(squeeze(rp[m, n, o, :]))
            lati_m[2, s, :] = transpose(squeeze(rp[m, n+1, o, :]))
            s += 1

            # Faccia X (yz, x=xmax)
            m = Npuntix
            if o == 1
                r1 = transpose(squeeze(rp[m, n, o, :]))
                r2 = transpose(squeeze(rp[m, n+1, o, :]))
                lato_vett_m_p = r2 - r1
            else
                r1 = transpose(squeeze(0.5 * (rp[m, n, o, :] + rp[m, n, o-1, :])))
                r2 = transpose(squeeze(0.5 * (rp[m, n+1, o, :] + rp[m, n+1, o-1, :])))
            end
            if o == Npuntiz
                r3 = transpose(squeeze(rp[m, n, o, :]))
                r4 = transpose(squeeze(rp[m, n+1, o, :]))
                lato_vett_m_p = r4 - r3
            else
                r3 = transpose(squeeze(0.5 * (rp[m, n, o, :] + rp[m, n, o+1, :])))
                r4 = transpose(squeeze(0.5 * (rp[m, n+1, o, :] + rp[m, n+1, o+1, :])))
            end

            celle_mag_p = [r1 r2 r3 r4]
            Sup_m_p = surfa_old(celle_mag_p, weights_five, roots_five)
            l_m_p = abs(mean_length_P(celle_mag_p, 1))
            width_m_p = abs(mean_length_P(celle_mag_p, 3))
            vers_m_p = lato_vett_m_p / norm(lato_vett_m_p, 2)
            norm_m_p = [1 0 0]

            celle_mag[s, :] = celle_mag_p
            Sup_m[s] = Sup_m_p
            l_m[s] = l_m_p
            width_m[s] = width_m_p
            vers_m[s, :] = vers_m_p
            norm_m[s, :] = norm_m_p
            lato_vett_m[s, :] = lato_vett_m_p
            lati_m[1, s, :] = transpose(squeeze(rp[m, n, o, :]))
            lati_m[2, s, :] = transpose(squeeze(rp[m, n+1, o, :]))
            s += 1
        end
    end

    # celle z sui piani yz
    for n in 1:Npuntiy
        for o in 1:Npuntiz-1
            # Faccia XI (yz, x=xmin)

            m = 1
            if n == 1
                r1 = transpose(squeeze(rp[m, n, o, :]))
                r2 = transpose(squeeze(rp[m, n, o+1, :]))
                lato_vett_m_p = r2 - r1
            else
                r1 = transpose(squeeze(0.5 * (rp[m, n, o, :] + rp[m, n-1, o, :])))
                r2 = transpose(squeeze(0.5 * (rp[m, n, o+1, :] + rp[m, n-1, o+1, :])))
            end
            if n == Npuntiy
                r3 = transpose(squeeze(rp[m, n, o, :]))
                r4 = transpose(squeeze(rp[m, n, o+1, :]))
                lato_vett_m_p = r4 - r3
            else
                r3 = transpose(squeeze(0.5 * (rp[m, n, o, :] + rp[m, n+1, o, :])))
                r4 = transpose(squeeze(0.5 * (rp[m, n, o+1, :] + rp[m, n+1, o+1, :])))
            end

            celle_mag_p = [r1 r2 r3 r4]
            Sup_m_p = surfa_old(celle_mag_p, weights_five, roots_five)
            l_m_p = abs(mean_length_P(celle_mag_p, 1))
            width_m_p = abs(mean_length_P(celle_mag_p, 2))
            vers_m_p = lato_vett_m_p / norm(lato_vett_m_p, 2)
            norm_m_p = [-1 0 0]

            celle_mag[s, :] = celle_mag_p
            Sup_m[s] = Sup_m_p
            l_m[s] = l_m_p
            width_m[s] = width_m_p
            vers_m[s, :] = vers_m_p
            norm_m[s, :] = norm_m_p
            lato_vett_m[s, :] = lato_vett_m_p
            lati_m[1, s, :] = transpose(squeeze(rp[m, n, o, :]))
            lati_m[2, s, :] = transpose(squeeze(rp[m, n, o+1, :]))
            s += 1

            # Faccia XII (yz, x=xmax)
            m = Npuntix
            if n == 1
                r1 = transpose(squeeze(rp[m, n, o, :]))
                r2 = transpose(squeeze(rp[m, n, o+1, :]))
                lato_vett_m_p = r2 - r1
            else
                r1 = transpose(squeeze(0.5 * (rp[m, n, o, :] + rp[m, n-1, o, :])))
                r2 = transpose(squeeze(0.5 * (rp[m, n, o+1, :] + rp[m, n-1, o+1, :])))
            end
            if n == Npuntiy
                r3 = transpose(squeeze(rp[m, n, o, :]))
                r4 = transpose(squeeze(rp[m, n, o+1, :]))
                lato_vett_m_p = r4 - r3
            else
                r3 = transpose(squeeze(0.5 * (rp[m, n, o, :] + rp[m, n+1, o, :])))
                r4 = transpose(squeeze(0.5 * (rp[m, n, o+1, :] + rp[m, n+1, o+1, :])))
            end

            celle_mag_p = [r1 r2 r3 r4]
            Sup_m_p = surfa_old(celle_mag_p, weights_five, roots_five)
            l_m_p = abs(mean_length_P(celle_mag_p, 1))
            width_m_p = abs(mean_length_P(celle_mag_p, 2))
            vers_m_p = lato_vett_m_p / norm(lato_vett_m_p, 2)
            norm_m_p = [1 0 0]

            celle_mag[s, :] = celle_mag_p
            Sup_m[s] = Sup_m_p
            l_m[s] = l_m_p
            width_m[s] = width_m_p
            vers_m[s, :] = vers_m_p
            norm_m[s, :] = norm_m_p
            lato_vett_m[s, :] = lato_vett_m_p
            lati_m[1, s, :] = transpose(squeeze(rp[m, n, o, :]))
            lati_m[2, s, :] = transpose(squeeze(rp[m, n, o+1, :]))
            s += 1
        end
    end


    # Continue the same pattern for the other "celle y sui piani xy", "celle z sui piani xz", etc.
    # You can loop over the other faces (III, IV, V, VI, VII, VIII) and repeat the above logic.
    # Please ensure you handle the dimensions and indexing carefully in Julia.

    return celle_mag, lati_m, Sup_m, l_m, width_m, vers_m, norm_m
end
