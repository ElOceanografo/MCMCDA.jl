function mcmcda!(sg::ScanGraph, t1::Integer, t2::Integer, n_iter::Integer, 
	params::Vector{Float64}, track_model::LinearGaussianSSM, gamma=0.1)
	LP1 = log_posterior(sg, params, track_model)
	for i in 1:n_iter
		propose_move!(sg, t1, t2, gamma)
		LP2 = log_posterior(sg, params, track_model)
		p_accept = min(1, exp(LP2 - LP1))
		if rand() < p_accept
			accept_move!(sg)
		else
			reject_move!(sg)
		end
	end
end
