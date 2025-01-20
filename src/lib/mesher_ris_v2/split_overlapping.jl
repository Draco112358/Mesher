function split_overlapping(barra1, barra2, mat1, mat2, materiale_dominante)
    # Indexes for x, y, and z
    indici_x = [1, 4, 7, 10, 13, 16, 19, 22]
    indici_y = [2, 5, 8, 11, 14, 17, 20, 23]
    indici_z = [3, 6, 9, 12, 15, 18, 21, 24]

    # Extracting coordinates for barra1
    x1 = round(1e14 * minimum(barra1[indici_x])) / 1e14
    x2 = round(1e14 * maximum(barra1[indici_x])) / 1e14
    y1 = round(1e14 * minimum(barra1[indici_y])) / 1e14
    y2 = round(1e14 * maximum(barra1[indici_y])) / 1e14
    z1 = round(1e14 * minimum(barra1[indici_z])) / 1e14
    z2 = round(1e14 * maximum(barra1[indici_z])) / 1e14

    # Extracting coordinates for barra2
    x3 = round(1e14 * minimum(barra2[indici_x])) / 1e14
    x4 = round(1e14 * maximum(barra2[indici_x])) / 1e14
    y3 = round(1e14 * minimum(barra2[indici_y])) / 1e14
    y4 = round(1e14 * maximum(barra2[indici_y])) / 1e14
    z3 = round(1e14 * minimum(barra2[indici_z])) / 1e14
    z4 = round(1e14 * maximum(barra2[indici_z])) / 1e14

    # Checking for overlap in x, y, and z directions
    overllapped_x = 0
    overllapped_y = 0
    overllapped_z = 0

    if (x1 >= x3 && x4 > x1) || (x3 < x2 && x3 >= x1)
        overllapped_x = 1
    end

    if (y1 >= y3 && y4 > y1) || (y3 < y2 && y3 >= y1)
        overllapped_y = 1
    end

    if (z1 >= z3 && z4 > z1) || (z3 < z2 && z3 >= z1)
        overllapped_z = 1
    end

    # Final overlap check
    isOverlapped = overllapped_x * overllapped_y * overllapped_z


    # Combine the two bars into barre_out and mat_out
    barre_out = vcat(barra1, barra2)
    mat_out = vcat(mat1, mat2)

    if isOverlapped == 1
        # Calculate intersection coordinates
        x1_inter = max(x1, x3)
        x2_inter = min(x2, x4)
        y1_inter = max(y1, y3)
        y2_inter = min(y2, y4)
        z1_inter = max(z1, z3)
        z2_inter = min(z2, z4)


        # Create the overlapping portion of the bar
        barra_overlapping = zeros(1, 24)
        barra_overlapping[[1, 7, 13, 19]] .= min(x1_inter, x2_inter)
        barra_overlapping[[4, 10, 16, 22]] .= max(x1_inter, x2_inter)
        barra_overlapping[[2, 5, 14, 17]] .= min(y1_inter, y2_inter)
        barra_overlapping[[8, 11, 20, 23]] .= max(y1_inter, y2_inter)
        barra_overlapping[[3, 6, 9, 12]] .= min(z1_inter, z2_inter)
        barra_overlapping[[15, 18, 21, 24]] .= max(z1_inter, z2_inter)


        # Determine which bar to split
        if mat1 == materiale_dominante
            barre_out = barra1
            mat_out = mat1
            barra_to_split = barra2
            mat_to_split = mat2
        else
            barre_out = barra2
            mat_out = mat2
            barra_to_split = barra1
            mat_to_split = mat1
        end

        # Split along the x-direction
        barre = spezza_x(barra_to_split, x1_inter, x2_inter)
        N = size(barre, 1)
        coord = zeros(0, 24)
        # Split along the y-direction
        for cont in 1:N
            y = spezza_y(barre[cont, :], y1_inter, y2_inter)
            coord = vcat(coord, y)
            #println(size(coord))
        end

        N = size(coord, 1)
        barre = zeros(0, 24)
        # Split along the z-direction
        for cont in 1:N
            z = spezza_z(coord[cont, :], z1_inter, z2_inter)
            barre = vcat(barre, z)
        end

        N = size(barre, 1)
        to_remove = 0
        barre_out = reshape(barre_out, (size(barre_out, 1) ÷ 24, 24))
        # Remove overlapping portion if it matches
        for cont in 1:N
            if norm(vec(barra_overlapping) - barre[cont, :]) < 1e-10
                to_remove = cont
                break
            end
        end

        if to_remove > 0
            to_keep = setdiff(1:N, to_remove)
            barre_out = vcat(barre_out, barre[to_keep, :])
            mat_out = vcat(mat_out, ones(N - 1, 1) * mat_to_split)
        end
    end
    return barre_out, isOverlapped, mat_out
end

# Supporting functions: spezza_x, spezza_y, spezza_z
function spezza_x(barra, x1_inter, x2_inter)
    indici_x = [1, 4, 7, 10, 13, 16, 19, 22]

    x1 = round(1e15 * minimum(barra[indici_x])) / 1e15
    x2 = round(1e15 * maximum(barra[indici_x])) / 1e15


    vect_x = unique(sort([x1, x2, x1_inter, x2_inter]))
    coord = zeros(length(vect_x) - 1, 24)
    for cont in 1:(length(vect_x) - 1)
        coord[cont, :] .= barra
        coord[cont, [1, 7, 13, 19]] .= vect_x[cont]
        coord[cont, [4, 10, 16, 22]] .= vect_x[cont + 1]
    end

    return coord
end

function spezza_y(barra, y1_inter, y2_inter)
    indici_y = [2, 5, 8, 11, 14, 17, 20, 23]

    y1 = round(1e14 * minimum(barra[indici_y])) / 1e14
    y2 = round(1e14 * maximum(barra[indici_y])) / 1e14

    vect_y = unique(sort([y1, y2, y1_inter, y2_inter]))
    coord = zeros(length(vect_y) - 1, 24)
    for cont in 1:(length(vect_y) - 1)
        coord[cont, :] .= barra
        coord[cont, [2, 5, 14, 17]] .= vect_y[cont]
        coord[cont, [8, 11, 20, 23]] .= vect_y[cont + 1]
    end

    return coord
end

function spezza_z(barra, z1_inter, z2_inter)
    indici_z = [3, 6, 9, 12, 15, 18, 21, 24]

    z1 = round(1e14 * minimum(barra[indici_z])) / 1e14
    z2 = round(1e14 * maximum(barra[indici_z])) / 1e14

    vect_z = unique(sort([z1, z2, z1_inter, z2_inter]))
    coord = zeros(length(vect_z) - 1, 24)
    for cont in 1:(length(vect_z) - 1)
        coord[cont, :] .= barra
        coord[cont, [3, 6, 9, 12]] .= vect_z[cont]
        coord[cont, [15, 18, 21, 24]] .= vect_z[cont + 1]
    end

    return coord
end
