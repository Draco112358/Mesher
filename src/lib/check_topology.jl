using Meshing, StaticArrays
include("buildSTL.jl")

# Funzione per unire cubi adiacenti
function merge_adjacent_cubes(matrix, nvoxels, cell_size, n_materials, materials)
    nx = nvoxels[1]
    ny = nvoxels[2]
    nz = nvoxels[3]
    merged_boxes = []
    for x in range(1, n_materials)
        push!(merged_boxes, [])
    end

    visited = falses(n_materials, nx, ny, nz)
    matrix2 = falses(n_materials, nx, ny, nz)

    for j in 1:n_materials, x in 1:nx, y in 1:ny, z in 1:nz
        matrix2[j,x,y,z] = matrix[materials[j]][x][y][z]
    end

    # Scorri la griglia e trova blocchi rettangolari
    for j in 1:n_materials, x in 1:nx, y in 1:ny, z in 1:nz
        if matrix2[j,x,y,z] && !visited[j, x, y, z]
            # Trova il blocco massimo a partire da questo cubo
            x2, y2, z2 = find_block(matrix2, nvoxels, visited, x, y, z, j)
            #println(x2, " ", y2, " ", z2)
            push!(merged_boxes[j], Box(Meshes.Point3f((x - 1) * cell_size[1], (y - 1) * cell_size[2], (z - 1) * cell_size[3]),
                                     Meshes.Point3f(x2 * cell_size[1], y2 * cell_size[2], z2 * cell_size[3])))
        end
    end

    return merged_boxes
end

# Trova il blocco rettangolare massimo a partire da (x, y, z)
function find_block(matrix, nvoxels, visited, x, y, z, j)
    nx = nvoxels[1]
    ny = nvoxels[2]
    nz = nvoxels[3]
    x2, y2, z2 = x, y, z

    # Estendi lungo l'asse X
    while x2 < nx && all(matrix[j,x2 + 1,y,z]) && !all(visited[j,x2 + 1, y, z])
        x2 += 1
    end

    # Estendi lungo l'asse Y
    while y2 < ny && all(matrix[j,x:x2,y2 + 1,z]) && !all(visited[j,x:x2, y2 + 1, z])
        y2 += 1
    end

    # Estendi lungo l'asse Z
    while z2 < nz && all(matrix[j,x:x2,y:y2,z2 + 1]) && !all(visited[j,x:x2, y:y2, z2 + 1])
        z2 += 1
    end

    # Segna tutti i voxel del blocco come visitati
    visited[j,x:x2, y:y2, z:z2] .= true

    return x2, y2, z2
end

# Creazione della mesh da box uniti
function boxes_to_mesh(boxes)
    vertices::Vector{Meshes.Point3f} = []
    faces::Array{Connectivity{Meshes.Triangle, 3}} = []

    for box in boxes
        cube_verts, cube_faces = cube_to_triangles(box)
        vert_offset = length(vertices)
        append!(vertices, cube_verts)
        append!(faces, [Meshes.connect(vert_offset .+ face) for face in cube_faces])
    end

    return SimpleMesh(vertices, faces)
end

# Converte un box in triangoli
function cube_to_triangles(box)
    min_point = box.min
    max_point = box.max
    verts = [
        Meshes.Point3f(min_point.coords[1], min_point.coords[2], min_point.coords[3]),
        Meshes.Point3f(max_point.coords[1], min_point.coords[2], min_point.coords[3]),
        Meshes.Point3f(max_point.coords[1], max_point.coords[2], min_point.coords[3]),
        Meshes.Point3f(min_point.coords[1], max_point.coords[2], min_point.coords[3]),
        Meshes.Point3f(min_point.coords[1], min_point.coords[2], max_point.coords[3]),
        Meshes.Point3f(max_point.coords[1], min_point.coords[2], max_point.coords[3]),
        Meshes.Point3f(max_point.coords[1], max_point.coords[2], max_point.coords[3]),
        Meshes.Point3f(min_point.coords[1], max_point.coords[2], max_point.coords[3]),
    ]

    faces = [
        (1, 2, 3), (1, 3, 4),  # Inferiore
        (5, 6, 7), (5, 7, 8),  # Superiore
        (1, 2, 6), (1, 6, 5),  # Fronte
        (2, 3, 7), (2, 7, 6),  # Destra
        (3, 4, 8), (3, 8, 7),  # Posteriore
        (4, 1, 5), (4, 5, 8)   # Sinistra
    ]

    return verts, faces
