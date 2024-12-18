function squeeze(A)
    return reshape(A, size(A)[[i for i in 1:ndims(A) if size(A, i) > 1]])  # Removes singleton dimensions
end