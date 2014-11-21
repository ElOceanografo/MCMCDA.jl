using MCMCDA
using Base.Test

if ~ isfile("data/test_targets.csv")
	println("Simulating test data...")
	include("simulate_data.jl")
	println("Done.")
end

println("Passed all tests.")
