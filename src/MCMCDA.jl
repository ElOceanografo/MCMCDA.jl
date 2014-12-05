module MCMCDA

using Distributions, DataFrames, Graphs, StateSpace
import Base: show

export Blip, 
	get_blip,
	ScanGraph, 
	read_targets,
	connect_graph!,
	loglikelihood,
	track_loglikelihood,
	config_logprior,
	log_posterior,
	summary_numbers,
	n_targets,
	n_false_targets,
	next_target,
	starts_track,
	ends_track,
	n_tracks_started,
	n_tracks_ended,
	track_start_indices,
	in_blips,
	out_blips,
	next_in_track,
	in_track,
	has_link_in,
	has_link_out,
	connected,
	n_edges,
	all_edges,
	start_time,
	end_time,
	n_tracks,
	propose_birth!,
	propose_death!,
	propose_split!,
	propose_merge!,
	propose_extend!,
	propose_reduce!,
	propose_update!,
	propose_switch!,
	propose_move!,
	undo_move!,
	accept_move!

#################################################

include("types.jl")
include("io.jl")
include("connections.jl")
include("probabilities.jl")
include("proposal_moves.jl")

end # module
