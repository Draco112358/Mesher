include("squeeze.jl")
include("surfa_old.jl")
include("mean_length_P.jl")

function genera_celle_capacitive_maglie_save(rp, Npuntix, Npuntiy, Npuntiz, weights_five, roots_five)
    n_celle_cap = 2 * (Npuntiy * Npuntix + Npuntiz * Npuntix + Npuntiy * Npuntiz)
    celle_cap = zeros(n_celle_cap, 12)
    Nodi = zeros(n_celle_cap, 3)
    Sup_c = zeros(n_celle_cap, 1)
    l_c = zeros(n_celle_cap, 1)
    width_c = zeros(n_celle_cap, 1)
    r = 1  # Current surface cell index
    # Loop over the first two indices (n and m) for the XY face
    for n in 1:Npuntiy
        for m in 1:Npuntix
            # Faccia I and II (xy)
            # Points r1 and r5
            if n == 1
                if m == 1
                    o = 1
                    r1 = transpose(squeeze(rp[m, n, o, :]))
                    o = Npuntiz
                    r5 = transpose(squeeze(rp[m, n, o, :]))
                else
                    o = 1
                    r1 = transpose(squeeze(0.5 * (rp[m, n, o, :] + rp[m - 1, n, o, :])))
                    o = Npuntiz
                    r5 = transpose(squeeze(0.5 * (rp[m, n, o, :] + rp[m - 1, n, o, :])))
                end
            else
                if m == 1
                    o = 1
                    r1 = transpose(squeeze(0.5 * (rp[m, n, o, :] + rp[m, n - 1, o, :])))
                    o = Npuntiz
                    r5 = transpose(squeeze(0.5 * (rp[m, n, o, :] + rp[m, n - 1, o, :])))
                else
                    o = 1
                    r1 = transpose(squeeze(0.25 * (rp[m, n, o, :] + rp[m - 1, n, o, :] + rp[m, n - 1, o, :] + rp[m - 1, n - 1, o, :])))
                    o = Npuntiz
                    r5 = transpose(squeeze(0.25 * (rp[m, n, o, :] + rp[m - 1, n, o, :] + rp[m, n - 1, o, :] + rp[m - 1, n - 1, o, :])))
                end
            end

            # Points r2 and r6
            if n == 1
                if m == Npuntix
                    o = 1
                    r2 = transpose(squeeze(rp[m, n, o, :]))
                    o = Npuntiz
                    r6 = transpose(squeeze(rp[m, n, o, :]))
                else
                    o = 1
                    r2 = transpose(squeeze(0.5 * (rp[m, n, o, :] + rp[m + 1, n, o, :])))
                    o = Npuntiz
                    r6 = transpose(squeeze(0.5 * (rp[m, n, o, :] + rp[m + 1, n, o, :])))
                end
            else
                if m == Npuntix
                    o = 1
                    r2 = transpose(squeeze(0.5 * (rp[m, n, o, :] + rp[m, n - 1, o, :])))
                    o = Npuntiz
                    r6 = transpose(squeeze(0.5 * (rp[m, n, o, :] + rp[m, n - 1, o, :])))
                else
                    o = 1
                    r2 = transpose(squeeze(0.25 * (rp[m, n, o, :] + rp[m + 1, n, o, :] + rp[m, n - 1, o, :] + rp[m + 1, n - 1, o, :])))
                    o = Npuntiz
                    r6 = transpose(squeeze(0.25 * (rp[m, n, o, :] + rp[m + 1, n, o, :] + rp[m, n - 1, o, :] + rp[m + 1, n - 1, o, :])))
                end
            end

            # Points r3 and r7
            if n == Npuntiy
                if m == 1
                    o = 1
                    r3 = transpose(squeeze(rp[m, n, o, :]))
                    o = Npuntiz
                    r7 = transpose(squeeze(rp[m, n, o, :]))
                else
                    o = 1
                    r3 = transpose(squeeze(0.5 * (rp[m, n, o, :] + rp[m - 1, n, o, :])))
                    o = Npuntiz
                    r7 = transpose(squeeze(0.5 * (rp[m, n, o, :] + rp[m - 1, n, o, :])))
                end
            else
                if m == 1
                    o = 1
                    r3 = transpose(squeeze(0.5 * (rp[m, n, o, :] + rp[m, n + 1, o, :])))
                    o = Npuntiz
                    r7 = transpose(squeeze(0.5 * (rp[m, n, o, :] + rp[m, n + 1, o, :])))
                else
                    o = 1
                    r3 = transpose(squeeze(0.25 * (rp[m, n, o, :] + rp[m - 1, n, o, :] + rp[m, n + 1, o, :] + rp[m - 1, n + 1, o, :])))
                    o = Npuntiz
                    r7 = transpose(squeeze(0.25 * (rp[m, n, o, :] + rp[m - 1, n, o, :] + rp[m, n + 1, o, :] + rp[m - 1, n + 1, o, :])))
                end
            end

            # Points r4 and r8
            if n == Npuntiy
                if m == Npuntix
                    o = 1
                    r4 = transpose(squeeze(rp[m, n, o, :]))
                    o = Npuntiz
                    r8 = transpose(squeeze(rp[m, n, o, :]))
                else
                    o = 1
                    r4 = transpose(squeeze(0.5 * (rp[m, n, o, :] + rp[m + 1, n, o, :])))
                    o = Npuntiz
                    r8 = transpose(squeeze(0.5 * (rp[m, n, o, :] + rp[m + 1, n, o, :])))
                end
            else
                if m == Npuntix
                    o = 1
                    r4 = transpose(squeeze(0.5 * (rp[m, n, o, :] + rp[m, n + 1, o, :])))
                    o = Npuntiz
                    r8 = transpose(squeeze(0.5 * (rp[m, n, o, :] + rp[m, n + 1, o, :])))
                else
                    o = 1
                    r4 = transpose(squeeze(0.25 * (rp[m, n, o, :] + rp[m + 1, n, o, :] + rp[m, n + 1, o, :] + rp[m + 1, n + 1, o, :])))
                    o = Npuntiz
                    r8 = transpose(squeeze(0.25 * (rp[m, n, o, :] + rp[m + 1, n, o, :] + rp[m, n + 1, o, :] + rp[m + 1, n + 1, o, :])))
                end
            end

            celle_cap[r, :] = hcat(r1, r2, r3, r4)
            celle_cap[r + 1, :] = hcat(r5, r6, r7, r8)
            Nodi[r, :] = transpose(squeeze(rp[m, n, 1, :]))
            Nodi[r + 1, :] = transpose(squeeze(rp[m, n, Npuntiz, :]))
            Sup_c[r] = surfa_old(celle_cap[r, :], weights_five, roots_five)
            Sup_c[r + 1] = surfa_old(celle_cap[r + 1, :], weights_five, roots_five)

            # For calculating the length and width, assume l_c is in direction 1 and width_c in direction 2
            l_c[r] = abs(mean_length_P(celle_cap[r, :], 1))
            width_c[r] = abs(mean_length_P(celle_cap[r, :], 2))
            l_c[r + 1] = abs(mean_length_P(celle_cap[r + 1, :], 1))
            width_c[r + 1] = abs(mean_length_P(celle_cap[r + 1, :], 2))

            r += 2
        end
    end
    for o in 1:Npuntiz
        for m in 1:Npuntix
            # Faccia III e IV (xz)
            # punti r1 ed r5
            if o == 1
                if m == 1
                    n = 1
                    r1 = transpose(squeeze(rp[m, n, o, :]))
                    n = Npuntiy
                    r5 = transpose(squeeze(rp[m, n, o, :]))
                else
                    n = 1
                    r1 = transpose(squeeze(0.5 * (rp[m, n, o, :] + rp[m-1, n, o, :])))
                    n = Npuntiy
                    r5 = transpose(squeeze(0.5 * (rp[m, n, o, :] + rp[m-1, n, o, :])))
                end
            else
                if m == 1
                    n = 1
                    r1 = transpose(squeeze(0.5 * (rp[m, n, o, :] + rp[m, n, o-1, :])))
                    n = Npuntiy
                    r5 = transpose(squeeze(0.5 * (rp[m, n, o, :] + rp[m, n, o-1, :])))
                else
                    n = 1
                    r1 = transpose(squeeze(0.25 * (rp[m, n, o, :] + rp[m-1, n, o, :] + rp[m, n, o-1, :] + rp[m-1, n, o-1, :])))
                    n = Npuntiy
                    r5 = transpose(squeeze(0.25 * (rp[m, n, o, :] + rp[m-1, n, o, :] + rp[m, n, o-1, :] + rp[m-1, n, o-1, :])))
                end
            end
            # punti r2 ed r6
            if o == 1
                if m == Npuntix
                    n = 1
                    r2 = transpose(squeeze(rp[m, n, o, :]))
                    n = Npuntiy
                    r6 = transpose(squeeze(rp[m, n, o, :]))
                else
                    n = 1
                    r2 = transpose(squeeze(0.5 * (rp[m, n, o, :] + rp[m+1, n, o, :])))
                    n = Npuntiy
                    r6 = transpose(squeeze(0.5 * (rp[m, n, o, :] + rp[m+1, n, o, :])))
                end
            else
                if m == Npuntix
                    n = 1
                    r2 = transpose(squeeze(0.5 * (rp[m, n, o, :] + rp[m, n, o-1, :])))
                    n = Npuntiy
                    r6 = transpose(squeeze(0.5 * (rp[m, n, o, :] + rp[m, n, o-1, :])))
                else
                    n = 1
                    r2 = transpose(squeeze(0.25 * (rp[m, n, o, :] + rp[m+1, n, o, :] + rp[m, n, o-1, :] + rp[m+1, n, o-1, :])))
                    n = Npuntiy
                    r6 = transpose(squeeze(0.25 * (rp[m, n, o, :] + rp[m+1, n, o, :] + rp[m, n, o-1, :] + rp[m+1, n, o-1, :])))
                end
            end
            # punti r3 ed r7
            if o == Npuntiz
                if m == 1
                    n = 1
                    r3 = transpose(squeeze(rp[m, n, o, :]))
                    n = Npuntiy
                    r7 = transpose(squeeze(rp[m, n, o, :]))
                else
                    n = 1
                    r3 = transpose(squeeze(0.5 * (rp[m, n, o, :] + rp[m-1, n, o, :])))
                    n = Npuntiy
                    r7 = transpose(squeeze(0.5 * (rp[m, n, o, :] + rp[m-1, n, o, :])))
                end
            else
                if m == 1
                    n = 1
                    r3 = transpose(squeeze(0.5 * (rp[m, n, o, :] + rp[m, n, o+1, :])))
                    n = Npuntiy
                    r7 = transpose(squeeze(0.5 * (rp[m, n, o, :] + rp[m, n, o+1, :])))
                else
                    n = 1
                    r3 = transpose(squeeze(0.25 * (rp[m, n, o, :] + rp[m-1, n, o, :] + rp[m, n, o+1, :] + rp[m-1, n, o+1, :])))
                    n = Npuntiy
                    r7 = transpose(squeeze(0.25 * (rp[m, n, o, :] + rp[m-1, n, o, :] + rp[m, n, o+1, :] + rp[m-1, n, o+1, :])))
                end
            end
            # punti r4 ed r8
            if o == Npuntiz
                if m == Npuntix
                    n = 1
                    r4 = transpose(squeeze(rp[m, n, o, :]))
                    n = Npuntiy
                    r8 = transpose(squeeze(rp[m, n, o, :]))
                else
                    n = 1
                    r4 = transpose(squeeze(0.5 * (rp[m, n, o, :] + rp[m+1, n, o, :])))
                    n = Npuntiy
                    r8 = transpose(squeeze(0.5 * (rp[m, n, o, :] + rp[m+1, n, o, :])))
                end
            else
                if m == Npuntix
                    n = 1
                    r4 = transpose(squeeze(0.5 * (rp[m, n, o, :] + rp[m, n, o+1, :])))
                    n = Npuntiy
                    r8 = transpose(squeeze(0.5 * (rp[m, n, o, :] + rp[m, n, o+1, :])))
                else
                    n = 1
                    r4 = transpose(squeeze(0.25 * (rp[m, n, o, :] + rp[m+1, n, o, :] + rp[m, n, o+1, :] + rp[m+1, n, o+1, :])))
                    n = Npuntiy
                    r8 = transpose(squeeze(0.25 * (rp[m, n, o, :] + rp[m+1, n, o, :] + rp[m, n, o+1, :] + rp[m+1, n, o+1, :])))
                end
            end
            
            celle_cap[r, :] = [r1 r2 r3 r4]
            celle_cap[r+1, :] = [r5 r6 r7 r8]
            Nodi[r, :] = transpose(squeeze(rp[m, 1, o, :]))
            Nodi[r+1, :] = transpose(squeeze(rp[m, Npuntiy, o, :]))
            Sup_c[r] = surfa_old(celle_cap[r, :], weights_five, roots_five)
            Sup_c[r+1] = surfa_old(celle_cap[r+1, :], weights_five, roots_five)
            # Per il calcolo della lunghezza e della larghezza assumo che l_c sia nella direzione 2 e che width_c nella direzione 1
            l_c[r] = abs(mean_length_P(celle_cap[r, :], 2))
            width_c[r] = abs(mean_length_P(celle_cap[r, :], 1))
            l_c[r+1] = abs(mean_length_P(celle_cap[r+1, :], 2))
            width_c[r+1] = abs(mean_length_P(celle_cap[r+1, :], 1))
            
            r += 2
        end # ciclo m
    end # ciclo o
    
    for o in 1:Npuntiz
        for n in 1:Npuntiy
            # Faccia V e VI (yz)
            # punti r1 ed r5
            if o == 1
                if n == 1
                    m = 1
                    r1 = transpose(squeeze(rp[m, n, o, :]))
                    m = Npuntix
                    r5 = transpose(squeeze(rp[m, n, o, :]))
                else
                    m = 1
                    r1 = transpose(squeeze(0.5 * (rp[m, n, o, :] + rp[m, n-1, o, :])))
                    m = Npuntix
                    r5 = transpose(squeeze(0.5 * (rp[m, n, o, :] + rp[m, n-1, o, :])))
                end
            else
                if n == 1
                    m = 1
                    r1 = transpose(squeeze(0.5 * (rp[m, n, o, :] + rp[m, n, o-1, :])))
                    m = Npuntix
                    r5 = transpose(squeeze(0.5 * (rp[m, n, o, :] + rp[m, n, o-1, :])))
                else
                    m = 1
                    r1 = transpose(squeeze(0.25 * (rp[m, n, o, :] + rp[m, n-1, o, :] + rp[m, n, o-1, :] + rp[m, n-1, o-1, :])))
                    m = Npuntix
                    r5 = transpose(squeeze(0.25 * (rp[m, n, o, :] + rp[m, n-1, o, :] + rp[m, n, o-1, :] + rp[m, n-1, o-1, :])))
                end
            end
            # punti r2 ed r6
            if o == 1
                if n == Npuntiy
                    m = 1
                    r2 = transpose(squeeze(rp[m, n, o, :]))
                    m = Npuntix
                    r6 = transpose(squeeze(rp[m, n, o, :]))
                else
                    m = 1
                    r2 = transpose(squeeze(0.5 * (rp[m, n, o, :] + rp[m, n+1, o, :])))
                    m = Npuntix
                    r6 = transpose(squeeze(0.5 * (rp[m, n, o, :] + rp[m, n+1, o, :])))
                end
            else
                if n == Npuntiy
                    m = 1
                    r2 = transpose(squeeze(0.5 * (rp[m, n, o, :] + rp[m, n, o-1, :])))
                    m = Npuntix
                    r6 = transpose(squeeze(0.5 * (rp[m, n, o, :] + rp[m, n, o-1, :])))
                else
                    m = 1
                    r2 = transpose(squeeze(0.25 * (rp[m, n, o, :] + rp[m, n+1, o, :] + rp[m, n, o-1, :] + rp[m, n+1, o-1, :])))
                    m = Npuntix
                    r6 = transpose(squeeze(0.25 * (rp[m, n, o, :] + rp[m, n+1, o, :] + rp[m, n, o-1, :] + rp[m, n+1, o-1, :])))
                end
            end
            # punti r3 ed r7
            if o == Npuntiz
                if n == 1
                    m = 1
                    r3 = transpose(squeeze(rp[m, n, o, :]))
                    m = Npuntix
                    r7 = transpose(squeeze(rp[m, n, o, :]))
                else
                    m = 1
                    r3 = transpose(squeeze(0.5 * (rp[m, n, o, :] + rp[m, n-1, o, :])))
                    m = Npuntix
                    r7 = transpose(squeeze(0.5 * (rp[m, n, o, :] + rp[m, n-1, o, :])))
                end
            else
                if n == 1
                    m = 1
                    r3 = transpose(squeeze(0.5 * (rp[m, n, o, :] + rp[m, n, o+1, :])))
                    m = Npuntix
                    r7 = transpose(squeeze(0.5 * (rp[m, n, o, :] + rp[m, n, o+1, :])))
                else
                    m = 1
                    r3 = transpose(squeeze(0.25 * (rp[m, n, o, :] + rp[m, n-1, o, :] + rp[m, n, o+1, :] + rp[m, n-1, o+1, :])))
                    m = Npuntix
                    r7 = transpose(squeeze(0.25 * (rp[m, n, o, :] + rp[m, n-1, o, :] + rp[m, n, o+1, :] + rp[m, n-1, o+1, :])))
                end
            end
            # punti r4 ed r8
            if o == Npuntiz
                if n == Npuntiy
                    m = 1
                    r4 = transpose(squeeze(rp[m, n, o, :]))
                    m = Npuntix
                    r8 = transpose(squeeze(rp[m, n, o, :]))
                else
                    m = 1
                    r4 = transpose(squeeze(0.5 * (rp[m, n, o, :] + rp[m, n+1, o, :])))
                    m = Npuntix
                    r8 = transpose(squeeze(0.5 * (rp[m, n, o, :] + rp[m, n+1, o, :])))
                end
            else
                if n == Npuntiy
                    m = 1
                    r4 = transpose(squeeze(0.5 * (rp[m, n, o, :] + rp[m, n, o+1, :])))
                    m = Npuntix
                    r8 = transpose(squeeze(0.5 * (rp[m, n, o, :] + rp[m, n, o+1, :])))
                else
                    m = 1
                    r4 = transpose(squeeze(0.25 * (rp[m, n, o, :] + rp[m, n+1, o, :] + rp[m, n, o+1, :] + rp[m, n+1, o+1, :])))
                    m = Npuntix
                    r8 = transpose(squeeze(0.25 * (rp[m, n, o, :] + rp[m, n+1, o, :] + rp[m, n, o+1, :] + rp[m, n+1, o+1, :])))
                end
            end
            
            celle_cap[r, :] = [r1 r2 r3 r4]
            celle_cap[r+1, :] = [r5 r6 r7 r8]
            Nodi[r, :] = transpose(squeeze(rp[1, n, o, :]))
            Nodi[r+1, :] = transpose(squeeze(rp[Npuntix, n, o, :]))
            Sup_c[r] = surfa_old(celle_cap[r, :], weights_five, roots_five)
            Sup_c[r+1] = surfa_old(celle_cap[r+1, :], weights_five, roots_five)
            # Per il calcolo della lunghezza e della larghezza assumo che l_c sia nella direzione 1 e che width_c nella direzione 2
            l_c[r] = abs(mean_length_P(celle_cap[r, :], 1))
            width_c[r] = abs(mean_length_P(celle_cap[r, :], 2))
            l_c[r+1] = abs(mean_length_P(celle_cap[r+1, :], 1))
            width_c[r+1] = abs(mean_length_P(celle_cap[r+1, :], 2))
            
            r += 2
        end # ciclo n
    end # ciclo o
    # Riduzione nodi capacitivi
    NumNodiCap = size(Nodi, 1)
    NodiRed = zeros(Npuntix * Npuntiy * Npuntiz - (Npuntix - 2) * (Npuntiy - 2) * (Npuntiz - 2), 3)

    if NumNodiCap > 1
        NodiRed[1, :] = Nodi[1, :]
        nodoAct = 2
        for k in 2:NumNodiCap
            m = findall(!iszero,
                (abs.(NodiRed[:, 1] .- Nodi[k, 1]) .<= 1e-11) .&&
                (abs.(NodiRed[:, 2] .- Nodi[k, 2]) .<= 1e-11) .&&
                (abs.(NodiRed[:, 3] .- Nodi[k, 3]) .<= 1e-11))
            if isempty(m)
                NodiRed[nodoAct, :] = Nodi[k, :]
                nodoAct += 1
            end  # if
        end  # for k
    end  # if NumNodiCap

    return celle_cap,Nodi,Sup_c,l_c,width_c,NodiRed
end
