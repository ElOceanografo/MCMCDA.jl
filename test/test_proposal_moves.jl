
println("Testing proposal moves...")
srand(1)
# for i in 1:100
# 	v = vertices(sg.graph)[i]
# 	if ! in_track(v, sg) && out_degree(v, sg.graph) > 0
# 		println(i)
# 		break
# 	end
# end

ba = sg.blips[10]
e = ba.out_edges[1]
n1 = n_tracks_started(sg)

extend!(ba, 0)
@assert n_tracks_started(sg) == n1 + 1

@assert e.active
@assert e.proposed
@assert n_proposed(sg) > 0

reject_move!(sg)
@assert ! e.active
@assert n_proposed(sg) == 0
@assert e.n_inactive == 1

extend!(ba, 0)
@assert e.active
@assert e.proposed

accept_move!(sg)
@assert n_proposed(sg) == 0
@assert e.active
@assert e.n_active == 1

propose_birth!(sg, 0) # first is a misfire with this random seed
propose_birth!(sg, 0)
accept_move!(sg)

n1 = n_tracks_started(sg)
propose_death!(sg)
@assert n_tracks_started(sg) == n1 - 1

accept_move!(sg)

# make sure there's at least one long track to split
for v in sg.scans[1]
	if ! in_track(v)
		extend!(v)
	end
end

n1 = n_tracks_started(sg)
propose_split!(sg)
@assert n_tracks_started(sg) == n1 + 1
accept_move!(sg)

n1 = n_targets(sg)
propose_extend!(sg)
@assert n_targets(sg) > n1
accept_move!(sg)

n1 = n_targets(sg)
propose_reduce!(sg)
@assert n_targets(sg) < n1
accept_move!(sg)


ea, ba = next_in_track(sg.scans[1][106]) # track with 13 blips
ea, ba = next_in_track(ba)
ea, ba = next_in_track(ba)
ea.active = false
n1 = sum([e.active for e in sg.edges])
n2 = n_targets(sg)
propose_merge!(sg, 1, 6)
@assert sum([e.active for e in sg.edges]) == n1 + 1
@assert n_targets(sg) == n2
accept_move!(sg)

propose_switch!(sg)


for i in 1:20
	propose_update!(sg)
	accept_move!(sg)
	println(i)
end

t1 = time()
for i in 1:100
	propose_move!(sg, 1, sg.nscans)
	println(i)
end
t2 = time()
println(t2 - t1, " seconds")
println(100. / (t2 - t1), " moves per second")