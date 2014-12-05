
println("Testing proposal moves...")
srand(1)
# for i in 1:100
# 	v = vertices(blips.graph)[i]
# 	if ! in_track(v, blips) && out_degree(v, blips.graph) > 0
# 		println(i)
# 		break
# 	end
# end

va = vertices(blips.graph)[10]
e = out_edges(va, blips.graph)[1]
n1 = n_tracks_started(blips)

extend!(va, blips, 0)
@assert n_tracks_started(blips) == n1 + 1

@assert e.attributes["active"]
@assert e.attributes["proposed"]
@assert n_proposed(blips) > 0

reject_move!(blips)
@assert ! e.attributes["active"]
@assert n_proposed(blips) == 0
@assert e.attributes["freq_inactive"] == 1

extend!(va, blips, 0)
@assert e.attributes["active"]
@assert e.attributes["proposed"]

accept_move!(blips)
@assert n_proposed(blips) == 0
@assert e.attributes["active"]
@assert e.attributes["freq_active"] == 1

propose_birth!(blips, 0) # first is a misfire with this random seed
propose_birth!(blips, 0)
accept_move!(blips)

n1 = n_tracks_started(blips)
propose_death!(blips)
@assert n_tracks_started(blips) == n1 - 1

accept_move!(blips)

# make sure there's at least one long track to split
for v in blips.scans[1]
	if ! in_track(v, blips)
		extend!(v, blips)
	end
end

n1 = n_tracks_started(blips)
propose_split!(blips)
@assert n_tracks_started(blips) == n1 + 1
accept_move!(blips)

n1 = n_targets(blips)
propose_extend!(blips)
@assert n_targets(blips) > n1
accept_move!(blips)

n1 = n_targets(blips)
propose_reduce!(blips)
@assert n_targets(blips) < n1
accept_move!(blips)

ea, va = next_in_track(v3, blips)
ea.attributes["active"] = false
n1 = sum([e.attributes["active"] for e in edges(blips.graph)])
n2 = n_targets(blips)
propose_merge!(blips, 1, 6)
@assert sum([e.attributes["active"] for e in edges(blips.graph)]) == n1 + 1
@assert n_targets(blips) == n2
accept_move!(blips)

for i in 1:20
	propose_update!(blips)
	accept_move!(blips)
end

# propose_move!(blips, 1, blips.nscans)
