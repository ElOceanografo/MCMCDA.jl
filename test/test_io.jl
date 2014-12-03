
println("Running test_io.jl")

println("Loading data...")
blips = read_targets("data/test_targets.csv")

println("Connecting graph...")
connect_graph!(blips, 25, 2)
println(blips)

@time connect_graph!(blips, 25, 2)
println(blips)
