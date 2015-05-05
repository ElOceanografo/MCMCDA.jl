
println("Running test_io.jl")

println("Loading data...")
sg = read_targets("data/test_targets.csv"; skipstart=1)

println(sg)