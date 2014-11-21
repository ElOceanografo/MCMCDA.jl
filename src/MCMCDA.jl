module MCMCDA

using Distributions, DataFrames, Graphs, StateSpace

export Blip, 
	ScanGraph, 
	read_targets

type Blip{T}
	x::Vector{T}
	t::T
end
Blip{T1, T2}(x::Array{T1, 1}, t::T2) = Blip(x, convert(T1, t))

type ScanGraph{T}
	scans::Vector{Vector{Blip{T}}}
	graph::AbstractGraph
	nblips::Vector{Int64}
	nscans::Int64
end

function read_targets(filename)
	blip_table = readtable("data/test_targets.csv")
	scans = Vector{Blip}[]
	for df in groupby(blip_table, :t)
		blips = [Blip(vec(array(df[i, [:x, :y]])), df[i, :t])
					for i in 1:size(df, 1)]
		push!(scans, blips)
	end
	return scans
end

end # module
