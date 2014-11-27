
println("Running test_io.jl")

println("Loading data...")
blips = read_targets("data/test_targets.csv")

println("Linking graph...")
link!(blips, 25, 2)
println(blips)

@time link!(blips, 25, 2)
println(blips)