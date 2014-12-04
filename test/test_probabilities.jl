
# same constants as used to generate the test data

nsim = 64
ntargets = 5
max_distance = 1e3 # 1 km square
lambda_f = 1.0 / 100^2 # one false alarm per 10,000 square m per timestep
vol = max_distance^2
lambda_b = ntargets / (nsim * vol)
p_missing = 0.05
p_detect = 1 - p_missing
p_disappear = 1e-4


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


println("Calculating cofiguration prior...")
params = [p_disappear, p_detect, lambda_b, lambda_f]
LP = config_logprior(blips, params, vol, 1, nsim)
@time LP = config_logprior(blips, params, vol, 1, nsim)
println(LP)


println("Calculating likelihood...")
LL = loglikelihood(blips, lambda_f * vol, track_model)
@time LL = loglikelihood(blips, lambda_f * vol, track_model)
println(LL)
