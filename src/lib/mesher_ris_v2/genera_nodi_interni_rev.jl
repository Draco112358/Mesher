function genera_nodi_interni_rev(xyz, Npuntix, Npuntiy, Npuntiz)
    a = range(-1, 1, Int64(Npuntix))  # linspace in Julia
    b = range(-1, 1, Int64(Npuntiy))
    c = range(-1, 1, Int64(Npuntiz))

    ri = reshape(xyz, 3, 8)  # Reshaping xyz into a 3x8 matrix
    rmi, rai, rbi, rci, rabi, rbci, raci, rabci = interpolating_vectors_rev(ri)

    rp = zeros(max(Int64(Npuntiz), Int64(Npuntix)), Int64(Npuntiy), max(Int64(Npuntiz), Int64(Npuntix)), 3)  # Initialize rp as a 4D array
    for n in 1:Int64(Npuntiz)
        for m in 1:Int64(Npuntiy)
            for l in 1:Int64(Npuntix)
                # rp[l, m, n, :] .= (rmi .+ rai .* a[l] + rbi .* b[m] + rci .* c[n] +
                #                   rabi .* a[l] .* b[m] + rbci .* b[m] .* c[n] + 
                #                   raci .* a[l] .* c[n] + rabci .* a[l] .* b[m] .* c[n])
                rp[l, m, n, :] .= (rmi + rai .* a[l] + rbi .* b[m] + rci .* c[n] +
                                    rabi .* a[l] .* b[m] + rbci .* b[m] .* c[n] +
                                    raci .* a[l] .* c[n] + rabci .* a[l] .* b[m] .* c[n])
            end
        end
    end

    # Identify internal nodes
    Nodi_interni = zeros(0, 3)
    for o in 2:Int64(Npuntiz)-1
        for n in 2:Int64(Npuntiy)-1
            for m in 2:Int64(Npuntix)-1
                Nodi_interni = vcat(Nodi_interni, transpose(squeeze(rp[m, n, o, :])))
            end
        end
    end
    return Nodi_interni
end
