function extend!(v::ExVertex, sg::ScanGraph, gamma=0.1)
	if in_track(v, sg) && ! ends_track(v, sg)
		return
	end
	eds = out_edges(v, sg.graph)
	while (length(eds) > 0) && (rand() > gamma)
		inactive_indices = find(Bool[! e.attributes["active"] for e in eds])
		if length(inactive_indices) == 0
			break
		end
		e = eds[sample(inactive_indices)]
		e.attributes["active"] = true
		e.attributes["proposed"] = true
		v = target(e, sg.graph)
		eds = out_edges(v, sg.graph)
	end
end

function propose_birth!(sg::ScanGraph, t1::Integer, t2::Integer, gamma=0.1)
	t = sample(t1:t2)
	v = sg.scans[t][sample(false_target_indices(sg, t))]
	extend!(v, sg, gamma) # if no edges out, will do nothing
end
propose_birth!(sg::ScanGraph, gamma=0.1) = propose_birth!(sg, 1, sg.nscans, gamma)

function propose_death!(sg::ScanGraph, t1::Integer, t2::Integer, gamma=0.1)
	i = sample(track_start_indices(sg, t1, t2))
	v1 = vertices(sg.graph)[i]
	while has_link_out(v1, sg)
		e2, v2 = next_in_track(v1, sg)
		e2.attributes["proposed"] = true
		e2.attributes["active"] = false
		v1 = v2
	end
end
propose_death!(sg::ScanGraph, gamma=0.1) = propose_death!(sg, 1, sg.nscans, gamma)


function propose_split!(sg::ScanGraph, t1::Integer, t2::Integer, gamma=0.1)
	# choose random track longer than 4
	track_i = track_start_indices(sg, t1, t2)
	verts = vertices(sg.graph)[track_i]
	long_track_i = find([track_length(v, sg) > 4 for v in verts])
	if long_track_i == []
		return # no long tracks, give up
	end
	v1 = verts[sample(long_track_i)]
	n = track_length(v1, sg)
	nmax = sample(1:n)
	j = 1
	while true
		e, v2 = next_in_track(v1, sg)
		if j >= nmax
			e.attributes["proposed"] = true
			e.attributes["active"] = false
			return 
		else
			v1 = v2
			j += 1
		end
	end
end
propose_split!(sg::ScanGraph, gamma=0.1) = propose_split!(sg, 1, sg.nscans, gamma)


function propose_merge!(sg::ScanGraph, t1::Integer, t2::Integer, gamma=0.1)
	# find edges connecting two tracks (if any)
	start_i = track_start_indices(sg, t1, t2)
	end_i = track_end_indices(sg, t1, t2)
	eds = ExEdge[]
	for i in start_i, j in end_i
		v1 = vertices(sg.graph)[i]
		v2 = vertices(sg.graph)[j]
		e = connecting_edge(v1, v2, sg)
		if e != nothing && ! e.attributes["active"]
			push!(eds, e)
		end
	end
	# choose one and connect it
	if length(eds) > 0
		e = sample(eds)
		e.attributes["active"] = true
		e.attributes["proposed"] = true
	end
end
propose_merge!(sg::ScanGraph, gamma=0.1) = propose_merge!(sg, 1, sg.nscans, gamma)


function propose_extend!(sg::ScanGraph, t1::Integer, t2::Integer, gamma=0.1)
	# choose random track
	end_i = track_end_indices(sg, t1, t2)
	verts = filter(v -> out_degree(v, sg.graph) > 0, vertices(sg.graph)[end_i])
	v = sample(verts)
	# extend from last vertex
	extend!(v, sg, gamma)
end
propose_extend!(sg::ScanGraph, gamma=0.1) = propose_extend!(sg, 1, sg.nscans, gamma)


