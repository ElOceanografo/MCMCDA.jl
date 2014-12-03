
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
