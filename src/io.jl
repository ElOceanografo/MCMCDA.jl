
function read_targets(filename)
	blip_table = readtable("data/test_targets.csv")
	scans = Vector{Blip}[]
	blips = Blip[]
	# make array of arrays of blips
	for df in groupby(blip_table, :t)
		this_scan = Blip[]
		for i in 1:size(df, 1)
			b = Blip(vec(array(df[i, [:x, :y]])), Edge[], Edge[])
			push!(this_scan, b)
			push!(blips, b)
		end
		push!(scans, this_scan)
	end
	nblips = [length(scan) for scan in scans]
	nscans = length(scans)
	edges = Edge[]
	return ScanGraph(scans, blips, edges, nblips, nscans)
end
