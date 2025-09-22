function loadSTL(path,
                             facetype=GeometryBasics.GLTriangleFace,
                             pointtype=GeometryBasics.Point3f,
                             normaltype=GeometryBasics.Vec3f,
                             topology=false)

    #io = FileIO.stream(fs)
    io = open(path, "r")

    points = pointtype[]
    faces = facetype[]
    normals = normaltype[]

    vert_count = 0
    vert_idx = [0, 0, 0]

    line_limit = 1000000
    line_counter = 0

    while !eof(io) && line_counter < line_limit
        line_counter += 1
        line_str = readline(io)
        line = split(lowercase(line_str))
        if !isempty(line) && line[1] == "facet"
            normal = normaltype(parse.(eltype(normaltype), line[3:5]))
            
            readline(io) # Throw away "outer loop"

            for i in 1:3
                vertex_line = split(readline(io))[2:4]
                vertex = pointtype(parse.(eltype(pointtype), vertex_line))
                
                if topology
                    @warn "Topology=true is not fully implemented in this context (missing 'mesh' object)."
                end
                
                push!(points, vertex)
                push!(normals, normal)
                vert_count += 1
                vert_idx[i] = vert_count
            end
            readline(io) # throwout "endloop"
            readline(io) # throwout "endfacet"
            
            push!(faces, GeometryBasics.TriangleFace{Int}(vert_idx...))
        end
    end
    meshes_connectivities = [Meshes.connect(Tuple(face), Meshes.Triangle) for face in faces]


    meshes_points = [Meshes.Point(p) for p in points]
    
    return Meshes.SimpleMesh(meshes_points, meshes_connectivities)
end