
function propose_birth!(sg::ScanGraph, t1::Integer, t2::Integer, gamma=0.1)
	# choose time
	# v1 = choose false target
	# while target has outgoing edges && rand() > gamma
	# 	choose random edge
	#	make it active
	#	v1 = v2
end

function propose_death!(sg::ScanGraph, t1::Integer, t2::Integer)
	track_start_indices = find(Bool[starts_track(v, sg) for v in edges(sg.graph)])
	v1 = vertices(sg.graph)[sample(track_start_indices)]
	while has_link_out(v1, sg)
		e2, v2 = next_in_track(v1)
		e2.attributes["proposed"] = true
		e2.attributes["active"] = false
	end
end

function propose_split!(sg::ScanGraph, t1::Integer, t2::Integer)
	# choose random track
end

function propose_merge!(sg::ScanGraph, t1::Integer, t2::Integer)
	#function body
end

function propose_extend!(sg::ScanGraph, t1::Integer, t2::Integer)
	# choose random track
	# extend
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

function undo_move!(sg::ScanGraph, t1::Integer, t2::Integer)
	for e in edges(sg.graph)
		if e.attributes["proposed"]
			e.attributes["active"] = ! e.attributes["active"]
			e.attributes["proposed"] = false
		end
	end
end

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
