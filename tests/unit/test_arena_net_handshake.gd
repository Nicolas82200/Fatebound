extends GutTest

# Teste le protocole ArenaNetHandshake en pure logique, via un transport
# simulé (FakeArenaNetTransport/FakeArenaNetHub — livraison synchrone,
# topologie étoile) : aucune dépendance à Steam, contrairement à
# ArenaSteamTransport lui-même (voir CLAUDE.md « Tests automatisés »).

# Construit 1 hôte + `client_count` clients, tous connectés et ayant lancé
# leur handshake. `results` est peuplé au fil des complétions (clé "host" ou
# "client_<i>" -> setup) : connecté AVANT chaque start()/join() pour ne rater
# aucune complétion, la cascade hôte<->client étant entièrement synchrone.
func _build_rig(client_count: int) -> Dictionary:
	var hub := FakeArenaNetHub.new()
	var results: Dictionary = {}

	var host_transport := FakeArenaNetTransport.new(hub, 1, true)
	var host_net := ArenaNetworkManager.new()
	autofree(host_net)
	host_net.is_host = true
	host_net.set_transport(host_transport)
	var host_handshake := ArenaNetHandshake.new(host_net, true, "Hôte")
	autofree(host_handshake)
	host_handshake.completed.connect(func(setup: Dictionary) -> void: results["host"] = setup)
	host_handshake.start()
	host_transport.host({})

	var client_handshakes: Array = []
	for i in client_count:
		var peer_id: int = 100 + i
		var client_transport := FakeArenaNetTransport.new(hub, peer_id, false)
		var client_net := ArenaNetworkManager.new()
		autofree(client_net)
		client_net.is_host = false
		client_net.set_transport(client_transport)
		var handshake := ArenaNetHandshake.new(client_net, false, "Joueur %d" % (i + 1))
		autofree(handshake)
		var key: String = "client_%d" % i
		handshake.completed.connect(func(setup: Dictionary) -> void: results[key] = setup)
		handshake.start()
		client_transport.join({})  # déclenche la cascade HELLO -> SEAT_ASSIGN (-> START_MATCH si la table se complète)
		client_handshakes.append(handshake)

	return {"results": results, "host_handshake": host_handshake, "client_handshakes": client_handshakes}

func test_match_does_not_start_before_the_table_is_full() -> void:
	var rig: Dictionary = _build_rig(ArenaConstants.PARTICIPANT_COUNT - 2)  # une place vacante
	assert_eq(rig.results.size(), 0, "personne ne doit recevoir START_MATCH tant qu'un siège reste vacant")

func test_match_starts_once_the_table_is_full() -> void:
	var rig: Dictionary = _build_rig(ArenaConstants.PARTICIPANT_COUNT - 1)
	assert_true(rig.results.has("host"), "l'hôte doit démarrer dès que la table est complète")
	for i in ArenaConstants.PARTICIPANT_COUNT - 1:
		assert_true(rig.results.has("client_%d" % i), "chaque client doit recevoir START_MATCH")

func test_all_participants_agree_on_the_same_seed() -> void:
	var rig: Dictionary = _build_rig(ArenaConstants.PARTICIPANT_COUNT - 1)
	var seed: int = rig.results["host"]["seed"]
	for key in rig.results:
		assert_eq(rig.results[key]["seed"], seed, "tous les participants doivent calculer la même graine combinée")

func test_seats_are_assigned_uniquely_and_host_is_always_seat_zero() -> void:
	var rig: Dictionary = _build_rig(ArenaConstants.PARTICIPANT_COUNT - 1)
	assert_eq(rig.results["host"]["seat_id"], 0)
	var seen_seats: Array = [0]
	for i in ArenaConstants.PARTICIPANT_COUNT - 1:
		var seat: int = rig.results["client_%d" % i]["seat_id"]
		assert_false(seen_seats.has(seat), "chaque siège doit être unique")
		seen_seats.append(seat)
	assert_eq(seen_seats.size(), ArenaConstants.PARTICIPANT_COUNT)

func test_roster_is_sorted_by_seat_id_and_includes_everyone() -> void:
	var rig: Dictionary = _build_rig(ArenaConstants.PARTICIPANT_COUNT - 1)
	var roster: Array = rig.results["host"]["roster"]
	assert_eq(roster.size(), ArenaConstants.PARTICIPANT_COUNT)
	for i in roster.size():
		assert_eq(roster[i]["seat_id"], i, "le roster doit être trié par seat_id, du siège 0 (hôte) au dernier")

func test_every_client_receives_the_same_roster_as_the_host() -> void:
	var rig: Dictionary = _build_rig(ArenaConstants.PARTICIPANT_COUNT - 1)
	var host_roster: Array = rig.results["host"]["roster"]
	for i in ArenaConstants.PARTICIPANT_COUNT - 1:
		assert_eq(rig.results["client_%d" % i]["roster"], host_roster,
			"le roster diffusé (START_MATCH) doit être identique pour tout le monde")

func test_a_duplicated_hello_is_ignored_once_a_seat_is_assigned() -> void:
	var rig: Dictionary = _build_rig(1)
	var host_handshake: ArenaNetHandshake = rig.host_handshake
	var seats_before: int = host_handshake._seat_by_peer.size()
	var next_seat_before: int = host_handshake._next_seat_id
	host_handshake._on_command_received(100, ArenaNetCommand.hello("Joueur 1 (dupliqué)", 12345))
	assert_eq(host_handshake._seat_by_peer.size(), seats_before, "un HELLO dupliqué ne doit pas ajouter de nouveau siège")
	assert_eq(host_handshake._next_seat_id, next_seat_before, "un HELLO dupliqué ne doit pas consommer un nouveau seat_id")
