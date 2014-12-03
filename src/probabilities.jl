
function track_loglikelihood(v::ExVertex, sg::ScanGraph, 
		track_model::LinearGaussianSSM, sigma0=100)
	LL = 0
	state0 = [v.attributes["blip"].x, 0, 0]
	state_filt = MvNormal(state0, sigma0)
	while ! ends_track(v, sg)
		state_pred = predict(track_model, state_filt)
		v_next = next_in_track(v, sg)
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