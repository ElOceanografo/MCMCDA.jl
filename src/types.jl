
# Blip: encapsulates information about a target detection
type Blip{T}
	x::Vector{Float64}
	t::Int64
	in_edges::Vector{T}
	out_edges::Vector{T}
end

function show{T}(io::IO, b::Blip{T})
	print("Blip: $(length(b.in_edges))/$(length(b.out_edges)) edges in/out.")
end

function distance{T}(b1::Blip{T}, b2::Blip{T})
	return norm(b1.x - b2.x)
end

function out_neighbors{T}(b::Blip{T})
	return [e.target for e in b.out_edges]
end

function in_neighbors{T}(b::Blip{T})
	return [e.target for e in b.in_edges]
end

# Edge: connection between blips in the target graph
type Edge
	source::Blip
	target::Blip
	active::Bool
	proposed::Bool
	n_active::Int64
	n_inactive::Int64
end

# data structure to track blips in time, and their connections to each other
type ScanGraph
	scans::Vector{Vector{Blip}}
	blips::Vector{Blip}
	edges::Vector{Edge}
	nblips::Vector{Int64}
	nscans::Int64
end


function show(io::IO, sg::ScanGraph)
	ns = sg.nscans
	nv = sum([length(b) for b in sg.scans])
	ne = length(sg.edges)
	na = sum([e.active for e in sg.edges])
	print("ScanGraph: $(ns) scans, $(nv) blips, $(ne) connections ($(na) active)")
end


function _next_in_track(b::Blip)
	for e in b.out_edges
		if e.active
			return e.target
		end
	end
	return b # for type-stability...should never actually evaluate!
end

function iter_track(b::Blip)
	function _it()
		while has_active_edge_out(b)
			produce(b)
			b = _next_in_track(b)
		end
		produce(b)
	end
	return Task(_it)
end

function track_length(b1::Blip)
	n = 0
	for b in iter_track(b1)
		n += 1
	end
	return n - 1 # number of edges, not blips
end