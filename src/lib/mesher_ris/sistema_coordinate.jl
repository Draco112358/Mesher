include("round_ud.jl")
include("interpolating_vectors.jl")
include("squeeze.jl")

function sistema_coordinate(coord, materiale)
    nBarre = size(coord, 1)
    coord = round_ud(coord, 10)
    new_coord = coord
    
    if nBarre > 1
        continua = 1
        c1 = 1
        c2 = c1 + 1
        
        while c1 < nBarre
            while continua == 1 && c2 <= nBarre
                if c1 != c2
                    cutted, a, b, c, inverted, c_o1, c_o2 = verifyTouchObj(coord[c1, :], coord[c2, :])
                    
                    if cutted == 1
                        if inverted == 0
                            auxCord = taglia(coord[c1, :], a, b, c, c_o1)
                            indiciNotCut = setdiff(1:nBarre, c1)
                            new_coord = vcat(auxCord, coord[indiciNotCut, :])
                            new_materiale = vcat(ones(size(auxCord, 1)) * materiale[c1], materiale[indiciNotCut])
                        else
                            auxCord = taglia(coord[c2, :], a, b, c, c_o2)
                            indiciNotCut = setdiff(1:nBarre, c2)
                            new_coord = vcat(auxCord, coord[indiciNotCut, :])
                            new_materiale = vcat(ones(size(auxCord, 1)) * materiale[c2], materiale[indiciNotCut])
                        end
                        
                        nBarre -= 1
                        nBarre += size(auxCord, 1)
                        continua = 0
                        c1 = 0
                        coord = new_coord
                        materiale = new_materiale
                        coord = round_ud(coord, 10)
                    end
                end
                c2 += 1
            end
            c1 += 1
            c2 = c1 + 1
            continua = 1
        end
    end
    
    return new_coord, materiale
end

function getFace(n, obj)
    if n == 1
        ind = [1:6..., 13:18...]
    elseif n == 2
        ind = [4:6..., 10:12..., 16:18..., 22:24...]
    elseif n == 3
        ind = [7:12..., 19:24...]
    elseif n == 4
        ind = [1:3..., 7:9..., 13:15..., 19:21...]
    elseif n == 5
        ind = [1:12...]
    else
        ind = [13:24...]
    end
    face = obj[ind]
    return face
end

function control_share(f1, f2, norma)
    shared = 0
    cutted = 0
    ind_x = [1, 4, 7, 10]
    ind_y = [2, 5, 8, 11]
    ind_z = [3, 6, 9, 12]
    a = [-1, 1]
    b = [-1, 1]
    c = [-1, 1]

    if norm([0, 0, 1] - norma) < 1e-10
        if abs(f1[12] - f2[12]) > 1e-10
            cutted = 0
        else
            sharex, vectx = find_cut(f1, f2, ind_x)
            sharey, vecty = find_cut(f1, f2, ind_y)
            a = cambio(sort(unique(vectx)))
            b = cambio(sort(unique(vecty)))
            shared = sharex * sharey
        end
    elseif norm([0, 1, 0] - norma) < 1e-10
        if abs(f1[2] - f2[2]) > 1e-10
            cutted = 0
        else
            sharex, vectx = find_cut(f1, f2, ind_x)
            sharez, vectz = find_cut(f1, f2, ind_z)
            a = cambio(sort(unique(vectx)))
            c = cambio(sort(unique(vectz)))
            shared = sharex * sharez
        end
    elseif norm([1, 0, 0] - norma) < 1e-10
        if abs(f1[1] - f2[1]) > 1e-10
            cutted = 0
        else
            sharey, vecty = find_cut(f1, f2, ind_y)
            sharez, vectz = find_cut(f1, f2, ind_z)
            c = cambio(sort(unique(vectz)))
            b = cambio(sort(unique(vecty)))
            shared = sharey * sharez
        end
    end

    if shared == 1
        if length(a) > 2
            b = [-1, 1]
            c = [-1, 1]
            cutted = 1
        elseif length(b) > 2
            a = [-1, 1]
            c = [-1, 1]
            cutted = 1
        elseif length(c) > 2
            a = [-1, 1]
            b = [-1, 1]
            cutted = 1
        end
    end

    inverted = 0

    if cutted == 0
        inverted = 1
        if norm([0, 0, 1] - norma) < 1e-10
            if abs(f1[12] - f2[12]) > 1e-10
                cutted = 0
            else
                sharex, vectx = find_cut(f2, f1, ind_x)
                sharey, vecty = find_cut(f2, f1, ind_y)
                a = cambio(sort(unique(vectx)))
                b = cambio(sort(unique(vecty)))
                shared = sharex * sharey
            end
        elseif norm([0, 1, 0] - norma) < 1e-10
            if abs(f1[2] - f2[2]) > 1e-10
                cutted = 0
            else
                sharex, vectx = find_cut(f2, f1, ind_x)
                sharez, vectz = find_cut(f2, f1, ind_z)
                a = cambio(sort(unique(vectx)))
                c = cambio(sort(unique(vectz)))
                shared = sharex * sharez
            end
        elseif norm([1, 0, 0] - norma) < 1e-10
            if abs(f1[1] - f2[1]) > 1e-10
                cutted = 0
            else
                sharey, vecty = find_cut(f2, f1, ind_y)
                sharez, vectz = find_cut(f2, f1, ind_z)
                c = cambio(sort(unique(vectz)))
                b = cambio(sort(unique(vecty)))
                shared = sharey * sharez
            end
        end

        if shared == 1
            if length(a) > 2
                b = [-1, 1]
                c = [-1, 1]
                cutted = 1
            elseif length(b) > 2
                a = [-1, 1]
                c = [-1, 1]
                cutted = 1
            elseif length(c) > 2
                a = [-1, 1]
                b = [-1, 1]
                cutted = 1
            end
        end
    end
    return cutted,a,b,c,inverted
