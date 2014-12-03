
# Blip: encapsulates information about a target detection
type Blip{T}
	x::Vector{T}
	t::T
end
Blip{T1, T2}(x::Array{T1, 1}, t::T2) = Blip(x, convert(T1, t))

function distance{T}(b1::Blip{T}, b2::Blip{T})
	return sqrt(sum((b1.x - b2.x).^2))
end

function get_blip(v::ExVertex)
	return v.attributes["blip"]
end

# data structure to track blips in time, and their connections to each other
type ScanGraph
	scans::Vector{Vector{ExVertex}}
	graph::AbstractGraph
	nblips::Vector{Int64}
	nscans::Int64
end

function show(io::IO, g::ScanGraph)
	ns = g.nscans
	nv = num_vertices(g.graph)
	ne = num_edges(g.graph)
	na = sum([e.attributes["active"] for e in edges(g.graph)])
	println("ScanGraph: $(ns) scans, $(nv) blips, $(ne) connections ($(na) active)")
end
