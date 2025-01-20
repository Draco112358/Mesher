function matrici_selettrici_rev(induttanze::Dict)

    # Initialize Nc (number of elements with epsr == 1)
    induttanze[:Nc] = 0

    # Count Nc by checking epsr values
    for k in 1:size(induttanze[:estremi_celle], 1)
        if induttanze[:epsr][k] == 1
            induttanze[:Nc] += 1
        end
    end

    induttanze[:Nd] = size(induttanze[:estremi_celle], 1) - induttanze[:Nc]

    # Initialize Sc and Sd
    induttanze[:Sc] = zeros(Float64, induttanze[:Nc])
    induttanze[:Sd] = zeros(Float64, induttanze[:Nd])
    induttanze[:Sc][1:induttanze[:Nc]].=1;
    newInduttanzeSd = zeros(size(induttanze[:estremi_celle],1))
    newInduttanzeSd[1:size(induttanze[:Sd],1)] .= induttanze[:Sd]
    newInduttanzeSd[induttanze[:Nc]+1:size(induttanze[:estremi_celle],1)] .= 1
    induttanze[:Sd]=newInduttanzeSd
    induttanze[:Nb]=induttanze[:Nc]+induttanze[:Nd]; #numero di lati

    return induttanze
end
