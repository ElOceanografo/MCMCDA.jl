
println("Testing samplers...")

n_iter = 100

mcmcda!(blips, 1, blips.nscans, 5, params, track_model)

t1 = time()
mcmcda!(blips, 1, blips.nscans, n_iter, params, track_model)
t2 = time()
println("Ran $(n_iter) iterations in $(t2 - t1) seconds ($(n_iter / (t2-t1)) per second)")


t1 = time()
mcmcda!(blips, 1, 5, n_iter, params, track_model)
t2 = time()
println("Ran $(n_iter) iterations in $(t2 - t1) seconds ($(n_iter / (t2-t1)) per second)")