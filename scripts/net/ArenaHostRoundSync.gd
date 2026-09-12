extends RefCounted
class_name ArenaHostRoundSync

# Diffuse à tous les clients l'état consécutif à une manche résolue côté hôte
# (voir ArenaMatch.start_combat_phase/advance_round) : un BOARD_SYNC pour
# CHAQUE siège — le combat peut changer le plateau/PV de n'importe quel
# participant, pas seulement celui qui a demandé quelque chose, donc
# ArenaHostGameRouter (qui ne répond qu'à l'émetteur d'une REQUEST_*) ne
# suffit pas ici — puis ROUND_ADVANCED (nouvelle manche) ou GAME_OVER
# (classement final) selon l'état de la partie.
#
# À appeler côté hôte UNIQUEMENT, après match_.start_combat_phase() et avant
# match_.advance_round() (pour que round_number diffusé soit bien celui de la
# manche qui VIENT de se jouer, voir ArenaBattle).

static func broadcast_after_combat(match_: ArenaMatch, net: ArenaNetworkManager) -> void:
	for player in match_.players:
		net.broadcast_command(ArenaGameCommand.board_sync(
			player.seat_id, player.hero_hp,
			ArenaBoardSnapshot.serialize_row(player.board_front),
			ArenaBoardSnapshot.serialize_row(player.board_back)))
	if match_.is_match_over():
		net.broadcast_command(ArenaGameCommand.game_over(_serialize_ranking(match_.final_ranking())))
	else:
		net.broadcast_command(ArenaGameCommand.round_advanced(match_.round_number, match_.last_combat_summaries))

static func _serialize_ranking(ranking: Array) -> Array:
	var out: Array = []
	for player in ranking:
		out.append({"seat_id": player.seat_id, "display_name": player.display_name})
	return out
