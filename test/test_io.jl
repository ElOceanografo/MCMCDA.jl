
println("Running test_io.jl")

println("Loading data...")
sg = read_targets("data/test_targets.csv")

println("Connecting graph...")
connect_graph!(sg, 25, 2)
println(sg)

@time connect_graph!(sg, 25, 2)
println(sg)
