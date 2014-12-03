module MCMCDA

using Distributions, DataFrames, Graphs, StateSpace
import Base: show

export Blip, 
	ScanGraph, 
	read_targets,
	connect_graph!,
	loglikelihood,
	track_loglikelihood,
	n_false_targets,
	next_target,
	starts_track,
	ends_track,
	in_track,
	has_link_in,
	has_link_out,
	n_edges,
	all_edges

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

function show(io::IO, g::ScanGraph)
	ns = g.nscans
	nv = num_vertices(g.graph)
	ne = num_edges(g.graph)
	na = sum([e.attributes["active"] for e in edges(g.graph)])
	println("ScanGraph: $(ns) scans, $(nv) blips, $(ne) connections ($(na) active)")
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


function connect_graph!(g::ScanGraph, max_distance, max_missed)
	edge_i = 1
	for i in 1:(g.nscans - max_missed)
		for j in (i + 1):(i + max_missed)
			for m in 1:length(g.scans[i])
				for n in 1:length(g.scans[j])
					v1 = g.scans[i][m]
					v2 = g.scans[j][n]
					if ! (v2 in out_neighbors(v1, g.graph))
						if distance(get_blip(v1), get_blip(v2)) < max_distance
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
end


function n_edges(v::ExVertex, g::AbstractGraph)
	return in_degree(v, g) + out_degree(v, g)
end

function all_edges(v::ExVertex, g::AbstractGraph)
	return [in_edges(v, g), out_edges(v, g)]
end

function in_track(v::ExVertex, sg::ScanGraph)
	return any([e.attributes["active"] for e in all_edges(v, sg.graph)])
end

function has_link_in(v::ExVertex, sg::ScanGraph)
	for e in in_edges(v, sg.graph)
		if e.attributes["active"]
			return true
		end
	end
	return false
end

function has_link_out(v::ExVertex, sg::ScanGraph)
	for e in out_edges(v, sg.graph)
		if e.attributes["active"]
			return true
		end
	end
	return false
end


function starts_track(v::ExVertex, sg::ScanGraph)
	return (! has_link_in(v, sg)) && has_link_out(v, sg)
end

function ends_track(v::ExVertex, sg::ScanGraph)
	return has_link_in(v, sg) && (! has_link_out(v, sg))
end


function n_false_targets(sg::ScanGraph)
	n = 0
	for v in vertices(sg.graph)
		if ! in_track(v, sg)
			n += 1
		end
	end
	return n
end

function next_target(v::ExVertex, sg::ScanGraph)
	for e in out_edges(v, sg.graph)
		if e.attributes["active"]
			return target(e)
		end
	end
	return nothing
end

function track_loglikelihood(v::ExVertex, sg::ScanGraph, 
		track_model::LinearGaussianSSM, sigma0=100)
	LL = 0
	state0 = [v.attributes["blip"].x, 0, 0]
	state_filt = MvNormal(state0, sigma0)
	while ! ends_track(v, sg)
		state_pred = predict(track_model, state_filt)
		v_next = next_target(v, sg)
		state_filt = update(track_model, state_pred, v_next.attributes["blip"].x)
		LL += logpdf(state_pred, mean(state_filt))
		LL += logpdf(observe(track_model, state_filt), v_next.attributes["blip"].x)
		v = v_next
	end
	return LL
end


function loglikelihood(sg::ScanGraph, lambda::Float64, 
		track_model::LinearGaussianSSM)
	LL = 0
	LL += logpdf(Poisson(lambda), n_false_targets(sg))
	for v in vertices(sg.graph)
		if starts_track(v, sg)
			LL += track_loglikelihood(v, sg, track_model)
		end
	end
	return LL
end


end # module