function propose_reduce!(sg::ScanGraph, t1::Integer, t2::Integer, gamma=0.1)
	end_i = track_end_indices(sg, t1, t2)
	i = sample(end_i)
	v1 = vertices(sg.graph)[i]
	n = track_length(v1, sg, false)
	n_reduce = sample(1:n)
	while n_reduce > 0
		e, v2 = prev_in_track(v1, sg)
		e.attributes["active"] = false
		e.attributes["proposed"] = true
		n_reduce -= 1
		v1 = v2
	end
end
propose_reduce!(sg::ScanGraph, gamma=0.1) = propose_reduce!(sg, 1, sg.nscans, gamma)


function propose_update!(sg::ScanGraph, t1::Integer, t2::Integer, gamma=0.1)
	# select track
	i = sample(track_start_indices(sg, t1, t2))
	v1 = vertices(sg.graph)[i]
	# select vertex in track with > 1 out edge
	eds, verts = get_track(v1, sg)
	fork_i = find(v -> out_degree(v, sg.graph) > 1, verts[1:end-1])
	if length(fork_i) > 0
		i = sample(fork_i)
		e = eds[i]
		e.attributes["active"] = false
		e.attributes["proposed"] = true
		extend!(verts[i], sg, gamma)
	end
end
propose_update!(sg::ScanGraph, gamma=0.1) = propose_update!(sg, 1, sg.nscans, gamma)


function attempt_switch!(v1::ExVertex, v2::ExVertex, sg::ScanGraph)
	if ends_track(v1, sg) | ends_track(v2, sg)
		return false
	end
	e1, v1_next = next_in_track(v1, sg)
	e2, v2_next = next_in_track(v2, sg)
	e_cross12 = connecting_edge(v1, v2_next, sg)
	e_cross21 = connecting_edge(v2, v1_next, sg)
	if e_cross12 != nothing && e_cross21 != nothing
		e1.attributes["active"] = false
		e2.attributes["active"] = false
		e_cross12.attributes["active"] = true
		e_cross21.attributes["active"] = true
		for e in [e1, e2, e_cross12, e_cross21]
			e.attributes["proposed"] = true
		end
		return true
	end
	return false #fall through condition
end

function propose_switch!(sg::ScanGraph, t1::Integer, t2::Integer, gamma=0.1)
	for t in shuffle([t1:(t2-1)])
		ii = in_track_indices(sg, t)
		if length(ii) > 1
			i1, i2 = sample(ii, 2)
			v1, v2 = sg.scans[t][[i1, i2]]
			success = attempt_switch!(v1, v2, sg)
			if success
				return
			end
		end
	end
end
propose_switch!(sg::ScanGraph, gamma=0.1) = propose_switch!(sg, 1, sg.nscans, gamma)


function propose_move!(sg::ScanGraph, t1::Integer, t2::Integer, gamma=0.1)
	ntracks = min(n_tracks(sg, t1, t2),
				  n_tracks_started(sg, t1, t2),
				  n_tracks_ended(sg, t1, t2))
	moves = [propose_birth!, propose_death!, propose_split!, propose_merge!, 
		propose_extend!, propose_reduce!, propose_update!, propose_switch!]
	if ntracks > 1
		this_move! = sample(moves)
	elseif ntracks == 1
		this_move! = moves[sample(1:7)]
	else # no tracks
		this_move! = moves[1]
	end
	this_move!(sg, t1, t2)
end
propose_move!(sg::ScanGraph, gamma=0.1) = propose_move!(sg, 1, sg.nscans, gamma)


function reject_move!(sg::ScanGraph)
	for e in edges(sg.graph)
		if e.attributes["proposed"]
			e.attributes["active"] = ! e.attributes["active"]
			e.attributes["proposed"] = false
		end
		if e.attributes["active"]
			e.attributes["freq_active"] += 1
		else
			e.attributes["freq_inactive"] += 1
		end
	end
end


function accept_move!(sg::ScanGraph)
	for e in edges(sg.graph)
		if e.attributes["active"]
			e.attributes["freq_active"] += 1
		else
			e.attributes["freq_inactive"] += 1
		end
		e.attributes["proposed"] = false
	end
end
