println("Testing connections...")

# for t1 in 16:18
# 	t2 = t1 + 2
# 	for i in 1:length(sg.scans[t1])
# 		for j in 1:length(sg.scans[t2])
# 			if connected(sg.scans[t1][i], sg.scans[t2][j])
# 				println(t1, ", ", i, " ==> ", t2, ", ", j)
# 			end
# 		end
# 	end
# end

# track with beginning, middle, and end
b1 = sg.scans[1][109]
e1 = b1.out_edges[1]
b2 = e1.target
e2 = b2.out_edges[1]
b3 = e2.target

# track with just two detections
b4 = sg.scans[1][16]
e4 = b4.out_edges[1]
b5 = e4.target

# # track that skips a scan
b6 = sg.scans[16][19]
e6 = b6.out_edges[1]
b7 = e6.target # time 18

for e in [e1, e2, e4, e6]
	e.active = true
end

@assert starts_track(b1)
@assert has_active_edge_out(b1)
@assert in_track(b1)
@assert n_tracks_started(sg, 1) == 2
@assert track_length(b1) == 2

@assert has_active_edge_in(b2)
@assert in_track(b2)
@assert has_active_edge_out(b2)
@assert connected(b1, b2)
@assert n_tracks_started(sg, 2) == 0
@assert n_tracks_ended(sg, 2) == 1

@assert has_active_edge_in(b3)
@assert in_track(b3)
@assert ends_track(b3)
@assert n_tracks_ended(sg, 3) == 1

for b in iter_track(b1)
	println(b)
end

@assert starts_track(b4)
@assert has_active_edge_out(b4)
@assert in_track(b4)

@assert ends_track(b5)
@assert has_active_edge_in(b5)
@assert in_track(b5)

# @assert n_targets(sg, 1) == 1
# @assert n_false_targets(sg, 1) == 108
# @assert n_targets(sg, 5) == 0
# @assert n_targets(sg, 6) == 1
# @assert n_false_targets(sg, 5) == 94
# @assert n_targets(sg) == 7

# @assert n_tracks(sg, 2) == 1
# @assert n_tracks(sg, 2) == n_targets(sg, 2)
# @assert n_tracks(sg, 17) == 1
# @assert n_tracks(sg, 17) > n_targets(sg, 17)

# @assert n_tracks(sg) == 3
# @assert n_tracks_started(sg) == 3

# @assert track_start_indices(sg) == [107, 530, 1594]
# @assert track_start_indices(sg, 1) == [107]
# @assert track_end_indices(sg) == [334, 641, 1836]
# @assert track_end_indices(sg, 3) == [105]


# @assert intersect(false_target_indices(sg), in_track_indices(sg)) == []
# @assert intersect(false_target_indices(sg, 1), in_track_indices(sg, 1)) == []
