extends GutTest

func _build_pair() -> Dictionary:
	var hub := FakeArenaNetHub.new()

	var host_transport := FakeArenaNetTransport.new(hub, 1, true)
	var host_net := ArenaNetworkManager.new()
	autofree(host_net)
	host_net.is_host = true
	host_net.set_transport(host_transport)
	host_transport.host({})

	var client_transport := FakeArenaNetTransport.new(hub, 200, false)
	var client_net := ArenaNetworkManager.new()
	autofree(client_net)
	client_net.is_host = false
	client_net.set_transport(client_transport)
	client_transport.join({})

	return {"host_net": host_net, "client_net": client_net}

func test_broadcasts_a_board_sync_for_every_seat() -> void:
	var rig := _build_pair()
	var players: Array[ArenaPlayerState] = [ArenaPlayerState.new("Hôte"), ArenaPlayerState.new("Client")]
	var m := ArenaMatch.new(players, ArenaCardPool.new([]))
	m.find_by_seat(0).hero_hp = 12
	m.find_by_seat(1).hero_hp = 8

	var received: Array = []
	rig.client_net.command_received.connect(func(_peer_id: int, command: Dictionary) -> void: received.append(command))

	ArenaHostRoundSync.broadcast_after_combat(m, rig.host_net)

	var board_syncs: Array = received.filter(func(c): return ArenaGameCommand.type_of(c) == ArenaGameCommand.BOARD_SYNC)
	assert_eq(board_syncs.size(), 2, "un BOARD_SYNC doit être diffusé pour chaque siège, pas seulement un émetteur")
	var hp_by_seat: Dictionary = {}
	for command in board_syncs:
		hp_by_seat[command["seat_id"]] = command["hero_hp"]
	assert_eq(hp_by_seat[0], 12)
	assert_eq(hp_by_seat[1], 8)

func test_broadcasts_round_advanced_when_the_match_is_not_over() -> void:
	var rig := _build_pair()
	var players: Array[ArenaPlayerState] = [ArenaPlayerState.new("Hôte"), ArenaPlayerState.new("Client")]
	var m := ArenaMatch.new(players, ArenaCardPool.new([]))
	m.last_combat_summaries = ["Hôte vs Client : Hôte gagne, 3 dégâts"]

	var received: Array = []
	rig.client_net.command_received.connect(func(_peer_id: int, command: Dictionary) -> void: received.append(command))

	ArenaHostRoundSync.broadcast_after_combat(m, rig.host_net)

	var round_messages: Array = received.filter(func(c): return ArenaGameCommand.type_of(c) == ArenaGameCommand.ROUND_ADVANCED)
	assert_eq(round_messages.size(), 1)
	assert_eq(round_messages[0]["round_number"], m.round_number)
	assert_eq(round_messages[0]["combat_log"], m.last_combat_summaries)
	assert_true(received.filter(func(c): return ArenaGameCommand.type_of(c) == ArenaGameCommand.GAME_OVER).is_empty())

func test_broadcasts_game_over_when_only_one_player_remains() -> void:
	var rig := _build_pair()
	var players: Array[ArenaPlayerState] = [ArenaPlayerState.new("Hôte"), ArenaPlayerState.new("Client")]
	var m := ArenaMatch.new(players, ArenaCardPool.new([]))
	m.find_by_seat(1).hero_hp = 0
	m.find_by_seat(1).is_eliminated = true
	m.elimination_order = [m.find_by_seat(1)]

	var received: Array = []
	rig.client_net.command_received.connect(func(_peer_id: int, command: Dictionary) -> void: received.append(command))

	ArenaHostRoundSync.broadcast_after_combat(m, rig.host_net)

	var game_over_messages: Array = received.filter(func(c): return ArenaGameCommand.type_of(c) == ArenaGameCommand.GAME_OVER)
	assert_eq(game_over_messages.size(), 1)
	assert_eq(game_over_messages[0]["ranking"][0]["seat_id"], 0, "le survivant doit arriver premier au classement")
	assert_true(received.filter(func(c): return ArenaGameCommand.type_of(c) == ArenaGameCommand.ROUND_ADVANCED).is_empty())
