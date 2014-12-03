using MCMCDA, StateSpace, Graphs
using Base.Test

if ~ isfile("data/test_targets.csv")
	println("Simulating test data...")
	include("simulate_data.jl")
	println("Done.")
end

include("test_io.jl")
include("test_connections.jl")
include("test_probabilities.jl")

println("Passed all tests.")
