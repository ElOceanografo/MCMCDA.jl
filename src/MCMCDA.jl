module MCMCDA

using Distributions, StateSpace, Graphs

export Blip, ScanGraph

type Blip{T}
	x::Vector{T}
end

type ScanGraph{T}
	scans::Vector{Vector{Blip{T}}}
	graph::AbstractGraph
	nblips::Vector{Int64}
	nscans::Int64
end


end # module