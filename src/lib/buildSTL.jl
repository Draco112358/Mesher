using Meshing

function are_adjacent(box1::Box, box2::Box)
    for i in 1:3
        if !(box1.min.coords[i] <= box2.max.coords[i] && box1.max.coords[i] >= box2.min.coords[i])
            return false
        end
    end
    return true
end

# Funzione per unire due box
function merge_boxes(box1::Box, box2::Box)
    new_min = (
        min(box1.min.coords[1], box2.min.coords[1]),
        min(box1.min.coords[2], box2.min.coords[2]),
        min(box1.min.coords[3], box2.min.coords[3])
    )
    new_max = (
        max(box1.max.coords[1], box2.max.coords[1]),
        max(box1.max.coords[2], box2.max.coords[2]),
        max(box1.max.coords[3], box2.max.coords[3])
    )
    return Box(new_min, new_max)
end

# Funzione per unire tutti i box adiacenti in una lista
function merge_adjacent_boxes(boxes)
    i = 1
    while i <= length(boxes)
        merged = false
        for j in i+1:length(boxes)
            if are_adjacent(boxes[i], boxes[j])
                # Unisco i due box
                boxes[i] = merge_boxes(boxes[i], boxes[j])
                deleteat!(boxes, j)
                merged = true
                break
            end
        end
        # Se ho unito un box, ripeto per lo stesso indice
        if !merged
            i += 1
        end
    end
    return boxes
end
