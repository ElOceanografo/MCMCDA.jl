
function read_targets(filename, x_cols=1:2, t_col=3; args...)
	blip_table = readcsv("data/test_targets.csv"; args...)
	T = eltype(blip_table)
	I = Int
	n = size(blip_table, 1)

	blips = Array(Blip{T}, n)

	for i in 1:n
		blips[i] = Blip(vec(blip_table[i, x_cols]), blip_table[i, t_col],
			Edge{T, I}[], Edge{T, I}[])
	end
	times = blip_table[:, t_col]
	scan_type = typeof(blips)
	scans = scan_type[blips[times .== t] for t in unique(times)]
	nblips = I[length(s) for s in scans]
	nscans = length(scans)
	return ScanGraph(scans, blips, Edge{T, I}[], nblips, nscans)
end
