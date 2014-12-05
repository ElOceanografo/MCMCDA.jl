function extend!(v::ExVertex, sg::ScanGraph, gamma=0.1)
	@assert ! in_track(v, sg)
	eds = out_edges(v, sg.graph)
	while (length(eds) > 0) && (rand() > gamma)
		inactive_indices = find(Bool[! e.attributes["active"] for e in eds])
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

function propose_death!(sg::ScanGraph, t1::Integer, t2::Integer)
	i = sample(track_start_indices(sg, t1, t2))
	v1 = vertices(sg.graph)[i]
	while has_link_out(v1, sg)
		e2, v2 = next_in_track(v1, sg)
		e2.attributes["proposed"] = true
		e2.attributes["active"] = false
		v1 = v2
	end
end
propose_death!(sg::ScanGraph) = propose_death!(sg, 1, sg.nscans)


function propose_split!(sg::ScanGraph, t1::Integer, t2::Integer)
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
propose_split!(sg::ScanGraph) = propose_split!(sg, 1, sg.nscans)

function propose_merge!(sg::ScanGraph, t1::Integer, t2::Integer)
	# find edges connecting two tracks (if any)
	# choose one and connect it
end

function propose_extend!(sg::ScanGraph, t1::Integer, t2::Integer)
	# choose random track
	# extend from last vertex
end

function propose_reduce!(sg::ScanGraph, t1::Integer, t2::Integer)
	#function body
end

function propose_update!(sg::ScanGraph, t1::Integer, t2::Integer)
	#function body
end

function propose_switch!(sg::ScanGraph, t1::Integer, t2::Integer)
	#function body
end

function propose_move!(sg::ScanGraph, t1::Integer, t2::Integer)
	ntracks = n_tracks(sg)
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

propose_move!(sg::ScanGraph) = propose_move!(sg, 1, sg.nscans)

function reject_move!(sg::ScanGraph, t1::Integer, t2::Integer)
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

reject_move!(sg::ScanGraph) = reject_move!(sg, 1, sg.nscans)

function accept_move!(sg::ScanGraph, t1::Integer, t2::Integer)
	for e in edges(sg.graph)
		if e.attributes["active"]
			e.attributes["freq_active"] += 1
		else
			e.attributes["freq_inactive"] += 1
		end
		e.attributes["proposed"] = false
	end
end

accept_move!(sg::ScanGraph) = accept_move!(sg, 1, sg.nscans)
