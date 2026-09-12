extends RefCounted
class_name ArenaClientGameLink

# Relie le protocole de partie (ArenaGameCommand) au reste de la pile réseau,
# CÔTÉ CLIENT (jamais l'hôte) : envoie les REQUEST_* du joueur local à l'hôte
# (send_request) et applique les réponses reçues au bon ArenaPlayerState
# local — BOARD_SYNC (n'importe quel siège, via ArenaRemoteBoardMirror) et
# PRIVATE_STATE_SYNC (uniquement si c'est le sien, via ArenaPrivateStateMirror).
#
# Suppose que `match_.players` contient déjà tous les sièges (même non
# encore synchronisés), avec les seat_id attribués par ArenaNetHandshake
# (voir son champ "roster" dans `completed`) — ce lien ne crée ni ne
# supprime jamais de siège, il ne fait que refléter leur état.
#
# `host_peer_id` : ignoré par ArenaNetTransport côté client (un seul pair
# possible, l'hôte — voir ArenaNetTransport) mais conservé explicitement,
# correct et prêt pour une future topologie où ce ne serait plus vrai.

var match_: ArenaMatch
var net: ArenaNetworkManager
var own_seat_id: int
var host_peer_id: int

func _init(_match: ArenaMatch, _net: ArenaNetworkManager, _own_seat_id: int, _host_peer_id: int) -> void:
	match_ = _match
	net = _net
	own_seat_id = _own_seat_id
	host_peer_id = _host_peer_id
	net.command_received.connect(_on_command_received)

func send_request(command: Dictionary) -> void:
	net.send_command(host_peer_id, command)

func _on_command_received(_peer_id: int, command: Dictionary) -> void:
	match ArenaGameCommand.type_of(command):
		ArenaGameCommand.BOARD_SYNC:
			ArenaRemoteBoardMirror.apply(match_, command)
		ArenaGameCommand.PRIVATE_STATE_SYNC:
			if int(command.get("seat_id", -1)) == own_seat_id:
				var player: ArenaPlayerState = match_.find_by_seat(own_seat_id)
				if player != null:
					ArenaPrivateStateMirror.apply(player, command)