end

function computeNormale(f1)
    norm1 = cross(f1[4:6] - f1[1:3], f1[7:9] - f1[1:3])
    norm1 = norm1 ./ sqrt(sum(norm1.^2))
    return norm1
end

function checkTouchObj(f1, f2)
    inverted = 0
    is_orto1, norm1, f1 = apply_convention(f1)
    is_orto2, norm2, f2 = apply_convention(f2)

    idemIncli = norm(norm1 - norm2)

    cutted = 0
    a = [-1, 1]
    b = [-1, 1]
    c = [-1, 1]

    if idemIncli < 1e-12 && is_orto1 == 1 && is_orto2 == 1
        cutted, a, b, c, inverted = control_share(f1, f2, norm1)
    end

    return cutted, a, b, c, inverted
end

function find_cut(f1, f2, ind)
    share = 0

    # Extract coordinates using indices
    c1, c2 = f1[ind[1]], f1[ind[4]]
    c3, c4 = f2[ind[1]], f2[ind[4]]
    vect = [-1.0, 1.0]

    # Determine vect based on conditions
    if c1 < c4 && c2 > c4
        vect = unique([c1, c4, c2])
    elseif c1 < c3 && c2 > c3
        vect = unique([c1, c3, c2])
    end

    # Determine share based on overlapping conditions
    if (c1 >= c3 && c4 >= c1) || (c2 >= c3 && c4 >= c2) || 
       (c3 >= c1 && c2 >= c3) || (c4 >= c1 && c2 >= c4)
        share = 1
    end

    return share, vect
end


function verifyTouchObj(obj1, obj2)
    cutted = 0
    inverted = 0
    c1 = 1
    continua = 1
    a = [-1, 1]
    b = [-1, 1]
    c = [-1, 1]
    c_o1 = 1
    c_o2 = 1
    while continua == 1 && c1 <= 6
        c2 = 1
        while continua == 1 && c2 <= 6
            f1 = getFace(c1, obj1)
            f2 = getFace(c2, obj2)
            cutted, a, b, c, inverted = checkTouchObj(f1, f2)
            if cutted == 1
                continua = 0
                c_o1 = c1
                c_o2 = c2
            end
            c2 += 1
        end
        c1 += 1
    end
    return cutted, a, b, c, inverted, c_o1, c_o2
end

function cambio(r)
    h = size(r, 1)  # Get the number of columns in the array
    rm = (r[1] + r[h]) / 2  # Calculate the midpoint
    r12 = (r[h] - r[1]) / 2  # Calculate half the range
    a = zeros(1, h)  # Initialize the result array with zeros
    for i in 1:h
        a[i] = (r[i] - rm) / r12  # Apply the transformation for each element
    end
    return a  # Return the transformed array
end

