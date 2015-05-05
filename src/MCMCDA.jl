module MCMCDA

using Distributions, StateSpace
import Base: show

export Blip,
	Edge,
	ScanGraph,
	show,
	distance,
	out_neighbors,
	in_neighbors,
	read_targets,
	connect_graph!,
	has_active_edge_in,
	has_active_edge_out,
	in_track,
	starts_track,
	ends_track,
	iter_track,
	track_length,
	next_in_track,
	n_tracks_started,
	n_tracks_ended,
	n_tracks,
	n_targets,
	n_false_targets,
	connected,
	connecting_edge,
	n_proposed,
	false_target_indices,
	in_track_indices,
	# probabilities.jl
	track_loglikelihood,
	loglikelihood,
	config_logprior,
	log_posterior,
	# proposal_moves.jl
	extend!,
	reject_move!,
	accept_move!,
	propose_birth!,
	propose_death!,
	propose_split!,
	propose_extend!,
	propose_reduce!,
	propose_merge!,
	propose_switch!,
	propose_update!,
	propose_move!,
	# samplers.jl
	mcmcda!

#################################################

include("types.jl")
include("io.jl")
include("connections.jl")
include("probabilities.jl")
include("proposal_moves.jl")
include("samplers.jl")

end # module
