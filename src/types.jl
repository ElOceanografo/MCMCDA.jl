
# Blip: encapsulates information about a target detection
# E is the edge type
type Blip{T, E}
	x::Array{T, 1}
	t::T
	in_edges::Array{E, 1}
	out_edges::Array{E, 1}
end

function show{T}(io::IO, b::Blip{T})
	print("Blip: $(length(b.in_edges))/$(length(b.out_edges)) edges in/out.")
end

function distance{B<:Blip}(b1::B, b2::B)
	return norm(b1.x - b2.x)
end

function out_neighbors{T}(b::Blip{T})
	return [e.target for e in b.out_edges]
end

function in_neighbors{T}(b::Blip{T})
	return [e.target for e in b.in_edges]
end

# Edge: connection between blips in the target graph
type Edge{T, I<:Integer}
	source::Blip{T}
	target::Blip{T}
	active::Bool
	proposed::Bool
	n_active::I
	n_inactive::I
end

# data structure to track blips in time, and their connections to each other
type ScanGraph{B, E, I<:Integer}
	scans::Array{Array{B, 1}, 1}
	blips::Array{B, 1}
	edges::Array{E, 1}
	nblips::Array{I, 1}
	nscans::I
end


function show(io::IO, sg::ScanGraph)
	ns = sg.nscans
	nv = sum([length(b) for b in sg.scans])
	ne = length(sg.edges)
	na = sum([e.active for e in sg.edges])
	print("ScanGraph: $(ns) scans, $(nv) blips, $(ne) connections ($(na) active)")
end

