function verifica_nodo_interno(Nodi_interni, Nodo)
    n_nodi_interni = size(Nodi_interni, 1)
    flag = true

    # Check if the node is very close to any of the internal nodes
    for k in 1:n_nodi_interni
        if norm(Nodi_interni[k, :] .- Nodo) < 1e-10
            flag = false
            break
        end
    end

    # Return result based on the flag
    if flag == "yes"
        return Nodo
    else
        return []
    end
end
