
# Blip: encapsulates information about a target detection
type Blip{T}
	x::Vector{Float64}
	in_edges::Vector{T}
	out_edges::Vector{T}
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
	println("ScanGraph: $(ns) scans, $(nv) blips, $(ne) connections ($(na) active)")
end
