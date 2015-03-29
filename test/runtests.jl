using MCMCDA, StateSpace#, Graphs
using Base.Test

if ~ isfile("data/test_targets.csv")
	println("Simulating test data...")
	include("simulate_data.jl")
	println("Done.")
end

include("test_io.jl")
include("test_connections.jl")
include("test_probabilities.jl")
# include("test_proposal_moves.jl")
# include("test_samplers.jl")

println("Passed all tests.\n")
