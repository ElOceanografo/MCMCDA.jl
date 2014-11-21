using MCMCDA
using Base.Test

if ~ isfile("data/test_targets.csv")
	println("Simulating test data...")
	include("simulate_data.jl")
	println("Done.")
end

include("test_io.jl")

println("Passed all tests.")
