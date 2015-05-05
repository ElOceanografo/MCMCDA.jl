
function add_edge!(b1::Blip, b2::Blip, sg::ScanGraph)
	if ! (b2 in out_neighbors(b1))
		e = Edge(b1, b2, false, false, 0, 0)
		push!(b1.out_edges, e)
		push!(b2.in_edges, e)
		push!(sg.edges, e)
	end
end

function connect_graph!(sg::ScanGraph, max_distance, max_missed)
	for i in 1:(sg.nscans - max_missed)
		for j in (i + 1):(i + max_missed)
			for m in 1:length(sg.scans[i])
				for n in 1:length(sg.scans[j])
					b1 = sg.scans[i][m]
					b2 = sg.scans[j][n]
					if distance(b1, b2) < max_distance
						add_edge!(b1, b2, sg)
					end
				end
			end
		end
	end
end

function has_active_edge_in(b::Blip)
	for e in b.in_edges
		if e.active
			return true
		end
	end
	return false
end

function has_active_edge_out(b::Blip)
	for e in b.out_edges
		if e.active
			return true
		end
	end
	return false
end

in_track(b::Blip) = has_active_edge_in(b) | has_active_edge_out(b)
starts_track(b::Blip) = ! has_active_edge_in(b) & has_active_edge_out(b)
ends_track(b::Blip) = has_active_edge_in(b) & ! has_active_edge_out(b)

function next_in_track(b::Blip)
	if has_active_edge_out(b)
		for e in b.out_edges
			if e.active
				return e, e.target
			end
		end
	else
		error("No more blips in track")
	end
end

function prev_in_track(b::Blip)
	if has_active_edge_in(b)
		for e in b.in_edges
			if e.active
				return e, e.source
			end
		end
	else
		error("No more blips in track")
	end
end


function next_blip_in_track(b::Blip)
	if length(b.out_edges) == 0
		return b
	end
	for e in b.out_edges
		if e.active
			return e.target
		end
	end
	return b # no active edges
end

function prev_blip_in_track(b::Blip)
	if length(b.in_edges) == 0
		return b
	end
	for e in b.in_edges
		if e.active
			return e.source
		end
	end
	return b # no active edges
end

function iter_track(b::Blip)
	function _it()
		while has_active_edge_out(b)
			produce(b)
			b = next_blip_in_track(b)
		end
		produce(b)
	end
	return Task(_it)
end

function track_length_forward(b::Blip)
	n = 0
	for b in iter_track(b)
		n += 1
	end
	return n - 1 # number of edges, not blips
end

function iter_track_reverse(b::Blip)
	function _it()
		while has_active_edge_in(b)
			produce(b)
			b = prev_blip_in_track(b)
		end
		produce(b)
	end
	return Task(_it)
end

function track_length_reverse(b::Blip)
	n = 0
	for b in iter_track_reverse(b)
		n += 1
	end
	return n - 1 # number of edges, not blips
end

function track_length(b::Blip; reverse=false)
	if reverse
		return track_length_reverse(b)
	else
		return track_length_forward(b)
	end
end


function get_track(b1::Blip)
	verts = [b1]
	eds = Edge[]
	while has_active_edge_out(b1)
		e, b2 = next_in_track(b1)
		push!(verts, b2)
		push!(eds, e)
		b1 = b2
	end
	return eds, verts
end

connected(b1::Blip, b2::Blip) = b2 in out_neighbors(b1)

function connecting_edge(b1::Blip, b2::Blip, sg::ScanGraph)
	for e in b1.out_edges
		if e.target == b2
			return e
		end
	end
end

# ## Number of detected targets (i.e., blips assigned to a track)
function n_targets(sg::ScanGraph, t::Integer)
	n = 0
	for i in 1:length(sg.scans[t])
		if in_track(sg.scans[t][i])
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

# ## Number of false targets (i.e., blips not assigned to a track; clutter)
function n_false_targets(sg::ScanGraph, t::Integer)
	n = 0
	for i in 1:length(sg.scans[t])
		if ! in_track(sg.scans[t][i])
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


start_time(e::Edge) = e.source.t
end_time(e::Edge) = e.target.t

