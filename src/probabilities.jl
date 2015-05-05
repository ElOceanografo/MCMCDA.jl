
function track_loglikelihood(b0::Blip, track_model::LinearGaussianSSM,
		sigma0=100.0)
	loglik = 0
	state0 = zeros(size(track_model.F, 1))
	state0[1:length(b0.x)] = b0.x
	state_filt = MvNormal(state0, sigma0)
	for b in iter_track(b0)
		state_pred = predict(track_model, state_filt)
		state_filt = update(track_model, state_pred, b.x)
		loglik += logpdf(state_pred, mean(state_filt))
		loglik += logpdf(observe(track_model, state_filt), b.x)
	end
	return loglik
end

function loglikelihood(sg::ScanGraph, lambda_f::Float64, 
		track_model::LinearGaussianSSM, t1, t2, sigma0=100.0)
	LL = 0
	for i in t1:t2
		# false detections
		LL += logpdf(Poisson(lambda_f), n_false_targets(sg, i))
		# actual targets
		for blip in sg.scans[i]
			if starts_track(blip)
				LL += track_loglikelihood(blip, track_model, sigma0)
			end
		end
	end
	return LL
end

function loglikelihood(sg::ScanGraph, lambda_f::Float64, 
		track_model::LinearGaussianSSM, sigma0=100.0)
	return loglikelihood(sg, lambda_f, track_model, 1, sg.nscans, sigma0)
end

function summary_numbers(sg::ScanGraph, i::Integer)
	zt = n_tracks_ended(sg, i)
	nt = n_tracks(sg, i) # total tracks present
	at = n_tracks_started(sg, i) # new ones this step
	ct = nt - zt - at # tracks continuing from last sweep
	dt = n_targets(sg, i) # total detected
	gt = nt - dt # number of undetected targets
	ft = n_false_targets(sg, i)
	return (zt, ct, dt, gt, at, ft)
end

function config_logprior(sg::ScanGraph, params::Vector{Float64}, t1::Integer, t2::Integer)
	# parameters
	pz, pd, lambda_b, lambda_f = params
	@assert (pz > 0) && (pd > 0) "Probabilities must be > 0"
	@assert (pz < 1) && (pd < 1) "Probabilities must be < 1"

	LP = 0
	for i in t1:t2
		zt, ct, dt, gt, at, ft = summary_numbers(sg, i)
		# add log probabilities for each piece of the prior (Oh et al eqn. 9)
		LP += zt * log(pz) + ct * log(1 - pz)
		LP += dt * log(pd) +  gt * log(1 - pd)
		LP += at * log(lambda_b)
		LP += ft * log(lambda_f)
	end
	return LP
end

function config_logprior(sg::ScanGraph, params::Vector{Float64})
	return config_logprior(sg, params, 1, sg.nscans)
end

function log_posterior(sg::ScanGraph, params::Vector{Float64}, 
		track_model::LinearGaussianSSM, t1, t2, sigma0=100.0)
	LL = loglikelihood(sg, params[4], track_model, t1, t2, sigma0)
	return LL + config_logprior(sg, params, t1, t2)
end

function log_posterior(sg::ScanGraph, params::Vector{Float64}, 
		track_model::LinearGaussianSSM, sigma0=100.0)
	log_posterior(sg, params, track_model, 1, sg.nscans, sigma0)
end
