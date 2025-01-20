include("squeeze.jl")
include("surfa_old.jl")
include("mean_length_save.jl")
include("mean_cross_section_Lp.jl")
include("mean_length_Lp.jl")
using  LinearAlgebra

function genera_celle_induttive_maglie_save(rp, Npuntix, Npuntiy, Npuntiz, weights_five, roots_five)
    n_celle_ind = Npuntiz * Npuntiy * (Npuntix - 1) + Npuntiz * (Npuntiy - 1) * Npuntix + (Npuntiz - 1) * Npuntiy * Npuntix
    celle_ind = zeros(n_celle_ind, 24)
    lati = zeros(2, n_celle_ind, 3)
    dir_curr = zeros(Int, n_celle_ind)
    vers = zeros(n_celle_ind, 3)
    l = zeros(n_celle_ind)
    spessore = zeros(n_celle_ind)
    Sup = zeros(n_celle_ind)
    width = zeros(n_celle_ind)

    dx = zeros(n_celle_ind)
    dy = zeros(n_celle_ind)
    dz = zeros(n_celle_ind)

    celle_ind_sup = zeros(6 * n_celle_ind, 12)
    rc_sup = zeros(6 * n_celle_ind, 3)
    Sup_sup = zeros(6 * n_celle_ind)
    normale_sup = zeros(6 * n_celle_ind, 3)
    dir_curr_sup = zeros(Int, 6 * n_celle_ind)
    w_sup = zeros(6 * n_celle_ind)

    indici_celle_ind_supx = zeros(Int, 6 * Npuntiz * Npuntiy * (Npuntix - 1))

    p = 1
    ps = 1
    psx = 1
    s = 1

    # Discretization of volume cells - X Direction
    for o in 1:Npuntiz
        for n in 1:Npuntiy
            for m in 1:(Npuntix - 1)
                if o == 1
                    if n == 1
                        r1 = transpose(squeeze(rp[m, n, o, :]))
                        r2 = transpose(squeeze(rp[m + 1, n, o, :]))
                    else
                        r1 = transpose(squeeze(0.5 .* (rp[m, n, o, :] .+ rp[m, n - 1, o, :])))
                        r2 = transpose(squeeze(0.5 .* (rp[m + 1, n, o, :] .+ rp[m + 1, n - 1, o, :])))
                    end
                else
                    if n == 1
                        r1 = transpose(squeeze(0.5 .* (rp[m, n, o, :] .+ rp[m, n, o - 1, :])))
                        r2 = transpose(squeeze(0.5 .* (rp[m + 1, n, o, :] .+ rp[m + 1, n, o - 1, :])))
                    else
                        r1 = transpose(squeeze(0.25 .* (rp[m, n, o, :] .+ rp[m, n - 1, o, :] .+ rp[m, n, o - 1, :] .+ rp[m, n - 1, o - 1, :])))
                        r2 = transpose(squeeze(0.25 .* (rp[m + 1, n, o, :] .+ rp[m + 1, n - 1, o, :] .+ rp[m + 1, n, o - 1, :] .+ rp[m + 1, n - 1, o - 1, :])))
                    end
                end
            
                if o == 1
                    if n == Npuntiy
                        r3 = transpose(squeeze(rp[m, n, o, :]))
                        r4 = transpose(squeeze(rp[m + 1, n, o, :]))
                    else
                        r3 = transpose(squeeze(0.5 .* (rp[m, n, o, :] .+ rp[m, n + 1, o, :])))
                        r4 = transpose(squeeze(0.5 .* (rp[m + 1, n, o, :] .+ rp[m + 1, n + 1, o, :])))
                    end
                else
                    if n == Npuntiy
                        r3 = transpose(squeeze(0.5 .* (rp[m, n, o, :] .+ rp[m, n, o - 1, :])))
                        r4 = transpose(squeeze(0.5 .* (rp[m + 1, n, o, :] .+ rp[m + 1, n, o - 1, :])))
                    else
                        r3 = transpose(squeeze(0.25 .* (rp[m, n, o, :] .+ rp[m, n + 1, o, :] .+ rp[m, n, o - 1, :] .+ rp[m, n + 1, o - 1, :])))
                        r4 = transpose(squeeze(0.25 .* (rp[m + 1, n, o, :] .+ rp[m + 1, n + 1, o, :] .+ rp[m + 1, n, o - 1, :] .+ rp[m + 1, n + 1, o - 1, :])))
                    end
                end
            
                if o == Npuntiz
                    if n == 1
                        r5 = transpose(squeeze(rp[m, n, o, :]))
                        r6 = transpose(squeeze(rp[m + 1, n, o, :]))
                    else
                        r5 = transpose(squeeze(0.5 .* (rp[m, n, o, :] .+ rp[m, n - 1, o, :])))
                        r6 = transpose(squeeze(0.5 .* (rp[m + 1, n, o, :] .+ rp[m + 1, n - 1, o, :])))
                    end
                else
                    if n == 1
                        r5 = transpose(squeeze(0.5 .* (rp[m, n, o, :] .+ rp[m, n, o + 1, :])))
                        r6 = transpose(squeeze(0.5 .* (rp[m + 1, n, o, :] .+ rp[m + 1, n, o + 1, :])))
                    else
                        r5 = transpose(squeeze(0.25 .* (rp[m, n, o, :] .+ rp[m, n - 1, o, :] .+ rp[m, n, o + 1, :] .+ rp[m, n - 1, o + 1, :])))
                        r6 = transpose(squeeze(0.25 .* (rp[m + 1, n, o, :] .+ rp[m + 1, n - 1, o, :] .+ rp[m + 1, n, o + 1, :] .+ rp[m + 1, n - 1, o + 1, :])))
                    end
                end
            
                if o == Npuntiz
                    if n == Npuntiy
                        r7 = transpose(squeeze(rp[m, n, o, :]))
                        r8 = transpose(squeeze(rp[m + 1, n, o, :]))
                    else
                        r7 = transpose(squeeze(0.5 .* (rp[m, n, o, :] .+ rp[m, n + 1, o, :])))
                        r8 = transpose(squeeze(0.5 .* (rp[m + 1, n, o, :] .+ rp[m + 1, n + 1, o, :])))
                    end
                else
                    if n == Npuntiy
                        r7 = transpose(squeeze(0.5 .* (rp[m, n, o, :] .+ rp[m, n, o + 1, :])))
                        r8 = transpose(squeeze(0.5 .* (rp[m + 1, n, o, :] .+ rp[m + 1, n, o + 1, :])))
                    else
                        r7 = transpose(squeeze(0.25 .* (rp[m, n, o, :] .+ rp[m, n + 1, o, :] .+ rp[m, n, o + 1, :] .+ rp[m, n + 1, o + 1, :])))
                        r8 = transpose(squeeze(0.25 .* (rp[m + 1, n, o, :] .+ rp[m + 1, n + 1, o, :] .+ rp[m + 1, n, o + 1, :] .+ rp[m + 1, n + 1, o + 1, :])))
                    end
                end
                celle_ind[p, :] = hcat(r1, r2, r3, r4, r5, r6, r7, r8)
                l[p] = abs(mean_length_save(celle_ind[p, :], 1))
                spessore[p] = abs(mean_length_save(celle_ind[p, :], 3))
                Sup[p] = abs(mean_cross_section_Lp(celle_ind[p, :], 1))
                width[p] = abs(mean_length_Lp(celle_ind[p, :], 2))
                dx[p] = norm(r2 - r1)
                dy[p] = norm(r3 - r1)
                dz[p] = norm(r5 - r1)
                l[p] = dx[p]
                Sup[p] = dy[p] * dz[p]
                p += 1

                lati[1, s, :] = transpose(squeeze(rp[m, n, o, :]))
                lati[2, s, :] = transpose(squeeze(rp[m + 1, n, o, :]))
                lato_vett = reshape(lati[2, s, :] - lati[1, s, :], 1, 3)
                dir_curr[s] = 1
                vers[s, :] = lato_vett ./ norm(lato_vett)
                s += 1

                # First section - superficie induttiva (xz plane)
                celle_ind_sup[ps, :] = [r1 r2 r3 r4]
                celle_ind_sup[ps + 1, :] = [r5 r6 r7 r8]
                dir_curr_sup[ps] = 1
                dir_curr_sup[ps + 1] = 1
                rc_sup[ps, :] = 0.25 * (r1 .+ r2 .+ r3 .+ r4)
                rc_sup[ps + 1, :] = 0.25 * (r5 .+ r6 .+ r7 .+ r8)
                indici_celle_ind_supx[[psx, psx + 1]] = [ps, ps + 1]
                Sup_sup[ps] = abs(surfa_old(celle_ind_sup[ps, :], weights_five, roots_five))
                Sup_sup[ps + 1] = abs(surfa_old(celle_ind_sup[ps + 1, :], weights_five, roots_five))
                normale_sup[ps, :] = -cross(r2.parent - r1.parent, r3.parent - r1.parent) / (norm(r2 - r1, 2) * norm(r3 - r1, 2))
                normale_sup[ps + 1, :] = cross(r6.parent - r5.parent, r7.parent - r5.parent) / (norm(r6 - r5, 2) * norm(r7 - r5, 2))
                w_sup[ps] = norm(r2 - r1, 2)
                w_sup[ps + 1] = norm(r5 - r6, 2)

                # Second section - superficie induttiva (xz plane)
                celle_ind_sup[ps + 2, :] = [r1 r2 r5 r6]
                celle_ind_sup[ps + 3, :] = [r3 r4 r7 r8]
                dir_curr_sup[ps + 2] = 1
                dir_curr_sup[ps + 3] = 1
                rc_sup[ps + 2, :] = 0.25 * (r1 .+ r2 .+ r5 .+ r6)
                rc_sup[ps + 3, :] = 0.25 * (r3 .+ r4 .+ r7 .+ r8)
                indici_celle_ind_supx[[psx + 2, psx + 3]] = [ps + 2, ps + 3]
                Sup_sup[ps + 2] = abs(surfa_old(celle_ind_sup[ps + 2, :], weights_five, roots_five))
                Sup_sup[ps + 3] = abs(surfa_old(celle_ind_sup[ps + 3, :], weights_five, roots_five))
                normale_sup[ps + 2, :] = cross(r2.parent - r1.parent, r5.parent - r1.parent) / (norm(r2 - r1, 2) * norm(r5 - r1, 2))
                normale_sup[ps + 3, :] = -cross(r4.parent - r3.parent, r7.parent - r3.parent) / (norm(r4 - r3, 2) * norm(r7 - r3, 2))
                w_sup[ps + 2] = norm(r2 - r1, 2)
                w_sup[ps + 3] = norm(r5 - r6, 2)

                # Third section - superficie induttiva (yz plane)
                celle_ind_sup[ps + 4, :] = [r1 r3 r5 r7]
                celle_ind_sup[ps + 5, :] = [r2 r4 r6 r8]
                dir_curr_sup[ps + 4] = 1
                dir_curr_sup[ps + 5] = 1
                rc_sup[ps + 4, :] = 0.25 * (r1 .+ r3 .+ r5 .+ r7)
                rc_sup[ps + 5, :] = 0.25 * (r2 .+ r4 .+ r6 .+ r8)
                indici_celle_ind_supx[[psx + 4, psx + 5]] = [ps + 4, ps + 5]
                Sup_sup[ps + 4] = abs(surfa_old(celle_ind_sup[ps + 4, :], weights_five, roots_five))
                Sup_sup[ps + 5] = abs(surfa_old(celle_ind_sup[ps + 5, :], weights_five, roots_five))
                normale_sup[ps + 4, :] = -cross(r3.parent - r1.parent, r5.parent - r1.parent) / (norm(r3 - r1, 2) * norm(r5 - r1, 2))
                normale_sup[ps + 5, :] = cross(r4.parent - r2.parent, r6.parent - r2.parent) / (norm(r4 - r2, 2) * norm(r6 - r2, 2))
                w_sup[ps + 4] = 0
                w_sup[ps + 5] = 0

                # Update ps and psx
                ps += 6
                psx += 6
            end
        end
    end
    # Discretizzazione delle celle di volume per il metodo delle maglie - Direzione Y
    indici_celle_ind_supy = zeros(Int, 6 * Npuntiz * (Npuntiy - 1) * Npuntix)
    psy = 1  # indice attuale del num di superficie cella induttiva nella direzione Y

    for o in 1:Npuntiz
        for m in 1:Npuntix
            for n in 1:Npuntiy - 1
                if o == 1
                    if m == 1
                        r1 = transpose(squeeze(rp[m, n, o, :]))
                        r3 = transpose(squeeze(rp[m, n+1, o, :]))
                    else
                        r1 = transpose(squeeze(0.5 * (rp[m, n, o, :] + rp[m-1, n, o, :])))
                        r3 = transpose(squeeze(0.5 * (rp[m, n+1, o, :] + rp[m-1, n+1, o, :])))
                    end
                else
                    if m == 1
                        r1 = transpose(squeeze(0.5 * (rp[m, n, o, :] + rp[m, n, o-1, :])))
                        r3 = transpose(squeeze(0.5 * (rp[m, n+1, o, :] + rp[m, n+1, o-1, :])))
                    else
                        r1 = transpose(squeeze(0.25 * (rp[m, n, o, :] + rp[m-1, n, o, :] + rp[m, n, o-1, :] + rp[m-1, n, o-1, :])))
                        r3 = transpose(squeeze(0.25 * (rp[m, n+1, o, :] + rp[m-1, n+1, o, :] + rp[m, n+1, o-1, :] + rp[m-1, n+1, o-1, :])))
                    end
                end

                if o == 1
                    if m == Npuntix
                        r2 = transpose(squeeze(rp[m, n, o, :]))
                        r4 = transpose(squeeze(rp[m, n+1, o, :]))
                    else
                        r2 = transpose(squeeze(0.5 * (rp[m, n, o, :] + rp[m+1, n, o, :])))
                        r4 = transpose(squeeze(0.5 * (rp[m, n+1, o, :] + rp[m+1, n+1, o, :])))
                    end
                else
                    if m == Npuntix
                        r2 = transpose(squeeze(0.5 * (rp[m, n, o, :] + rp[m, n, o-1, :])))
                        r4 = transpose(squeeze(0.5 * (rp[m, n+1, o, :] + rp[m, n+1, o-1, :])))
                    else
                        r2 = transpose(squeeze(0.25 * (rp[m, n, o, :] + rp[m+1, n, o, :] + rp[m, n, o-1, :] + rp[m+1, n, o-1, :])))
                        r4 = transpose(squeeze(0.25 * (rp[m, n+1, o, :] + rp[m+1, n+1, o, :] + rp[m, n+1, o-1, :] + rp[m+1, n+1, o-1, :])))
                    end
                end

                if o == Npuntiz
                    if m == 1
                        r5 = transpose(squeeze(rp[m, n, o, :]))
                        r7 = transpose(squeeze(rp[m, n+1, o, :]))
                    else
                        r5 = transpose(squeeze(0.5 * (rp[m, n, o, :] + rp[m-1, n, o, :])))
                        r7 = transpose(squeeze(0.5 * (rp[m, n+1, o, :] + rp[m-1, n+1, o, :])))
                    end
                else
                    if m == 1
                        r5 = transpose(squeeze(0.5 * (rp[m, n, o, :] + rp[m, n, o+1, :])))
                        r7 = transpose(squeeze(0.5 * (rp[m, n+1, o, :] + rp[m, n+1, o+1, :])))
                    else
                        r5 = transpose(squeeze(0.25 * (rp[m, n, o, :] + rp[m-1, n, o, :] + rp[m, n, o+1, :] + rp[m-1, n, o+1, :])))
                        r7 = transpose(squeeze(0.25 * (rp[m, n+1, o, :] + rp[m-1, n+1, o, :] + rp[m, n+1, o+1, :] + rp[m-1, n+1, o+1, :])))
                    end
                end

                if o == Npuntiz
                    if m == Npuntix
                        r6 = transpose(squeeze(rp[m, n, o, :]))
                        r8 = transpose(squeeze(rp[m, n+1, o, :]))
                    else
                        r6 = transpose(squeeze(0.5 * (rp[m, n, o, :] + rp[m+1, n, o, :])))
                        r8 = transpose(squeeze(0.5 * (rp[m, n+1, o, :] + rp[m+1, n+1, o, :])))
                    end
                else
                    if m == Npuntix
                        r6 = transpose(squeeze(0.5 * (rp[m, n, o, :] + rp[m, n, o+1, :])))
                        r8 = transpose(squeeze(0.5 * (rp[m, n+1, o, :] + rp[m, n+1, o+1, :])))
                    else
                        r6 = transpose(squeeze(0.25 * (rp[m, n, o, :] + rp[m+1, n, o, :] + rp[m, n, o+1, :] + rp[m+1, n, o+1, :])))
                        r8 = transpose(squeeze(0.25 * (rp[m, n+1, o, :] + rp[m+1, n+1, o, :] + rp[m, n+1, o+1, :] + rp[m+1, n+1, o+1, :])))
                    end
                end
                
                # Store cell data
                celle_ind[p, :] = hcat(r1, r2, r3, r4, r5, r6, r7, r8)
                l[p] = abs(mean_length_save(celle_ind[p, :], 2))
                spessore[p] = abs(mean_length_save(celle_ind[p, :], 3))
                Sup[p] = abs(mean_cross_section_Lp(celle_ind[p, :], 2))
                width[p] = abs(mean_length_Lp(celle_ind[p, :], 1))
                dx[p] = norm(r2 - r1, 2)
                dy[p] = norm(r3 - r1, 2)
                dz[p] = norm(r5 - r1, 2)
                l[p] = dy[p]
                Sup[p] = dx[p] * dz[p]

                # Update for next cell
                p += 1

                lati[1, s, :] = transpose(squeeze(rp[m, n, o, :]))
                lati[2, s, :] = transpose(squeeze(rp[m, n+1, o, :]))
                lato_vett = reshape(lati[2, s, :] - lati[1, s, :], 1, 3)
                dir_curr[s] = 2
                vers[s, 1:3] = lato_vett ./ norm(lato_vett, 2)
                s += 1

                # Surface cells - xy plane
                celle_ind_sup[ps, :] = [r1 r2 r3 r4]
                celle_ind_sup[ps+1, :] = [r5 r6 r7 r8]
                dir_curr_sup[ps] = 2
                dir_curr_sup[ps+1] = 2
                rc_sup[ps, :] = 0.25 * (r1 .+ r2 .+ r3 .+ r4)
                rc_sup[ps+1, :] = 0.25 * (r5 .+ r6 .+ r7 .+ r8)
                indici_celle_ind_supy[psy:psy+1] = [ps ps+1]
                Sup_sup[ps] = abs(surfa_old(celle_ind_sup[ps, :], weights_five, roots_five))
                Sup_sup[ps+1] = abs(surfa_old(celle_ind_sup[ps+1, :], weights_five, roots_five))
                normale_sup[ps, :] = -cross(r2.parent - r1.parent, r3.parent - r1.parent) / (norm(r2 - r1, 2) * norm(r3 - r1, 2))
                normale_sup[ps+1, :] = cross(r6.parent - r5.parent, r7.parent - r5.parent) / (norm(r6 - r5, 2) * norm(r7 - r5, 2))
                w_sup[ps] = norm(r2 - r1, 2)
                w_sup[ps+1] = norm(r5 - r6, 2)

                # Surface of the inductive cell - xz plane
                celle_ind_sup[ps+2, :] = [r1 r2 r5 r6]
                celle_ind_sup[ps+3, :] = [r3 r4 r7 r8]
                dir_curr_sup[ps+2] = 1
                dir_curr_sup[ps+3] = 1
                rc_sup[ps+2, :] = 0.25 * (r1 .+ r2 .+ r5 .+ r6)
                rc_sup[ps+3, :] = 0.25 * (r3 .+ r4 .+ r7 .+ r8)
                indici_celle_ind_supy[psy+2:psy+3] = [ps+2, ps+3]
                Sup_sup[ps+2] = abs(surfa_old(celle_ind_sup[ps+2, :], weights_five, roots_five))
                Sup_sup[ps+3] = abs(surfa_old(celle_ind_sup[ps+3, :], weights_five, roots_five))
                normale_sup[ps+2, :] = cross(r2.parent - r1.parent, r5.parent - r1.parent) / (norm(r2 - r1, 2) * norm(r5 - r1, 2))
                normale_sup[ps+3, :] = -cross(r4.parent - r3.parent, r7.parent - r3.parent) / (norm(r4 - r3, 2) * norm(r7 - r3, 2))
                w_sup[ps+2] = 0
                w_sup[ps+3] = 0

                # Surface of the inductive cell - yz plane
                celle_ind_sup[ps+4, :] = [r1 r3 r5 r7]
                celle_ind_sup[ps+5, :] = [r2 r4 r6 r8]
                dir_curr_sup[ps+4] = 1
                dir_curr_sup[ps+5] = 1
                rc_sup[ps+4, :] = 0.25 * (r1 .+ r3 .+ r5 .+ r7)
                rc_sup[ps+5, :] = 0.25 * (r2 .+ r4 .+ r6 .+ r8)
                indici_celle_ind_supy[psy+4:psy+5] = [ps+4, ps+5]
                Sup_sup[ps+4] = abs(surfa_old(celle_ind_sup[ps+4, :], weights_five, roots_five))
                Sup_sup[ps+5] = abs(surfa_old(celle_ind_sup[ps+5, :], weights_five, roots_five))
                normale_sup[ps+4, :] = -cross(r3.parent - r1.parent, r5.parent - r1.parent) / (norm(r3 - r1, 2) * norm(r5 - r1, 2))
                normale_sup[ps+5, :] = cross(r4.parent - r2.parent, r6.parent - r2.parent) / (norm(r4 - r2, 2) * norm(r6 - r2, 2))
                w_sup[ps+4] = norm(r3 - r1, 2)
                w_sup[ps+5] = norm(r2 - r4, 2)

                # Update indices for next iteration
                ps += 6
                psy += 6
            end  # ciclo n
        end  # ciclo m
    end  # ciclo o
    # Discretization of volume cells for the mesh method - Z direction
    # Initialize the index array for inductive cell surfaces in the Z direction
    indici_celle_ind_supz = zeros(6 * (Npuntiz - 1) * Npuntiy * Npuntix)

    psz = 1  # Current index of the inductive cell surface number in the Z direction
    for n = 1:Npuntiy
        for m = 1:Npuntix
            for o = 1:Npuntiz-1
                # Calculation for r1, r2, r3, r4, r5, r6, r7, r8 based on conditions for n, m
                if n == 1
                    if m == 1
                        r1 = transpose(squeeze(rp[m, n, o, :]))
                        r5 = transpose(squeeze(rp[m, n, o+1, :]))
                    else
                        r1 = transpose(squeeze(0.5 * (rp[m, n, o, :] + rp[m-1, n, o, :])))
                        r5 = transpose(squeeze(0.5 * (rp[m, n, o+1, :] + rp[m-1, n, o+1, :])))
                    end
                else
                    if m == 1
                        r1 = transpose(squeeze(0.5 * (rp[m, n, o, :] + rp[m, n-1, o, :])))
                        r5 = transpose(squeeze(0.5 * (rp[m, n, o+1, :] + rp[m, n-1, o+1, :])))
                    else
                        r1 = transpose(squeeze(0.25 * (rp[m, n, o, :] + rp[m-1, n, o, :] + rp[m, n-1, o, :] + rp[m-1, n-1, o, :])))
                        r5 = transpose(squeeze(0.25 * (rp[m, n, o+1, :] + rp[m-1, n, o+1, :] + rp[m, n-1, o+1, :] + rp[m-1, n-1, o+1, :])))
                    end
                end
                if n == 1
                    if m == Npuntix
                        r2 = transpose(squeeze(rp[m, n, o, :]))
                        r6 = transpose(squeeze(rp[m, n, o + 1, :]))
                    else
                        r2 = transpose(squeeze(0.5 * (rp[m, n, o, :] + rp[m + 1, n, o, :])))
                        r6 = transpose(squeeze(0.5 * (rp[m, n, o + 1, :] + rp[m + 1, n, o + 1, :])))
                    end
                else
                    if m == Npuntix
                        r2 = transpose(squeeze(0.5 * (rp[m, n, o, :] + rp[m, n - 1, o, :])))
                        r6 = transpose(squeeze(0.5 * (rp[m, n, o + 1, :] + rp[m, n - 1, o + 1, :])))
                    else
                        r2 = transpose(squeeze(0.25 * (rp[m, n, o, :] + rp[m + 1, n, o, :] + rp[m, n - 1, o, :] + rp[m + 1, n - 1, o, :])))
                        r6 = transpose(squeeze(0.25 * (rp[m, n, o + 1, :] + rp[m + 1, n, o + 1, :] + rp[m, n - 1, o + 1, :] + rp[m + 1, n - 1, o + 1, :])))
                    end
                end
                
                if n == Npuntiy
                    if m == 1
                        r3 = transpose(squeeze(rp[m, n, o, :]))
                        r7 = transpose(squeeze(rp[m, n, o + 1, :]))
                    else
                        r3 = transpose(squeeze(0.5 * (rp[m, n, o, :] + rp[m - 1, n, o, :])))
                        r7 = transpose(squeeze(0.5 * (rp[m, n, o + 1, :] + rp[m - 1, n, o + 1, :])))
                    end
                else
                    if m == 1
                        r3 = transpose(squeeze(0.5 * (rp[m, n, o, :] + rp[m, n + 1, o, :])))
                        r7 = transpose(squeeze(0.5 * (rp[m, n, o + 1, :] + rp[m, n + 1, o + 1, :])))
                    else
                        r3 = transpose(squeeze(0.25 * (rp[m, n, o, :] + rp[m - 1, n, o, :] + rp[m, n + 1, o, :] + rp[m - 1, n + 1, o, :])))
                        r7 = transpose(squeeze(0.25 * (rp[m, n, o + 1, :] + rp[m - 1, n, o + 1, :] + rp[m, n + 1, o + 1, :] + rp[m - 1, n + 1, o + 1, :])))
                    end
                end
                
                if n == Npuntiy
                    if m == Npuntix
                        r4 = transpose(squeeze(rp[m, n, o, :]))
                        r8 = transpose(squeeze(rp[m, n, o + 1, :]))
                    else
                        r4 = transpose(squeeze(0.5 * (rp[m, n, o, :] + rp[m + 1, n, o, :])))
                        r8 = transpose(squeeze(0.5 * (rp[m, n, o + 1, :] + rp[m + 1, n, o + 1, :])))
                    end
                else
                    if m == Npuntix
                        r4 = transpose(squeeze(0.5 * (rp[m, n, o, :] + rp[m, n + 1, o, :])))
                        r8 = transpose(squeeze(0.5 * (rp[m, n, o + 1, :] + rp[m, n + 1, o + 1, :])))
                    else
                        r4 = transpose(squeeze(0.25 * (rp[m, n, o, :] + rp[m + 1, n, o, :] + rp[m, n + 1, o, :] + rp[m + 1, n + 1, o, :])))
                        r8 = transpose(squeeze(0.25 * (rp[m, n, o + 1, :] + rp[m + 1, n, o + 1, :] + rp[m, n + 1, o + 1, :] + rp[m + 1, n + 1, o + 1, :])))
                    end
                end
                
                # Similar conditional calculations for r2, r3, r4, r5, r6, r7, r8
                # Continue similarly for r2, r3, r4, r6, r7, r8 calculations
                
                # Update cell indices, lengths, and surfaces
                celle_ind[p, :] = hcat(r1, r2, r3, r4, r5, r6, r7, r8)
                l[p] = abs(mean_length_save(celle_ind[p, :], 3))
                spessore[p] = abs(mean_length_save(celle_ind[p, :], 1))
                Sup[p] = abs(mean_cross_section_Lp(celle_ind[p, :], 3))
                width[p] = abs(mean_length_Lp(celle_ind[p, :], 2))
                dx[p] = norm(r2 - r1, 2)
                dy[p] = norm(r3 - r1, 2)
                dz[p] = norm(r5 - r1, 2)
                l[p] = dz[p]
                Sup[p] = dx[p] * dy[p]

                p += 1  # Increment cell index
                
                # Update the lateral faces
                lati[1, s, :] = transpose(squeeze(rp[m, n, o, :]))
                lati[2, s, :] = transpose(squeeze(rp[m, n, o+1, :]))
                lato_vett = reshape(lati[2, s, :] - lati[1, s, :], 1, 3)
                dir_curr[s] = 3
                vers[s, 1:3] = lato_vett ./ norm(lato_vett, 2)
                s += 1  # Increment lateral face index

                # Inductive cell surfaces - xy plane
                celle_ind_sup[ps, :] = [r1 r2 r3 r4]
                celle_ind_sup[ps+1, :] = [r5 r6 r7 r8]
                dir_curr_sup[ps] = 3
                dir_curr_sup[ps+1] = 3
                rc_sup[ps, :] = 0.25 * (r1 .+ r2 .+ r3 .+ r4)
                rc_sup[ps+1, :] = 0.25 * (r5 .+ r6 .+ r7 .+ r8)
                indici_celle_ind_supz[psz:psz+1] = [ps, ps+1]
                Sup_sup[ps] = abs(surfa_old(celle_ind_sup[ps, :], weights_five, roots_five))
                Sup_sup[ps+1] = abs(surfa_old(celle_ind_sup[ps+1, :], weights_five, roots_five))
                normale_sup[ps, :] = -cross(r2.parent - r1.parent, r3.parent - r1.parent) / (norm(r2 - r1, 2) * norm(r3 - r1, 2))
                normale_sup[ps+1, :] = cross(r6.parent - r5.parent, r7.parent - r5.parent) / (norm(r6 - r5, 2) * norm(r7 - r5, 2))
                w_sup[ps] = 0
                w_sup[ps+1] = 0
                
                # Inductive cell surfaces - xz plane
                celle_ind_sup[ps+2, :] = [r1 r2 r5 r6]
                celle_ind_sup[ps+3, :] = [r3 r4 r7 r8]
                dir_curr_sup[ps+2] = 1
                dir_curr_sup[ps+3] = 1
                rc_sup[ps+2, :] = 0.25 * (r1 .+ r2 .+ r5 .+ r6)
                rc_sup[ps+3, :] = 0.25 * (r3 .+ r4 .+ r7 .+ r8)
                indici_celle_ind_supz[psz+2:psz+3] = [ps+2, ps+3]
                Sup_sup[ps+2] = abs(surfa_old(celle_ind_sup[ps+2, :], weights_five, roots_five))
                Sup_sup[ps+3] = abs(surfa_old(celle_ind_sup[ps+3, :], weights_five, roots_five))
                normale_sup[ps+2, :] = cross(r2.parent - r1.parent, r5.parent - r1.parent) / (norm(r2 - r1, 2) * norm(r5 - r1, 2))
                normale_sup[ps+3, :] = -cross(r4.parent - r3.parent, r7.parent - r3.parent) / (norm(r4 - r3, 2) * norm(r7 - r3, 2))
                w_sup[ps+2] = norm(r2 - r1, 2)
                w_sup[ps+3] = norm(r4 - r3, 2)
                
                # Inductive cell surfaces - yz plane
                celle_ind_sup[ps+4, :] = [r1 r3 r5 r7]
                celle_ind_sup[ps+5, :] = [r2 r4 r6 r8]
                dir_curr_sup[ps+4] = 1
                dir_curr_sup[ps+5] = 1
                rc_sup[ps+4, :] = 0.25 * (r1 .+ r3 .+ r5 .+ r7)
                rc_sup[ps+5, :] = 0.25 * (r2 .+ r4 .+ r6 .+ r8)
                indici_celle_ind_supz[psz+4:psz+5] = [ps+4, ps+5]
                Sup_sup[ps+4] = abs(surfa_old(celle_ind_sup[ps+4, :], weights_five, roots_five))
                Sup_sup[ps+5] = abs(surfa_old(celle_ind_sup[ps+5, :], weights_five, roots_five))
                normale_sup[ps+4, :] = -cross(r3.parent - r1.parent, r5.parent - r1.parent) / (norm(r3 - r1, 2) * norm(r5 - r1, 2))
                normale_sup[ps+5, :] = cross(r4.parent - r2.parent, r6.parent - r2.parent) / (norm(r4 - r2, 2) * norm(r6 - r2, 2))
                w_sup[ps+4] = norm(r3 - r1, 2)
                w_sup[ps+5] = norm(r2 - r4, 2)
                
                ps += 6
                psz += 6
            end  # End of loop for o
        end  # End of loop for m
    end  # End of loop for n

    # Final variable assignment
    barra = celle_ind

    return celle_ind,lati,vers,l,spessore,Sup,width,dir_curr,
    celle_ind_sup,indici_celle_ind_supx,indici_celle_ind_supy,indici_celle_ind_supz,rc_sup,Sup_sup,normale_sup,dir_curr_sup,w_sup,
    barra
end