## Number of targets (detected and undetected) present
function n_tracks(sg::ScanGraph, t::Integer)
	n = 0
	for e in sg.edges
		if e.active && start_time(e) < t && end_time(e) > t
			n += 1
		end
	end
	return n + n_targets(sg, t)
end

function n_tracks(sg::ScanGraph, t1::Integer, t2::Integer)
	n = 0
	for i in t1:t2
		n += n_tracks(sg, i)
	end
	return n
end

## Number of tracks starting in this timestep
function n_tracks_started(sg::ScanGraph, t::Integer)
	n = 0
	for blip in sg.scans[t]
		if starts_track(blip)
			n += 1
		end
	end
	return n
end

## Number of tracks in range
function n_tracks_started(sg::ScanGraph, t1::Integer, t2::Integer)
	n = 0
	for i in t1:t2
		n += n_tracks_started(sg, i)
	end
	return n
end

## Number of tracks in entire graph
n_tracks_started(sg::ScanGraph) = n_tracks_started(sg, 1, sg.nscans)
n_tracks(sg::ScanGraph) = n_tracks_started(sg, 1, sg.nscans)

## Number of tracks ending in this timestep
function n_tracks_ended(sg::ScanGraph, t::Integer)
	n = 0
	for blip in sg.scans[t]
		if ends_track(blip)
			n += 1
		end
	end
	return n
end

function n_tracks_ended(sg::ScanGraph, t1::Integer, t2::Integer)
	n = 0
	for i in t1:t2
		n += n_tracks_ended(sg, i)
	end
	return n
end
n_tracks_ended(sg::ScanGraph) = n_tracks_ended(sg, 1, sg.nscans)


function n_proposed(sg::ScanGraph, t1::Integer, t2::Integer)
	n = 0
	for t in t1:(t2 - 1) # only consider edges inside range
		for blip in sg.scans[t]
			for edge in blip.out_edges
				if edge.proposed
					n += 1
				end
			end
		end
	end
	return n
end
n_proposed(sg::ScanGraph) = n_proposed(sg, 1, sg.nscans)


function iter_blips(sg::ScanGraph, t1::Integer, t2::Integer)
	function producer()
		for t in t1:t2
			for blip in sg.scans[t]
				produce(blip)
			end
		end
	end
	return Task(producer)
end
iter_blips(sg::ScanGraph, t::Integer) = iter_blips(sg, t, t)
iter_blips(sg::ScanGraph) = iter_blips(sg, 1, sg.nscans)


function track_start_indices(sg::ScanGraph, t1::Integer, t2::Integer)
	indices = Int64[]
	scans = Int64[]
	for i in t1:t2
		for j in 1:length(sg.scans[i])
			if starts_track(sg.scans[i][j])
				push!(scans, i)
				push!(indices, j)
			end
		end
	end
	return (scans, indices)
end

function track_start_indices(sg::ScanGraph)
	return track_start_indices(sg, 1, sg.nscans)
end

function track_start_indices(sg::ScanGraph, t::Integer)
	return track_start_indices(sg, t, t)
end

function track_end_indices(sg::ScanGraph, t1::Integer, t2::Integer)
	indices = Int64[]
	scans = Int64[]
	for i in t1:t2
		for j in 1:length(sg.scans[i])
			if ends_track(sg.scans[i][j])
				push!(scans, i)
				push!(indices, j)
			end
		end
	end
	return (scans, indices)
end

function track_end_indices(sg::ScanGraph)
	return track_end_indices(sg, 1, sg.nscans)
end

function track_end_indices(sg::ScanGraph, t::Integer)
	return track_end_indices(sg, t, t)
end




function false_target_indices(sg::ScanGraph)
	return find(Bool[! in_track(blip) for blip in sg.blips])
end

function false_target_indices(sg::ScanGraph, t::Integer)
	return find(Bool[! in_track(blip) for blip in sg.scans[t]])
end

function in_track_indices(sg::ScanGraph)
	return find(Bool[in_track(blip) for blip in sg.blips])
end

function in_track_indices(sg::ScanGraph, t::Integer)
	return find(Bool[in_track(blip) for blip in sg.scans[t]])
end
