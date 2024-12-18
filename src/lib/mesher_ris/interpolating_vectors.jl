function interpolating_vectors(ri)
    # Calculate interpolation vectors
    rmi = 0.125 * sum(ri, dims=2)
    rai = 0.125 * (-ri[:, 1] + ri[:, 2] + ri[:, 4] - ri[:,3] - ri[:,5] + ri[:,6] + ri[:,8] - ri[:,7])
    rbi = 0.125 * (-ri[:, 1] - ri[:, 2] + ri[:, 4] + ri[:,3] - ri[:,5] - ri[:,6] + ri[:,8] + ri[:,7])
    rci = 0.125 * (-ri[:, 1] - ri[:, 2] - ri[:, 4] - ri[:,3] + ri[:,5] + ri[:,6] + ri[:,8] + ri[:,7])
    rabi = 0.125 * (ri[:, 1] - ri[:, 2] + ri[:, 4] - ri[:,3] + ri[:,5] - ri[:,6] + ri[:,8] - ri[:,7])
    rbci = 0.125 * (ri[:, 1] + ri[:, 2] - ri[:, 4] - ri[:,3] - ri[:,5] - ri[:,6] + ri[:,8] + ri[:,7])
    raci = 0.125 * (ri[:, 1] - ri[:, 2] - ri[:, 4] + ri[:,3] - ri[:,5] + ri[:,6] + ri[:,8] - ri[:,7])
    rabci = 0.125 * (-ri[:, 1] + ri[:, 2] - ri[:, 4] + ri[:,3] + ri[:,5] - ri[:,6] + ri[:,8] - ri[:,7])
    # Return results as a tuple
    return rmi, rai, rbi, rci, rabi, rbci, raci, rabci
end
