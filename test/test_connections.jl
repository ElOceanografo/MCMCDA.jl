println("Testing connections...")

# for va in blips.scans[2]
# 	for vb in blips.scans[3]
# 		if connected(va, vb, blips)
# 			println(va, "==>", vb)
# 		end
# 	end
# end

# track with beginning, middle, and end
v1 = vertices(blips.graph)[107]
e1 = out_edges(v1, blips.graph)[1]
v2 = target(e1)
e2 = out_edges(v2, blips.graph)[1]
v3 = target(e2)

# track with just two detections
v4 = vertices(blips.graph)[530]
e4 = out_edges(v4, blips.graph)[1]
v5 = target(e4)

# track that skips a scan
v6 = vertices(blips.graph)[1594] # time 16
e6 = out_edges(v6, blips.graph)[1]
v7 = target(e6) # time 18

for e in [e1, e2, e4, e6]
	e.attributes["active"] = true
end

@assert starts_track(v1, blips)
@assert has_link_out(v1, blips)
@assert in_track(v1, blips)
@assert n_tracks_started(blips, 1) == 1

@assert has_link_in(v2, blips)
@assert in_track(v2, blips)
@assert has_link_out(v2, blips)
@assert connected(v1, v2, blips)
@assert n_tracks_started(blips, 2) == n_tracks_ended(blips, 2) == 0

@assert has_link_in(v3, blips)
@assert in_track(v3, blips)
@assert ends_track(v3, blips)
@assert n_tracks_ended(blips, 3) == 1

@assert starts_track(v4, blips)
@assert has_link_out(v4, blips)
@assert in_track(v4, blips)

@assert ends_track(v5, blips)
@assert has_link_in(v5, blips)
@assert in_track(v5, blips)

@assert n_targets(blips, 1) == 1
@assert n_false_targets(blips, 1) == 108
@assert n_targets(blips, 5) == 0
@assert n_targets(blips, 6) == 1
@assert n_false_targets(blips, 5) == 94
@assert n_targets(blips) == 7

@assert n_tracks(blips, 2) == 1
@assert n_tracks(blips, 2) == n_targets(blips, 2)
@assert n_tracks(blips, 17) == 1
@assert n_tracks(blips, 17) > n_targets(blips, 17)

