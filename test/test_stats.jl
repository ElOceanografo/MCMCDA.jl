
# define model for movement of targets: for testing purposes, use the true
# dynamic model that was used to generate the data
F = [1.0 0.0 1.0 0.0;
	 0.0 1.0 0.0 1.0;
	 0.0 0.0 1.0 0.0;
	 0.0 0.0 0.0 1.0]
V = diagm([0.1, 0.1, 1.0, 1.0])
# Observation: actual position plus small error
G = [diagm(ones(2)) zeros(2, 2)]
W = diagm(2 * ones(2))
track_model = LinearGaussianSSM(F, V, G, W)

lambda = 6000.0

println("Calculating likelihood...")
LL = loglikelihood(blips, lambda, track_model)
@time LL = loglikelihood(blips, lambda, track_model)
println(LL)