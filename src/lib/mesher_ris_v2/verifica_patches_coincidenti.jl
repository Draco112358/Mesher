function verifica_patches_coincidenti(nodi_estremi_celle)
    r = zeros(size(nodi_estremi_celle, 1), 4, 3)
    
    # Assign values from nodi_estremi_celle to r
    r[:, 1, :] = nodi_estremi_celle[:, 1:3]
    r[:, 2, :] = nodi_estremi_celle[:, 4:6]
    r[:, 3, :] = nodi_estremi_celle[:, 7:9]
    r[:, 4, :] = nodi_estremi_celle[:, 10:12]

    coinc = zeros(4)
    
    for n in 1:4
        coinc[n] = 0
        for m in 1:4
            dist_mn = norm(reshape(r[1, m, :] - r[2, n, :], 1, 3), 2)
            if dist_mn < 1e-12
                coinc[n] = 1
            end
        end
    end

    if all(coinc .== 1)
        coinc_fin = true
    else
        coinc_fin = false
    end
    return coinc_fin
end
