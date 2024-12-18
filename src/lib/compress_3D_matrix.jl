function compress_3D_matrix(input3D_mat, Nx, Ny, Nz)
    N = Nx * Ny * Nz
    numbit_com = 50
    Nc = ceil(Int, N / numbit_com)
    vect_app = falses(Nc * numbit_com)

    cont = 1
    for pl in 1:Nx, pj in 1:Ny, pk in 1:Nz
        vect_app[cont] = input3D_mat[pl, pj, pk]
        cont += 1
    end

    compressed_mat = zeros(Int, Nc)

    st = 1
    en = numbit_com
    pos = 1
    for k in 1:Nc
        compressed_mat[pos] = compress_1_byte_sequence(vect_app[st:en])
        pos += 1
        st = en + 1
        en += numbit_com
    end

    return compressed_mat
end

function compress_1_byte_sequence(input_seq)
    res = 0
    len = length(input_seq)
    for k in 1:len
        res += input_seq[k] * 2^(len - k)
    end
    return res
end
