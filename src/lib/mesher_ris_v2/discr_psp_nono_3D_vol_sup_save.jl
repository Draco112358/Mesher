function discr_psp_nono_3D_vol_sup_save(xyz, Npuntix, Npuntiy, Npuntiz, discrUnif, weights_five, roots_five)
    # Generate linspace equivalent in Julia
    a = range(-1, 1, Npuntix)
    b = range(-1, 1, Npuntiy)
    c = range(-1, 1, Npuntiz)
    
    lati_m = []
    ri=reshape(xyz,3,8)
    rmi, rai, rbi, rci, rabi, rbci, raci, rabci = interpolating_vectors(ri)
    
    # Create the 4D array `rp`
    rp = zeros(Npuntix, Npuntiy, Npuntiz, 3)
    for n in 1:Npuntiz
        for m in 1:Npuntiy
            for l in 1:Npuntix
                rp[l, m, n, :] .= (rmi + rai .* a[l] + rbi .* b[m] + rci .* c[n] +
                    rabi .* a[l] .* b[m] + rbci .* b[m] .* c[n] +
                    raci .* a[l] .* c[n] + rabci .* a[l] .* b[m] .* c[n])
            end
        end
    end
    
    i_barre = 1

    if discrUnif == 1
        sizeCicli = (Npuntiz - 1) * (Npuntiy - 1) * (Npuntix - 1)
        
        # Preallocate arrays
        indici_celle_indx = zeros(Int, 1, 4 * sizeCicli)
        indici_celle_indy = zeros(Int, 1, 4 * sizeCicli)
        indici_celle_indz = zeros(Int, 1, 4 * sizeCicli)
        celle_ind = zeros(Float64, 12 * sizeCicli, 24)
        lati1 = zeros(Float64, sizeCicli * 12, 3)
        lati2 = zeros(Float64, sizeCicli * 12, 3)
        vers = zeros(Float64, sizeCicli * 12, 3)
        l_i = zeros(Float64, sizeCicli * 12)
        spessore_i = zeros(Float64, 12 * sizeCicli)
        Sup_i = zeros(Float64, 12 * sizeCicli)
        width_i = zeros(Float64, 12 * sizeCicli)
        dir_curr = zeros(Int, 12 * sizeCicli)
        
        # Surface part
        celle_ind_sup = zeros(Float64, sizeCicli * 72, 12)
        Sup_sup = zeros(Float64, sizeCicli, 72)
        normale_sup = zeros(Float64, sizeCicli * 72, 3)
        dir_curr_sup = zeros(Int, sizeCicli * 72)
        rc_sup = zeros(Float64, sizeCicli * 72, 3)
        w_sup = zeros(Float64, sizeCicli * 72)
        
        barra = zeros(Float64, sizeCicli, 24)
        
        contTot = 0
        
        # Volume discretization
        for o in 1:(Npuntiz-1)
            for n in 1:(Npuntiy-1)
                for m in 1:(Npuntix-1)
                    # Initialize variables
                    contTot += 1

                    r1 = transpose(squeeze(rp[m, n, o, :]))
                    r2 = transpose(squeeze(rp[m+1, n, o, :]))
                    r3 = transpose(squeeze(rp[m, n+1, o, :]))
                    r4 = transpose(squeeze(rp[m+1, n+1, o, :]))
                    r5 = transpose(squeeze(0.5 * (rp[m, n, o, :] + rp[m, n+1, o, :])))
                    r6 = transpose(squeeze(0.5 * (rp[m+1, n, o, :] + rp[m+1, n+1, o, :])))
                    r7 = transpose(squeeze(0.5 * (rp[m, n, o, :] + rp[m+1, n, o, :])))
                    r8 = transpose(squeeze(0.5 * (rp[m, n+1, o, :] + rp[m+1, n+1, o, :])))
                    r9 = squeeze(0.5 * (r5 + r6))
                    r10 = transpose(squeeze(rp[m, n, o+1, :]))
                    r11 = transpose(squeeze(rp[m+1, n, o+1, :]))
                    r12 = transpose(squeeze(rp[m, n+1, o+1, :]))
                    r13 = transpose(squeeze(rp[m+1, n+1, o+1, :]))
                    r14 = transpose(squeeze(0.5 * (rp[m, n, o+1, :] + rp[m, n+1, o+1, :])))
                    r15 = transpose(squeeze(0.5 * (rp[m+1, n, o+1, :] + rp[m+1, n+1, o+1, :])))
                    r16 = transpose(squeeze(0.5 * (rp[m, n, o+1, :] + rp[m+1, n, o+1, :])))
                    r17 = transpose(squeeze(0.5 * (rp[m, n+1, o+1, :] + rp[m+1, n+1, o+1, :])))
                    r18 = squeeze(0.5 * (r14 + r15))
                    r19 = squeeze(0.5 * (r1 + r10))
                    r20 = squeeze(0.5 * (r7 + r16))
                    r21 = squeeze(0.5 * (r2 + r11))
                    r22 = squeeze(0.5 * (r6 + r15))
                    r23 = squeeze(0.5 * (r4 + r13))
                    r24 = squeeze(0.5 * (r8 + r17))
                    r25 = squeeze(0.5 * (r3 + r12))
                    r26 = squeeze(0.5 * (r5 + r14))
                    r27 = squeeze(0.5 * (r9 + r18))
                    r28 = squeeze(0.5 * (r1 + r5))
                    r29 = squeeze(0.5 * (r2 + r6))
                    r30 = squeeze(0.5 * (r5 + r3))
                    r31 = squeeze(0.5 * (r6 + r4))
                    r32 = squeeze(0.5 * (r10 + r14))
                    r33 = squeeze(0.5 * (r11 + r15))
                    r34 = squeeze(0.5 * (r14 + r12))
                    r35 = squeeze(0.5 * (r15 + r13))
                    r36 = squeeze(0.5 * (r7 + r9))
                    r37 = squeeze(0.5 * (r9 + r8))
                    r38 = squeeze(0.5 * (r16 + r18))
                    r39 = squeeze(0.5 * (r18 + r17))
                    r40 = squeeze(0.5 * (r28 + r32))
                    r41 = squeeze(0.5 * (r30 + r34))
                    r42 = squeeze(0.5 * (r21 + r22))
                    r43 = squeeze(0.5 * (r22 + r23))

                    # Combine nodes
                    r_nodi_barra = [r1; r2; r3; r4; r5; r6; r7; r8; r9; r10; r11; r12; r13; r14; r15; r16; r17; r18;
                                    r19; r20; r21; r22; r23; r24; r25; r26; r27; r28; r29; r30; r31; r32; r33; r34; r35;
                                    r36; r37; r38; r39; r40; r41; r42; r43]

                    # Generate inductive cells
                    celle_ind_p, lati_p, vers_p, l_i_p, indici_celle_indx_p, indici_celle_indy_p, indici_celle_indz_p, spessore_i_p, Sup_i_p, width_i_p, dir_curr_p = 
                        genera_celle_induttive(r_nodi_barra)

                    # Store results
                    p += 1
                    celle_ind[(contTot-1)*12+1:contTot*12, :] = celle_ind_p
                    lati1[(contTot-1)*12+1:contTot*12, :] = squeeze(lati_p[1, :, :])
                    lati2[(contTot-1)*12+1:contTot*12, :] = squeeze(lati_p[2, :, :])
                    vers[(contTot-1)*12+1:contTot*12, :] = vers_p
                    l_i[:, (contTot-1)*12+1:contTot*12] = l_i_p
                    indici_celle_indx[:, (contTot-1)*4+1:contTot*4] = indici_celle_indx_p
                    indici_celle_indy[:, (contTot-1)*4+1:contTot*4] = indici_celle_indy_p
                    indici_celle_indz[:, (contTot-1)*4+1:contTot*4] = indici_celle_indz_p
                    spessore_i[:, (contTot-1)*12+1:contTot*12] = spessore_i_p
                    Sup_i[:, (contTot-1)*12+1:contTot*12] = Sup_i_p
                    width_i[:, (contTot-1)*12+1:contTot*12] = width_i_p
                    dir_curr[(contTot-1)*12+1:contTot*12, :] = dir_curr_p

                    # Generate surface cells
                    celle_ind_sup_p, indici_celle_ind_supx_p, indici_celle_ind_supy_p, indici_celle_ind_supz_p, Sup_sup_p, normale_sup_p, dir_curr_sup_p, w_sup_p = 
                        genera_superfici_celle_induttive(r_nodi_barra, weights_five, roots_five)

                    # Compute center of surface cells
                    r1_sup = celle_ind_sup_p[:, 1:3]
                    r2_sup = celle_ind_sup_p[:, 4:6]
                    r3_sup = celle_ind_sup_p[:, 7:9]
                    r4_sup = celle_ind_sup_p[:, 10:12]
                    rc_sup_p = 0.25 * (r1_sup + r2_sup + r3_sup + r4_sup)

                    # Store results
                    celle_ind_sup[(contTot-1)*72+1:contTot*72, :] = celle_ind_sup_p
                    indici_celle_ind_supx[:, (contTot-1)*24+1:contTot*24] = indici_celle_ind_supx_p
                    indici_celle_ind_supy[:, (contTot-1)*24+1:contTot*24] = indici_celle_ind_supy_p
                    indici_celle_ind_supz[:, (contTot-1)*24+1:contTot*24] = indici_celle_ind_supz_p
                    Sup_sup[contTot, :] = Sup_sup_p
                    normale_sup[(contTot-1)*72+1:contTot*72, :] = normale_sup_p
                    dir_curr_sup[(contTot-1)*72+1:contTot*72, :] = dir_curr_sup_p
                    rc_sup[(contTot-1)*72+1:contTot*72, :] = rc_sup_p
                    w_sup[(contTot-1)*72+1:contTot*72, :] = w_sup_p'

                    # Update bar details
                    barra[i_barre, :] = [r1; r2; r3; r4; r10; r11; r12; r13]
                    i_barre += 1

                end
            end
        end
        # Initialize structures to hold indices
        indici_sup = Dict("x" => indici_celle_ind_supx,
        "y" => indici_celle_ind_supy,
        "z" => indici_celle_ind_supz)

        # Uniform discretization for surface inductive cells
        celle_mag, Sup_m, l_m, width_m, vers_m, norm_m = 
        genera_celle_induttive_sup(rp, Npuntix, Npuntiy, Npuntiz, weights_five, roots_five)

        # Surface capacitive cell discretization
        size1 = (Npuntiy-1)*(Npuntix-1)*16 + (Npuntiz-1)*(Npuntix-1)*16 + (Npuntiz-1)*(Npuntiy-1)*16
        size2 = (Npuntiy-1)*(Npuntix-1)*8 + (Npuntiz-1)*(Npuntix-1)*8 + (Npuntiz-1)*(Npuntiy-1)*8

        celle_cap = zeros(Float64, size1, 12)
        Sup_c = zeros(Float64, size2)
        l_c = zeros(Float64, size2)
        width_c = zeros(Float64, size2)
        Nodi = zeros(Float64, size1, 3)

        start = 1
        endC = 8

        start2 = 1
        endC2 = 4

        # Iterate over dimensions and generate capacitive cells
        for n in 1:Npuntiy-1
            for m in 1:Npuntix-1
            # Face I (xy, z=zmin)
            o = 1
            r1 = transpose(squeeze(rp[m, n, o, :]))
            r2 = transpose(squeeze(rp[m+1, n, o, :]))
            r3 = transpose(squeeze(rp[m, n+1, o, :]))
            r4 = transpose(squeeze(rp[m+1, n+1, o, :]))
            r_nodi_barra = vcat(r1, r2, r3, r4)

            celle_cap_p, Nodi_p, Sup_c_p, l_c_p, width_c_p = 
            genera_celle_capacitive_new_sup(r_nodi_barra, weights_five, roots_five)

            celle_cap[start:endC, :] .= celle_cap_p
            Nodi[start:endC, :] .= Nodi_p
            Sup_c[start2:endC2] .= Sup_c_p
            l_c[start2:endC2] .= l_c_p
            width_c[start2:endC2] .= width_c_p

            start += 8
            endC += 8
            start2 += 4
            endC2 += 4

            # Face II (xy, z=zmax)
            o = Npuntiz
            r1 = transpose(squeeze(rp[m, n, o, :]))
            r2 = transpose(squeeze(rp[m+1, n, o, :]))
            r3 = transpose(squeeze(rp[m, n+1, o, :]))
            r4 = transpose(squeeze(rp[m+1, n+1, o, :]))
            r_nodi_barra = vcat(r1, r2, r3, r4)

            celle_cap_p, Nodi_p, Sup_c_p, l_c_p, width_c_p = 
            genera_celle_capacitive_new_sup(r_nodi_barra, weights_five, roots_five)

            celle_cap[start:endC, :] .= celle_cap_p
            Nodi[start:endC, :] .= Nodi_p
            Sup_c[start2:endC2] .= Sup_c_p
            l_c[start2:endC2] .= l_c_p
            width_c[start2:endC2] .= width_c_p

            start += 8
            endC += 8
            start2 += 4
            endC2 += 4
            end
        end
        for o in 1:Npuntiz-1
            for m in 1:Npuntix-1
                # Face III (xz, y=ymin)
                n = 1
                r1 = transpose(squeeze(rp[m, n, o, :]))
                r2 = transpose(squeeze(rp[m+1, n, o, :]))
                r3 = transpose(squeeze(rp[m, n, o+1, :]))
                r4 = transpose(squeeze(rp[m+1, n, o+1, :]))
                r_nodi_barra = vcat(r1, r2, r3, r4)
                
                celle_cap_p, Nodi_p, Sup_c_p, l_c_p, width_c_p = 
                    genera_celle_capacitive_new_sup(r_nodi_barra, weights_five, roots_five)
                
                celle_cap[start:endC, :] .= celle_cap_p
                Nodi[start:endC, :] .= Nodi_p
                Sup_c[start2:endC2] .= Sup_c_p
                l_c[start2:endC2] .= l_c_p
                width_c[start2:endC2] .= width_c_p
                
                start += 8
                endC += 8
                start2 += 4
                endC2 += 4
        
                # Face IV (xz, y=ymax)
                n = Npuntiy
                r1 = transpose(squeeze(rp[m, n, o, :]))
                r2 = transpose(squeeze(rp[m+1, n, o, :]))
                r3 = transpose(squeeze(rp[m, n, o+1, :]))
                r4 = transpose(squeeze(rp[m+1, n, o+1, :]))
                r_nodi_barra = vcat(r1, r2, r3, r4)
                
                celle_cap_p, Nodi_p, Sup_c_p, l_c_p, width_c_p = 
                    genera_celle_capacitive_new_sup(r_nodi_barra, weights_five, roots_five)
                
                celle_cap[start:endC, :] .= celle_cap_p
                Nodi[start:endC, :] .= Nodi_p
                Sup_c[start2:endC2] .= Sup_c_p
                l_c[start2:endC2] .= l_c_p
                width_c[start2:endC2] .= width_c_p
                
                start += 8
                endC += 8
                start2 += 4
                endC2 += 4
            end
        end
        
        for n in 1:Npuntiy-1
            for o in 1:Npuntiz-1
                # Face V (yz, x=xmin)
                m = 1
                r1 = transpose(squeeze(rp[m, n, o, :]))
                r2 = transpose(squeeze(rp[m, n+1, o, :]))
                r3 = transpose(squeeze(rp[m, n, o+1, :]))
                r4 = transpose(squeeze(rp[m, n+1, o+1, :]))
                r_nodi_barra = vcat(r1, r2, r3, r4)
                
                celle_cap_p, Nodi_p, Sup_c_p, l_c_p, width_c_p = 
                    genera_celle_capacitive_new_sup(r_nodi_barra, weights_five, roots_five)
                
                celle_cap[start:endC, :] .= celle_cap_p
                Nodi[start:endC, :] .= Nodi_p
                Sup_c[start2:endC2] .= Sup_c_p
                l_c[start2:endC2] .= l_c_p
                width_c[start2:endC2] .= width_c_p
                
                start += 8
                endC += 8
                start2 += 4
                endC2 += 4
        
                # Face VI (yz, x=xmax)
                m = Npuntix
                r1 = transpose(squeeze(rp[m, n, o, :]))
                r2 = transpose(squeeze(rp[m, n+1, o, :]))
                r3 = transpose(squeeze(rp[m, n, o+1, :]))
                r4 = transpose(squeeze(rp[m, n+1, o+1, :]))
                r_nodi_barra = vcat(r1, r2, r3, r4)
                
                celle_cap_p, Nodi_p, Sup_c_p, l_c_p, width_c_p = 
                    genera_celle_capacitive_new_sup(r_nodi_barra, weights_five, roots_five)
                
                celle_cap[start:endC, :] .= celle_cap_p
                Nodi[start:endC, :] .= Nodi_p
                Sup_c[start2:endC2] .= Sup_c_p
                l_c[start2:endC2] .= l_c_p
                width_c[start2:endC2] .= width_c_p
                
                start += 8
                endC += 8
                start2 += 4
                endC2 += 4
            end
        end
        
        # Reduce capacitive nodes
        NumNodiCap = size(Nodi, 1)
        NodiRed = zeros(Float64, Npuntix * Npuntiy * Npuntiz - (Npuntix-2)*(Npuntiy-2)*(Npuntiz-2), 3)

        if NumNodiCap > 1
            NodiRed[1, :] = Nodi[1, :]
            nodoAct = 2
            for k in 2:NumNodiCap
                m = findfirst(i -> all(abs.(NodiRed[i, :] .- Nodi[k, :]) .<= 1e-11), 1:nodoAct-1)
                if isnothing(m)
                    NodiRed[nodoAct, :] = Nodi[k, :]
                    nodoAct += 1
                end
            end
        end
    else
        (celle_ind, lati, vers, l_i, spessore_i, Sup_i, width_i, dir_curr,
        celle_ind_sup, indici_celle_ind_supx, indici_celle_ind_supy, indici_celle_ind_supz, rc_sup, Sup_sup, normale_sup, dir_curr_sup, w_sup,
        barra) = genera_celle_induttive_maglie_save(rp, Npuntix, Npuntiy, Npuntiz, weights_five, roots_five)

        indici_sup = Dict(
            :x => indici_celle_ind_supx,
            :y => indici_celle_ind_supy,
            :z => indici_celle_ind_supz
        )

        (celle_mag, lati_m, Sup_m, l_m, width_m, vers_m, norm_m) =
            genera_celle_induttive_sup_maglie_save(rp, Npuntix, Npuntiy, Npuntiz, weights_five, roots_five)

        (celle_cap, Nodi, Sup_c, l_c, width_c, NodiRed) =
            genera_celle_capacitive_maglie_save(rp, Npuntix, Npuntiy, Npuntiz, weights_five, roots_five)
    end
    return barra, celle_cap, celle_ind, celle_mag, lati, lati_m, vers, Nodi, spessore_i, Sup_c, Sup_i, Sup_m, l_i, l_c, l_m, width_i, width_c, width_m, dir_curr, vers_m, norm_m, celle_ind_sup, Sup_sup, indici_sup, normale_sup, dir_curr_sup, rc_sup, w_sup, NodiRed
end
