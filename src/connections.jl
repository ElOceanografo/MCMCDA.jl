
# max_missed = floor(log(1 - p_max_lost) / log(p_detect))
# max_missed = max(max_missed, 1)
# max_missed = min(g.nscans - 1, max_missed)


function connect_graph!(sg::ScanGraph, max_distance, max_missed)
	edge_i = 1
	for i in 1:(sg.nscans - max_missed)
		for j in (i + 1):(i + max_missed)
			for m in 1:length(sg.scans[i])
				for n in 1:length(sg.scans[j])
					v1 = sg.scans[i][m]
					v2 = sg.scans[j][n]
					if ! (v2 in out_neighbors(v1, sg.graph))
						if distance(get_blip(v1), get_blip(v2)) < max_distance
							e = ExEdge(edge_i, v1, v2)
							e.attributes["active"] = false
							add_edge!(sg.graph, e)
							edge_i += 1
						end
					end
				end
			end
		end
	end
end


function n_edges(v::ExVertex, g::AbstractGraph)
	return in_degree(v, g) + out_degree(v, g)
end

function all_edges(v::ExVertex, g::AbstractGraph)
	return [in_edges(v, g), out_edges(v, g)]
end

function in_track(v::ExVertex, sg::ScanGraph)
	return any([e.attributes["active"] for e in all_edges(v, sg.graph)])
end

function has_link_in(v::ExVertex, sg::ScanGraph)
	for e in in_edges(v, sg.graph)
		if e.attributes["active"]
			return true
		end
	end
	return false
end

function has_link_out(v::ExVertex, sg::ScanGraph)
	for e in out_edges(v, sg.graph)
		if e.attributes["active"]
			return true
		end
	end
	return false
end

in_blips(v::ExVertex, sg::ScanGraph) = [source(e) for e in in_edges(v, sg.graph)]
out_blips(v::ExVertex, sg::ScanGraph) = [target(e) for e in out_edges(v, sg.graph)]

function next_in_track(v::ExVertex, sg::ScanGraph)
	for e in out_edges(v, sg.graph)
		if e.attributes["active"]
			return target(e)
		end
	end
end

connected(v1::ExVertex, v2::ExVertex, sg::ScanGraph) = v2 in out_blips(v1, sg)


function starts_track(v::ExVertex, sg::ScanGraph)
	return (! has_link_in(v, sg)) && has_link_out(v, sg)
end

function ends_track(v::ExVertex, sg::ScanGraph)
	return has_link_in(v, sg) && (! has_link_out(v, sg))
end

function n_targets(sg::ScanGraph, t::Integer)
	n = 0
	for i in 1:length(sg.scans[t])
		if in_track(sg.scans[t][i], sg)
			n += 1
		end
	end
	return n
end

function n_targets(sg::ScanGraph)
	n = 0
	for i in 1:length(sg.scans)
		n += n_targets(sg, i)
	end
	return n
end

function n_false_targets(sg::ScanGraph, t::Integer)
	n = 0
	for i in 1:length(sg.scans[t])
		if ! in_track(sg.scans[t][i], sg)
			n += 1
		end
	end
	return n
end

function n_false_targets(sg::ScanGraph)
	n = 0
	for i in 1:length(sg.scans)
		n += n_false_targets(sg, i)
	end
	return n
end

start_time(e::ExEdge) = get_blip(source(e)).t
end_time(e::ExEdge) = get_blip(target(e)).t

function n_tracks(sg::ScanGraph, t::Integer)
	n = 0
	for e in edges(sg.graph)
		if e.attributes["active"] && start_time(e) < t && end_time(e) > t
			n += 1
		end
	end
	return n + n_targets(sg, t)
end
