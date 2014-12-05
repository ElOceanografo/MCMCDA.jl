
println("Testing proposal moves...")

# for i in 1:100
# 	v = vertices(blips.graph)[i]
# 	if ! in_track(v, blips) && out_degree(v, blips.graph) > 0
# 		println(i)
# 		break
# 	end
# end

va = vertices(blips.graph)[10]
n1 = n_tracks_started(blips)

extend!(va, blips)
@assert n_tracks_started(blips) == n1 + 1

e, vb = next_in_track(va, blips)
@assert e.attributes["active"]
@assert e.attributes["proposed"]
@assert n_proposed(blips) > 0

reject_move!(blips)
@assert ! e.attributes["active"]
@assert n_proposed(blips) == 0
@assert e.attributes["freq_inactive"] == 1

extend!(va, blips)
e, vb = next_in_track(va, blips)
accept_move!(blips)

@assert n_proposed(blips) == 0
@assert e.attributes["active"]
@assert e.attributes["freq_active"] == 1

# propose_move!(blips, 1, blips.nscans)
