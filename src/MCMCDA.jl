module MCMCDA

using Distributions, DataFrames, Graphs, StateSpace

export Blip, 
	ScanGraph, 
	read_targets,
	link!

#################################################

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

type ScanGraph
	scans::Vector{Vector{ExVertex}}
	graph::AbstractGraph
	nblips::Vector{Int64}
	nscans::Int64
end

function read_targets(filename)
	blip_table = readtable("data/test_targets.csv")
	scans = Vector{ExVertex}[]
	g = graph(ExVertex[], ExEdge{ExVertex}[], is_directed=true)
	vertex_i = 1
	# make array of arrays of blips
	for df in groupby(blip_table, :t)
		this_scan = ExVertex[]
		for i in 1:size(df, 1)
			b = Blip(vec(array(df[i, [:x, :y]])), df[i, :t])
			v = ExVertex(vertex_i, string(vertex_i))
			v.attributes["blip"] = b
			push!(this_scan, v)
			add_vertex!(g, v)
			vertex_i += 1
		end
		push!(scans, this_scan)
	end
	nblips = [length(scan) for scan in scans]
	nscans = length(scans)
	return ScanGraph(scans, g, nblips, nscans)
end


# max_missed = floor(log(1 - p_max_lost) / log(p_detect))
# max_missed = max(max_missed, 1)
# max_missed = min(g.nscans - 1, max_missed)


function link!(g::ScanGraph, max_dist, max_missed)
	edge_i = 1
	for i in 1:(g.nscans - max_missed)
		for j in (i + 1):(i + max_missed)
			for m in 1:length(g.scans[i])
				for n in 1:length(g.scans[j])
					v1 = g.scans[i][m]
					v2 = g.scans[j][n]
					if distance(get_blip(v1), get_blip(v2)) < max_dist
						e = ExEdge(edge_i, v1, v2)
						e.attributes["active"] = false
						add_edge!(g.graph, e)
						edge_i += 1
					end
				end
			end
		end
	end
end

end # module
