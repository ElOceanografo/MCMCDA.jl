println("Testing connections...")

# for v in vertices(blips.graph)
# 	n = out_degree(v, blips.graph)
# 	t = v.attributes["blip"].t
# 	if (n > 0) & (t < 10)
# 		println(t, " ", v, " ", n)
# 	end
# end


v1 = vertices(blips.graph)[12]
e1 = out_edges(v1, blips.graph)[1]
v2 = target(e1)
e2 = out_edges(v2, blips.graph)[1]
v3 = target(e2)

v4 = vertices(blips.graph)[527]
e4 = out_edges(v4, blips.graph)[1]
v5 = target(e4)

for e in [e1, e2, e4]
	e.attributes["active"] = true
end

@assert starts_track(v1, blips)
@assert has_link_out(v1, blips)
@assert in_track(v1, blips)

@assert has_link_in(v2, blips)
@assert in_track(v2, blips)
@assert has_link_out(v2, blips)

@assert has_link_in(v3, blips)
@assert in_track(v3, blips)
@assert ends_track(v3, blips)

@assert starts_track(v4, blips)
@assert has_link_out(v4, blips)
@assert in_track(v4, blips)

@assert ends_track(v5, blips)
@assert has_link_in(v5, blips)
@assert in_track(v5, blips)

