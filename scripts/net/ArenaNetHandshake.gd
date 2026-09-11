extends Node
class_name ArenaNetHandshake

# Échange d'ouverture réseau Arena — même rôle que NetHandshake.gd (1v1),
# généralisé à un quorum de N pairs en topologie étoile (voir ArenaNetTransport) :
# l'hôte attribue un seat_id stable à chaque client au fil de leur connexion
# (voir ArenaPlayerState.seat_id / ArenaMatch, Phase 1 du chantier réseau
# Arena), combine une contribution de graine RNG par pair (XOR — même principe
# que NetHandshake : aucun pair ne peut choisir seul la graine finale) et ne
# démarre la partie qu'une fois la table complète
# (ArenaConstants.PARTICIPANT_COUNT - 1 clients connectés).
#
# Simplification assumée pour cette étape de fondation (contrairement à
# NetHandshake) : pas de renvoi automatique du HELLO en cas de perte de
# paquet — la fiabilisation du handshake réseau reste à traiter dans une
# phase ultérieure, une fois ce protocole branché sur une vraie partie.
#
# Émis une fois la partie prête à démarrer : `setup` contient "seed" (int,
# identique pour tous), "seat_id" (le sien), "roster" (Array de
# {seat_id, display_name}, trié par seat_id — siège 0 = hôte).
signal completed(setup: Dictionary)
signal progress(message: String)

var _net: ArenaNetworkManager
var _is_host: bool
var _local_display_name: String
var _local_seed_contribution: int = randi()
var _finished: bool = false

# Hôte uniquement : construit au fil des HELLO reçus.
var _seat_by_peer: Dictionary = {}          # peer_id -> seat_id
var _display_name_by_seat: Dictionary = {}  # seat_id -> display_name
var _seed_by_seat: Dictionary = {}          # seat_id -> contribution
var _next_seat_id: int = 1                  # 0 réservé à l'hôte

# Client uniquement.
var _host_peer_id: int = 0
var _own_seat_id: int = -1

func _init(net: ArenaNetworkManager, is_host: bool, local_display_name: String) -> void:
	_net = net
	_is_host = is_host
	_local_display_name = local_display_name
	_net.command_received.connect(_on_command_received)
	if not _is_host:
		_net.peer_joined.connect(_on_peer_joined_as_client)

# Hôte uniquement : s'attribue lui-même le siège 0. Un client n'a rien à
# envoyer avant d'être effectivement connecté à l'hôte (voir
# _on_peer_joined_as_client) — appeler start() ne fait donc rien côté client.
func start() -> void:
	if not _is_host:
		return
	_display_name_by_seat[0] = _local_display_name
	_seed_by_seat[0] = _local_seed_contribution

func cancel() -> void:
	if _finished:
		return
	_finished = true
	if _net.command_received.is_connected(_on_command_received):
		_net.command_received.disconnect(_on_command_received)

# ── Côté client ──

func _on_peer_joined_as_client(peer_id: int, _display_name: String) -> void:
	# Un seul pair possible côté client (l'hôte) : voir ArenaNetTransport —
	# send()/receive() y ignorent déjà peer_id, mais le mémoriser explicitement
	# reste correct et prêt pour une future topologie où ce ne serait plus vrai.
	_host_peer_id = peer_id
	_net.send_command(_host_peer_id, ArenaNetCommand.hello(_local_display_name, _local_seed_contribution))
	progress.emit("Handshake Arena : connecté à l'hôte, en attente d'un siège…")

# ── Réception (les deux rôles partagent le même signal) ──

func _on_command_received(peer_id: int, command: Dictionary) -> void:
	match ArenaNetCommand.type_of(command):
		ArenaNetCommand.HELLO:
			if _is_host:
				_register_client(peer_id, command)
		ArenaNetCommand.SEAT_ASSIGN:
			if not _is_host:
				_own_seat_id = int(command.get("seat_id", -1))
				progress.emit("Handshake Arena : siège %d attribué" % _own_seat_id)
		ArenaNetCommand.START_MATCH:
			if not _is_host:
				_finish(int(command.get("seed", 0)), command.get("roster", []))

# ── Côté hôte ──

func _register_client(peer_id: int, command: Dictionary) -> void:
	if _seat_by_peer.has(peer_id):
		return  # HELLO dupliqué (paquet renvoyé) : siège déjà attribué, rien à refaire
	var seat_id: int = _next_seat_id
	_next_seat_id += 1
	_seat_by_peer[peer_id] = seat_id
	_display_name_by_seat[seat_id] = str(command.get("display_name", "Joueur"))
	_seed_by_seat[seat_id] = int(command.get("seed", 0))
	_net.send_command(peer_id, ArenaNetCommand.seat_assign(seat_id))
	progress.emit("Handshake Arena : « %s » a rejoint (siège %d, %d/%d)" % [
		_display_name_by_seat[seat_id], seat_id, _seat_by_peer.size(), ArenaConstants.PARTICIPANT_COUNT - 1])
	if _seat_by_peer.size() >= ArenaConstants.PARTICIPANT_COUNT - 1:
		_start_match()

func _start_match() -> void:
	var combined_seed: int = 0
	for seat_id in _seed_by_seat:
		combined_seed ^= int(_seed_by_seat[seat_id])
	var roster: Array = _build_roster()
	_net.broadcast_command(ArenaNetCommand.start_match(combined_seed, roster))
	_finish(combined_seed, roster)

func _build_roster() -> Array:
	var seat_ids: Array = _display_name_by_seat.keys()
	seat_ids.sort()
	var roster: Array = []
	for seat_id in seat_ids:
		roster.append({"seat_id": seat_id, "display_name": _display_name_by_seat[seat_id]})
	return roster

func _finish(seed: int, roster: Array) -> void:
	if _finished:
		return
	_finished = true
	if _net.command_received.is_connected(_on_command_received):
		_net.command_received.disconnect(_on_command_received)
	completed.emit({
		"seed": seed,
		"seat_id": 0 if _is_host else _own_seat_id,
		"roster": roster,
	})
