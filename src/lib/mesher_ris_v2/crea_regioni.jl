include("round_ud.jl")
include("sistema_coordinate.jl")
include("solve_overlapping.jl")


function crea_regioni(bricks, bricks_material, materials)
    N = size(bricks, 1)
    coord = zeros(N, 24)
    for k in 1:N
        coord = aggiungiBlocco(coord, k, bricks[k, 1], bricks[k, 2], bricks[k, 3], bricks[k, 4], bricks[k, 5], bricks[k, 6])
    end

    mat_conductors_index = []
    for (index, mat) in enumerate(materials)
        if mat[:sigmar] != 0
            push!(mat_conductors_index, index)
        end
    end

    # Solve overlapping and coordinate system transformation
    coord, bricks_material = solve_overlapping_new(coord, bricks_material, mat_conductors_index)
    coord, bricks_material = sistema_coordinate(round_ud(coord, 8), bricks_material)
    Nnew = size(coord, 1)
    Regioni = Dict(
        :coordinate => zeros(Nnew, 24),
        :cond => zeros(Nnew),
        :epsr => zeros(Nnew),
        :mu => zeros(Nnew),
        :mur => zeros(Nnew),
        :materials => zeros(Nnew)
    )

    # Case for conductors
    st = 1
    for k in range(1,size(materials, 1))
        if abs(materials[k][:sigmar]) > 1e-10
            ind = findall(x -> x == k, bricks_material)
            en = st - 1 + length(ind)
            Regioni[:coordinate][st:en, :] .= round_ud(coord[ind, :], 8)
            Regioni[:cond][st:en] .= materials[k][:sigmar]
            Regioni[:epsr][st:en] .= materials[k][:eps_re]
            Regioni[:mu][st:en] .= 4 * π * 1e-7 * materials[k][:mur]
            Regioni[:mur][st:en] .= materials[k][:mur]
            Regioni[:materials][st:en] .= k
            st = en + 1
        end
    end

    # Case for dielectrics (Dielectrics should always be after all conductors)
    for k in range(1,size(materials, 1))
        if abs(materials[k][:sigmar]) < 1e-10
            ind = findall(x -> x == k, bricks_material)
            en = st - 1 + length(ind)
            Regioni[:coordinate][st:en, :] .= round_ud(coord[ind, :], 8)
            Regioni[:cond][st:en] .= materials[k][:sigmar]
            Regioni[:epsr][st:en] .= materials[k][:eps_re]
            Regioni[:mu][st:en] .= 4 * π * 1e-7 * materials[k][:mur]
            Regioni[:mur][st:en] .= materials[k][:mur]
            Regioni[:materials][st:en] .= k
            st = en + 1
        end
    end

    return Regioni
end

function aggiungiBlocco(geo, pos, x1, x2, y1, y2, z1, z2)
    geo[pos, :] .= [
        min(x1, x2), min(y1, y2), min(z1, z2),
        max(x1, x2), min(y1, y2), min(z1, z2),
        min(x1, x2), max(y1, y2), min(z1, z2),
        max(x1, x2), max(y1, y2), min(z1, z2),
        min(x1, x2), min(y1, y2), max(z1, z2),
        max(x1, x2), min(y1, y2), max(z1, z2),
        min(x1, x2), max(y1, y2), max(z1, z2),
        max(x1, x2), max(y1, y2), max(z1, z2)
    ]
    return geo
end
