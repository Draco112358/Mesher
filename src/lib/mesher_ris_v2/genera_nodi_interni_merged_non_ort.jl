function genera_nodi_interni_merged_non_ort(Regioni, nodi_nodi, primo_ciclo, Nodi_i)
    Nregioni = size(Regioni[:coordinate], 1)
    Nnodi = size(nodi_nodi, 1)
    Nodi_interni_output = zeros(0, 3)
    k = primo_ciclo
    n_nodi_int = size(Nodi_i, 1)

    for m in 1:Nregioni
        if m != k
            contatto = 0
            vertici_contatto = []
            if (Regioni[:cond][k] == Regioni[:cond][m]) && (Regioni[:epsr][k] == Regioni[:epsr][m]) && (Regioni[:mur][k] == Regioni[:mur][m])
                for k1 in 1:8
                    for k2 in 1:8
                        if norm(Regioni[:coordinate][k, (3*k1-2):(k1*3)] - Regioni[:coordinate][m, (3*k2-2):(k2*3)], 2) < 1e-12
                            contatto += 1
                            append!(vertici_contatto, Regioni[:coordinate][k, (3*k1-2):(k1*3)])
                        end
                    end
                end

                if contatto == 4
                    for n in 1:Nnodi
                        if controlla_nodo_su_superfice(vertici_contatto, nodi_nodi[n, :]) == 1
                            coinc = 0
                            if n_nodi_int > 0
                                for k2 in 1:n_nodi_int
                                    # println(size(nodi_nodi[n, :]))
                                    # println(size(Nodi_i))
                                    if norm(nodi_nodi[n, :] - Nodi_i[k2, :], 2) < 1e-12
                                        coinc = 1
                                    end
                                end
                            end
                            if coinc == 0
                                Nodi_interni_output = vcat(Nodi_interni_output, transpose(nodi_nodi[n, :]))
                            end
                        end
                    end
                end
            end
        end
    end
    return Nodi_interni_output
end

function controlla_nodo_su_superfice(vertici_contatto, nodo_i)
    esito = 0
    v1 = vertici_contatto[1:3]
    v2 = vertici_contatto[4:6]
    v3 = vertici_contatto[7:9]
    v4 = vertici_contatto[10:12]

    esito1 = punti_allineati(v1, v2, nodo_i)
    esito2 = punti_allineati(v2, v4, nodo_i)
    esito3 = punti_allineati(v4, v3, nodo_i)
    esito4 = punti_allineati(v3, v1, nodo_i)

    if esito1 == 1 || esito2 == 1 || esito3 == 1 || esito4 == 1
        esito = 0
    else
        a, b, c, d = piano_passante3_punti(v1, v2, v3)
        dist1 = abs(a*nodo_i[1] + b*nodo_i[2] + c*nodo_i[3] + d) / sqrt(a^2 + b^2 + c^2)

        a, b, c, d = piano_passante3_punti(v2, v3, v4)
        dist2 = abs(a*nodo_i[1] + b*nodo_i[2] + c*nodo_i[3] + d) / sqrt(a^2 + b^2 + c^2)

        if dist1 < 1e-10 || dist2 < 1e-10
            esito = 1
        end
    end
    return esito
end

function piano_passante3_punti(v1, v2, v3)
    P12 = v2 - v1
    P13 = v3 - v1

    v = cross(P12, P13)

    a = v[1]
    b = v[2]
    c = v[3]

    d = -(a*v1[1] + b*v1[2] + c*v1[3])

    return a, b, c, d
end

function punti_allineati(v1, v2, v3)
    esito = 0
    P12 = v2 - v1
    P13 = v3 - v1

    v = cross(P12, P13)

    if norm(v) < 1e-10
        esito = 1
    end

    return esito
end