function apply_convention(f)
    is_orto = 0
    ind_x = [1, 4, 7, 10]
    ind_y = [2, 5, 8, 11]
    ind_z = [3, 6, 9, 12]

    x = sort(f[ind_x])
    y = sort(f[ind_y])
    z = sort(f[ind_z])

    f_out = f
    norma = abs.(computeNormale(f))

    if norm(norma - [1, 0, 0]) < 1e-12 && length(unique(y)) == 2 && length(unique(z)) == 2
        f_out = [x[1], y[1], z[1], x[1], y[4], z[1], x[1], y[1], z[4], x[1], y[4], z[4]]
        is_orto = 1
    end

    if norm(norma - [0, 1, 0]) < 1e-12 && length(unique(x)) == 2 && length(unique(z)) == 2
        f_out = [x[1], y[1], z[1], x[4], y[1], z[1], x[1], y[1], z[4], x[4], y[1], z[4]]
        is_orto = 1
    end

    if norm(norma - [0, 0, 1]) < 1e-12 && length(unique(x)) == 2 && length(unique(y)) == 2
        f_out = [x[1], y[1], z[1], x[4], y[1], z[1], x[1], y[4], z[1], x[4], y[4], z[1]]
        is_orto = 1
    end

    permutation = [1:12...]

    v1 = f[1:3]
    v2 = f[4:6]
    v3 = f[7:9]
    v4 = f[10:12]

    v1_out = f_out[1:3]
    v2_out = f_out[4:6]
    v3_out = f_out[7:9]
    v4_out = f_out[10:12]

    if norm(v1 - v1_out) < 1e-12
        permutation[1] = 1
        permutation[2] = 2
        permutation[3] = 3
    end

    if norm(v2 - v1_out) < 1e-12
        permutation[1] = 4
        permutation[2] = 5
        permutation[3] = 6
    end

    if norm(v3 - v1_out) < 1e-12
        permutation[1] = 7
        permutation[2] = 8
        permutation[3] = 9
    end

    if norm(v4 - v1_out) < 1e-12
        permutation[1] = 10
        permutation[2] = 11
        permutation[3] = 12
    end

    if norm(v1 - v2_out) < 1e-12
        permutation[4] = 1
        permutation[5] = 2
        permutation[6] = 3
    end

    if norm(v2 - v2_out) < 1e-12
        permutation[4] = 4
        permutation[5] = 5
        permutation[6] = 6
    end

    if norm(v3 - v2_out) < 1e-12
        permutation[4] = 7
        permutation[5] = 8
        permutation[6] = 9
    end

    if norm(v4 - v2_out) < 1e-12
        permutation[4] = 10
        permutation[5] = 11
        permutation[6] = 12
    end

    if norm(v1 - v3_out) < 1e-12
        permutation[7] = 1
        permutation[8] = 2
        permutation[9] = 3
    end

    if norm(v2 - v3_out) < 1e-12
        permutation[7] = 4
        permutation[8] = 5
        permutation[9] = 6
    end

    if norm(v3 - v3_out) < 1e-12
        permutation[7] = 7
        permutation[8] = 8
        permutation[9] = 9
    end

    if norm(v4 - v3_out) < 1e-12
        permutation[7] = 10
        permutation[8] = 11
        permutation[9] = 12
    end

    if norm(v1 - v4_out) < 1e-12
        permutation[10] = 1
        permutation[11] = 2
        permutation[12] = 3
    end

    if norm(v2 - v4_out) < 1e-12
        permutation[10] = 4
        permutation[11] = 5
        permutation[12] = 6
    end

    if norm(v3 - v4_out) < 1e-12
        permutation[10] = 7
        permutation[11] = 8
        permutation[12] = 9
    end

    if norm(v4 - v4_out) < 1e-12
        permutation[10] = 10
        permutation[11] = 11
        permutation[12] = 12
    end

    return is_orto, norma, f_out, permutation
end

