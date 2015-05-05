function activate!(e1::Edge)
	for e in e1.source.out_edges
		e.active = false
	end
	for e in e1.target.in_edges
		e.active = false
	end
	e1.active = true
end

function propose_activate!(e::Edge)
	activate!(e)
	e.proposed = true
end

function propose_deactivate!(e1::Edge)
	e1.active = false
	e1.proposed = true
end

function extend!(blip::Blip, gamma=0.1)
	if in_track(blip) && ! ends_track(blip)
		return
	end
	while (length(blip.out_edges) > 0) && (rand() > gamma)
		e = sample(blip.out_edges) #eds[sample(inactive_indices)]
		propose_activate!(e)
		blip = e.target
	end
end

function propose_birth!(sg::ScanGraph, t1::Integer, t2::Integer, gamma=0.1)
	t = sample(t1:t2)
	blip = sg.scans[t][sample(false_target_indices(sg, t))]
	extend!(blip, gamma) # if no edges out, will do nothing
end
propose_birth!(sg::ScanGraph, gamma=0.1) = propose_birth!(sg, 1, sg.nscans, gamma)


function get_random_track_start(sg::ScanGraph, t1::Integer, t2::Integer)
	track_starts = filter(starts_track, iter_blips(sg, t1, t2))
	return sample(collect(track_starts))
end
get_random_track_start(sg::ScanGraph, t1::Integer) = get_random_track_start(sg, t1, t1)
get_random_track_start(sg::ScanGraph) = get_random_track_start(sg, 1, sg.nscans)

function propose_death!(sg::ScanGraph, t1::Integer, t2::Integer, gamma=0.1)
	b1 = get_random_track_start(sg, t1, t2)
	while has_active_edge_out(b1)
		e2, b2 = next_in_track(b1)
		e2.proposed = true
		e2.active = false
		b1 = b2
	end
end
propose_death!(sg::ScanGraph, gamma=0.1) = propose_death!(sg, 1, sg.nscans, gamma)


function propose_split!(sg::ScanGraph, t1::Integer, t2::Integer, gamma=0.1)
	# choose random track
	scan_i, blip_i = track_start_indices(sg, t1, t2)
	i = sample(1:length(scan_i))
	b1 = sg.scans[scan_i[i]][blip_i[i]]
	# make sure it's longer than 4
	n = track_length(b1)
	if n < 4
		return
	end
	# Choose one edge and deactivate it
	break_point = sample(1:n)
	i = 1
	while true
		e, b2 = next_in_track(b1)
		if i >= break_point
			propose_deactivate!(e)
			return 
		else
			b1 = b2
			i += 1
		end
	end
end
propose_split!(sg::ScanGraph) = propose_split!(sg, 1, sg.nscans)


function propose_merge!(sg::ScanGraph, t1::Integer, t2::Integer, gamma=0.1)
	# find edges connecting two tracks (if any)
	start_indices = track_start_indices(sg, t1, t2)
	end_indices = track_end_indices(sg, t1, t2)
	n_start = length(start_indices[1])
	n_end = length(end_indices[1])
	eds = Edge[]
	for i in 1:n_start
		for j in 1:n_end
			b1 = sg.scans[end_indices[1][j]][end_indices[2][j]]
			b2 = sg.scans[start_indices[1][i]][start_indices[2][i]]
			e = connecting_edge(b1, b2, sg)
			if e != nothing && ! e.active
				push!(eds, e)
			end
		end
	end
	# choose one and connect it
	if length(eds) > 0
		e = sample(eds)
		propose_activate!(e)
	end
end
propose_merge!(sg::ScanGraph, gamma=0.1) = propose_merge!(sg, 1, sg.nscans, gamma)


function propose_extend!(sg::ScanGraph, t1::Integer, t2::Integer, gamma=0.1)
	# choose random track
	scan_i, blip_i = track_end_indices(sg, t1, t2)
	i = sample(1:length(scan_i))
	blip = sg.scans[scan_i[i]][blip_i[i]]
	# extend from last vertex
	extend!(blip, gamma)
end

function propose_extend!(sg::ScanGraph, gamma=0.1) 
	return propose_extend!(sg, 1, sg.nscans, gamma)
end


function propose_reduce!(sg::ScanGraph, t1::Integer, t2::Integer, gamma=0.1)
	scan_i, blip_i = track_end_indices(sg, t1, t2)
	i = sample(1:length(scan_i))
	b1 = sg.scans[scan_i[i]][blip_i[i]]
	n = track_length(b1, reverse=true)
	n_reduce = sample(1:n)
	while n_reduce > 0
		e, b2 = prev_in_track(b1)
		propose_deactivate!(e)
		n_reduce -= 1
		b1 = b2
	end
end
propose_reduce!(sg::ScanGraph, gamma=0.1) = propose_reduce!(sg, 1, sg.nscans, gamma)


function propose_update!(sg::ScanGraph, t1::Integer, t2::Integer, gamma=0.1)
	# select track
	scan_i, blip_i = track_start_indices(sg, t1, t2)
	i = sample(1:length(scan_i))
	b1 = sg.scans[scan_i[i]][blip_i[i]]
	# select vertex in track with > 1 out edge
	eds, verts = get_track(b1)
	fork_i = find(b -> length(b.out_edges) > 1, verts[1:end-1])
	if length(fork_i) > 0
		i = sample(fork_i)
		e1 = eds[i]
		e2 = sample(e1.source.out_edges[e1.source.out_edges .!= e1])
		propose_deactivate!(e1)
		propose_activate!(e2)
		extend!(e2.target, gamma)
	end
end
propose_update!(sg::ScanGraph, gamma=0.1) = propose_update!(sg, 1, sg.nscans, gamma)


function attempt_switch!(v1::Blip, v2::Blip, sg::ScanGraph)
	if ends_track(v1) | ends_track(v2)
		return false
	end
	e1, v1_next = next_in_track(v1)
	e2, v2_next = next_in_track(v2)
	e_cross12 = connecting_edge(v1, v2_next, sg)
	e_cross21 = connecting_edge(v2, v1_next, sg)
	if e_cross12 != nothing && e_cross21 != nothing
		e1.active = false
		e2.active = false
		e_cross12.active = true
		e_cross21.active = true
		for e in [e1, e2, e_cross12, e_cross21]
			e.proposed = true
		end
		return true
	end
	return false #fall through condition
end

function propose_switch!(sg::ScanGraph, t1::Integer, t2::Integer, gamma=0.1)
	for t in shuffle([t1:(t2-1);])
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
	this_move!(sg, t1, t2, gamma)
end
propose_move!(sg::ScanGraph, gamma=0.1) = propose_move!(sg, 1, sg.nscans, gamma)


function reject_move!(sg::ScanGraph)
	for e in sg.edges
		if e.proposed
			e.active = ! e.active
			e.proposed = false
		end
		if e.active
			e.n_active += 1
		else
			e.n_inactive += 1
		end
	end
end


function accept_move!(sg::ScanGraph)
	for e in sg.edges
		if e.active
			e.n_active += 1
		else
			e.n_inactive += 1
		end
		e.proposed = false
	end
end
