using Distributions, DataFrames
using StateSpace

srand(1)
nsim = 64

ntargets = 5
max_distance = 1e3 # 1 km radius
start_x = rand(Normal(0, 100), ntargets)
start_y = rand(Normal(0, 100), ntargets)
start_speed = rand(Normal(10, 1), ntargets)
start_direction = rand(Uniform(0, 2pi), ntargets)
start_u = start_speed .* cos(start_direction)
start_v = start_speed .* sin(start_direction)

# Movement model: random walk in velcoity
F = [1.0 0.0 1.0 0.0;
	 0.0 1.0 0.0 1.0;
	 0.0 0.0 1.0 0.0;
	 0.0 0.0 0.0 1.0]
V = diagm([0.1, 0.1, 1.0, 1.0])
# Observation: actual position plus small error
G = [diagm(ones(2)) zeros(2, 2)]
W = diagm(2 * ones(2))
movement_model = LinearGaussianSSM(F, V, G, W)

# False detection model: uniform Poisson process
lambda = 1.0 / 100^2 # one false alarm per 10,000 square m
false_detections = Poisson(lambda * max_distance^2)
false_detection_coord = Uniform(-max_distance, max_distance)

# Missing data model: Bernoulli trial
p_missing = 0.05
data_missing = Bernoulli(p_missing)

# Generate tracks
start_state = [start_x start_y start_u start_v]'
start_cov = diagm(1e-6 * ones(4))
start_dists = [MvNormal(vec(start_state[:, i]), start_cov) for i in 1:ntargets]
tracks = [simulate(movement_model, nsim, start_dists[i]) for i in 1:ntargets]

# Generate false detections
blips = [rand(false_detection_coord, (2, rand(false_detections))) for i in 1:nsim]

# Add real tracks to false detections
for i in 1:nsim
	for j in 1:ntargets
		track = copy(tracks[j][2])
		# delete some measurements at random before appending
		n = size(track, 2)
		drop = Bool[bool(rand(data_missing)) for i in 1:n]
		track = track[:, ~drop]
		# append
		blips[i] = [blips[i] tracks[j][2][:, i]]
	end
end

# Plot to make sure it worked
# using PyPlot
# for i in 1:16
# 	subplot(4, 4, i)
# 	scatter(blips[4i][1, :]', blips[4i][2, :]', 5, "k")
# 	for j in 1:ntargets
# 		plot(tracks[j][1][1, 1:4i]', tracks[j][1][2, 1:4i]')
# 	end
# end

# Put everything in a DataFrame and save
dfs = [DataFrame(x = vec(blips[i][1, :]), y = vec(blips[i][2, :]), t=i) 
		for i in 1:nsim]
dfs = vcat(dfs)
writetable("data/test_targets.csv", dfs)