function taglia(barra, a, b, c, num_faccia)
    Npuntix = length(a)
    Npuntiy = length(b)
    Npuntiz = length(c)

    indici_x = [1, 4, 7, 10, 13, 16, 19, 22]
    indici_y = [2, 5, 8, 11, 14, 17, 20, 23]
    indici_z = [3, 6, 9, 12, 15, 18, 21, 24]

    val_x = round_ud(barra[indici_x], 10)
    val_y = round_ud(barra[indici_y], 10)
    val_z = round_ud(barra[indici_z], 10)

    if !(length(unique(val_x)) == 2 && length(unique(val_y)) == 2 && length(unique(val_z)) == 2)
        f1 = getFace(num_faccia, barra)
        _, _, f1, permutation = apply_convention(f1)
        f2 = f1

        if num_faccia == 1 || num_faccia == 3
            if num_faccia == 1
                f2 = getFace(3, barra)
            else
                f2 = getFace(1, barra)
            end
        end

        if num_faccia == 2 || num_faccia == 4
            if num_faccia == 2
                f2 = getFace(4, barra)
            else
                f2 = getFace(2, barra)
            end
        end

        if num_faccia == 5 || num_faccia == 6
            if num_faccia == 5
                f2 = getFace(6, barra)
            else
                f2 = getFace(5, barra)
            end
        end

        f2 = f2[permutation]

        if length(a) > 2 || (length(b) > 2 && abs(f1[3] - f1[12]) < 1e-10)
            barra = [f1; f2]
        end

        if length(b) > 2 && abs(f1[3] - f1[12]) > 1e-10
            barra = [f1[[1:3; 7:9; 4:6; 10:12]]; f2[[1:3; 7:9; 4:6; 10:12]]]
        end

        if length(c) > 2
            barra = [f1[1:6]; f2[1:6]; f1[7:12]; f2[7:12]]
        end
    end

    ri = reshape(barra, 3, 8)  # Reshape to a 3x8 array
    rmi, rai, rbi, rci, rabi, rbci, raci, rabci = interpolating_vectors(ri)

    rp = zeros(Npuntix, Npuntiy, Npuntiz, 3)

    # Computing the coordinates for all points
    for n = 1:Npuntiz
        for m = 1:Npuntiy
            for l = 1:Npuntix
                rp[l, m, n, :] .= rmi .+ rai * a[l] .+ rbi * b[m] .+ rci * c[n] .+ rabi * a[l] * b[m] +
                    rbci * b[m] * c[n] + raci * a[l] * c[n] + rabci * a[l] * b[m] * c[n]
            end
        end
    end

    coord = zeros(2, 24)
    # Assign the coordinates based on the length of a, b, and c
    if length(a) > 2
        coord[1, :] = [transpose(squeeze(rp[1, 1, 1, :]))...; transpose(squeeze(rp[2, 1, 1, :]))...; transpose(squeeze(rp[1, 2, 1, :]))...; transpose(squeeze(rp[2, 2, 1, :]))...; 
                        transpose(squeeze(rp[1, 1, 2, :]))...; transpose(squeeze(rp[2, 1, 2, :]))...; transpose(squeeze(rp[1, 2, 2, :]))...; transpose(squeeze(rp[2, 2, 2, :]))...]
        coord[2, :] = [transpose(squeeze(rp[2, 1, 1, :]))...; transpose(squeeze(rp[3, 1, 1, :]))...; transpose(squeeze(rp[2, 2, 1, :]))...; transpose(squeeze(rp[3, 2, 1, :]))...; 
                        transpose(squeeze(rp[2, 1, 2, :]))...; transpose(squeeze(rp[3, 1, 2, :]))...; transpose(squeeze(rp[2, 2, 2, :]))...; transpose(squeeze(rp[3, 2, 2, :]))...]
    end

    if length(b) > 2
        coord[1, :] = [transpose(squeeze(rp[1, 1, 1, :]))...; transpose(squeeze(rp[2, 1, 1, :]))...; transpose(squeeze(rp[1, 2, 1, :]))...; transpose(squeeze(rp[2, 2, 1, :]))...; 
                        transpose(squeeze(rp[1, 1, 2, :]))...; transpose(squeeze(rp[2, 1, 2, :]))...; transpose(squeeze(rp[1, 2, 2, :]))...; transpose(squeeze(rp[2, 2, 2, :]))...]
        coord[2, :] = [transpose(squeeze(rp[1, 2, 1, :]))...; transpose(squeeze(rp[2, 2, 1, :]))...; transpose(squeeze(rp[1, 3, 1, :]))...; transpose(squeeze(rp[2, 3, 1, :]))...; 
                        transpose(squeeze(rp[1, 2, 2, :]))...; transpose(squeeze(rp[2, 2, 2, :]))...; transpose(squeeze(rp[1, 3, 2, :]))...; transpose(squeeze(rp[2, 3, 2, :]))...]
    end

    if length(c) > 2
        coord[1, :] = [transpose(squeeze(rp[1, 1, 1, :]))...; transpose(squeeze(rp[2, 1, 1, :]))...; transpose(squeeze(rp[1, 2, 1, :]))...; transpose(squeeze(rp[2, 2, 1, :]))...; 
                        transpose(squeeze(rp[1, 1, 2, :]))...; transpose(squeeze(rp[2, 1, 2, :]))...; transpose(squeeze(rp[1, 2, 2, :]))...; transpose(squeeze(rp[2, 2, 2, :]))...]
        coord[2, :] = [transpose(squeeze(rp[1, 1, 2, :]))...; transpose(squeeze(rp[2, 1, 2, :]))...; transpose(squeeze(rp[1, 2, 2, :]))...; transpose(squeeze(rp[2, 2, 2, :]))...; 
                        transpose(squeeze(rp[1, 1, 3, :]))...; transpose(squeeze(rp[2, 1, 3, :]))...; transpose(squeeze(rp[1, 2, 3, :]))...; transpose(squeeze(rp[2, 2, 3, :]))...]
    end

    return coord
end
