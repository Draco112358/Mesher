include("distfcm.jl")

function find_nodes_ports_or_le(ports, lumped_elements, nodi_coord, scalamento)
    Np = size(ports[:port_start], 1)
    
    # Initialize the port nodes
    ports[:port_nodes] = zeros(Np, 2)
    
    # Find port start and end nodes by scaling and calling nodes_find_rev
    ports[:port_nodes][:, 1] = nodes_find_rev(ports[:port_start] * scalamento, nodi_coord)
    ports[:port_nodes][:, 2] = nodes_find_rev(ports[:port_end] * scalamento, nodi_coord)

    Nle = size(lumped_elements[:le_start], 1)

    # Initialize the lumped element nodes
    lumped_elements[:le_nodes] = zeros(Nle, 2)
    
    # Find lumped element start and end nodes by scaling and calling nodes_find_rev
    lumped_elements[:le_nodes][:, 1] = nodes_find_rev(lumped_elements[:le_start] * scalamento, nodi_coord)
    lumped_elements[:le_nodes][:, 2] = nodes_find_rev(lumped_elements[:le_end] * scalamento, nodi_coord)

    return ports, lumped_elements
end

function nodes_find_rev(Nodes_inp_coord, nodi_centri)
    nodes = zeros(size(Nodes_inp_coord, 1), 1)
    
    for k in range(1,size(Nodes_inp_coord, 1))
        # Compute the distances using distfcm, find minimum distances and corresponding node index
        dist = distfcm(Nodes_inp_coord[k, :], nodi_centri)
        nodes_app = findfirst(vec(dist) .== minimum(dist))
        nodes[k] = nodes_app
    end
    
    return nodes
end
