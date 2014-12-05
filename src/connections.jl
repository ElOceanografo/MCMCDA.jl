
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
							e.attributes["proposed"] = false
							e.attributes["freq_active"] = 0
							e.attributes["freq_inactive"] = 0
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
			return (e, target(e))
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

## Number of detected targets (i.e., blips assigned to a track)
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

## Number of false targets (i.e., blips not assigned to a track; clutter)
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

## Number of targets (detected and undetected) present
function n_tracks(sg::ScanGraph, t::Integer)
	n = 0
	for e in edges(sg.graph)
		if e.attributes["active"] && start_time(e) < t && end_time(e) > t
			n += 1
		end
	end
	return n + n_targets(sg, t)
end

## Number of tracks starting in this timestep
function n_tracks_started(sg::ScanGraph, t::Integer)
	n = 0
	for v in sg.scans[t]
		if starts_track(v, sg)
			n += 1
		end
	end
	return n
end

## Number of tracks in entire graph
function n_tracks_started(sg::ScanGraph)
	n = 0
	for v in vertices(sg.graph)
		if starts_track(v, sg)
			n += 1
		end
	end
	return n
end

n_tracks(sg::ScanGraph) = n_tracks_started(sg)

## Number of tracks ending in this timestep
function n_tracks_ended(sg::ScanGraph, t::Integer)
	n = 0
	for v in sg.scans[t]
		if ends_track(v, sg)
			n += 1
		end
	end
	return n
end


function n_proposed(sg::ScanGraph, t1::Integer, t2::Integer)
	return return sum(Bool[e.attributes["proposed"] for e in edges(sg.graph)])
end

n_proposed(sg::ScanGraph) = n_proposed(sg, 1, sg.nscans)


function track_start_indices(sg::ScanGraph)
	return find(Bool[starts_track(v, sg) for v in vertices(sg.graph)])
end

function track_start_indices(sg::ScanGraph, t::Integer)
	return find(Bool[starts_track(v, sg) for v in sg.scans[t]])
end

function track_start_indices(sg::ScanGraph, t1::Integer, t2::Integer)
	# Special case: all scans specified.  Calling the other method will
	# be a bit faster, because the array doesn't have to be bult up.
	if t1 == 1 && t2 == sg.nscans
		return track_start_indices(sg)
	end
	indices = Int64[]
	for i in t1:t2
		for v in sg.scans[i]
			if starts_track(v, sg)
				push!(indices, v.index)
			end
		end
	end
	return indices
end

function false_target_indices(sg::ScanGraph)
	return find(Bool[! in_track(v, sg) for v in vertices(sg.graph)])
end

function false_target_indices(sg::ScanGraph, t::Integer)
	return find(Bool[! in_track(v, sg) for v in sg.scans[t]])
end

function in_track_indices(sg::ScanGraph)
	return find(Bool[in_track(v, sg) for v in vertices(sg.graph)])
end

function in_track_indices(sg::ScanGraph, t::Integer)
	return find(Bool[in_track(v, sg) for v in sg.scans[t]])
end