end

function are_topologies_equivalent(top1, top2)
    # Controlla se i rank sono identici
    # println(length(top1.ranks))
    # println(length(top2.ranks))
    if top1.ranks != top2.ranks
        return false
    end

    # Ottieni gli elementi di entrambe le topologie
    elems1 = top1.elms
    elems2 = top2.elms

    # Controlla il numero di elementi
    if length(elems1) != length(elems2)
        return false
    end

    # Normalizza i triangoli ordinando i vertici
    normalized_elems1 = Set(sort(elems1))
    normalized_elems2 = Set(sort(elems2))

    # Controlla se i set di triangoli normalizzati sono uguali
    return normalized_elems1 == normalized_elems2
end

function checkTopology(meshes_stl_converted, mesh)
    matrix = mesh["mesher_matrices"]
    n_materials = mesh["n_materials"]
    materials = []
    for pair in mesh["materials"]
        push!(materials, pair[2])
    end
    cell_size = SVector(mesh["cell_size"]["cell_size_x"], mesh["cell_size"]["cell_size_y"], mesh["cell_size"]["cell_size_z"])
    nvoxels = [Int64(mesh["n_cells"]["n_cells_x"]), Int64(mesh["n_cells"]["n_cells_y"]), Int64(mesh["n_cells"]["n_cells_z"])]
    boxes = merge_adjacent_cubes(matrix, nvoxels, cell_size, n_materials, materials)
    meshes = []
    for k in range(1, n_materials)
        #merged_boxes2 = merge_adjacent_boxes(boxes[k])
        mesh = boxes_to_mesh(boxes[k])
        push!(meshes, mesh)
    end

    verticesArray = []
    facesArray = []
    singleMeshes = []

    for m in meshes
        push!(singleMeshes, SimpleMesh(vertices(m), m.topology.connec))
        verticesArray = [verticesArray..., vertices(m)...]
        facesArray = [facesArray..., m.topology.connec...]
    end

    singleMeshesStl = []

    for msc in meshes_stl_converted
        push!(singleMeshesStl, SimpleMesh(vertices(msc), msc.topology.connec))
    end

    equal = false

    for (index, sm) in enumerate(singleMeshes)
        top1 = sm.topology
        top2 = singleMeshesStl[index].topology
        println(length(unique(vertices(sm))))
        println(length(unique(vertices(singleMeshesStl[index]))))
        println(are_topologies_equivalent(top1, top2))
        if are_topologies_equivalent(top1, top2)
            equal = true
        else
            equal = false
        end
    end

    # grouped_mesh = SimpleMesh(verticesArray, facesArray)

    # verticesArray2 = []
    # facesArray2 = []

    # for mesh_stl_converted in meshes_stl_converted
    #     verticesArray2 = [verticesArray2..., vertices(mesh_stl_converted)...]
    #     facesArray2 = [facesArray2..., mesh_stl_converted.topology.connec...]
    # end

    # grouped_mesh_stl_converted = SimpleMesh(verticesArray2, facesArray2)

    # topology_grouped_mesh = grouped_mesh.topology
    # topology_grouped_mesh_stl_converted = grouped_mesh_stl_converted.topology

    #println("Are topologies equivalent?: ", are_topologies_equivalent(topology_grouped_mesh, topology_grouped_mesh_stl_converted))

    return equal
end