extends RefCounted
class_name ArenaNetCommand

# Vocabulaire des commandes échangées pendant le handshake réseau Arena (voir
# ArenaNetHandshake) — même esprit que NetCommand.gd (1v1), gardé séparé (voir
# ArenaNetTransport) : le protocole de jeu proprement dit (achats/positionnement/
# combat synchronisés à 8 joueurs) n'existe pas encore, seul l'échange
# d'ouverture (qui est qui, graine RNG partagée, tous prêts) est couvert ici.

const HELLO := "ARENA_HELLO"               # client -> hôte : nom d'affichage + contribution de graine
const SEAT_ASSIGN := "ARENA_SEAT_ASSIGN"   # hôte -> client : seat_id attribué
const START_MATCH := "ARENA_START_MATCH"   # hôte -> tous : graine finale + liste des sièges

static func hello(display_name: String, seed_contribution: int) -> Dictionary:
	return {"type": HELLO, "display_name": display_name, "seed": seed_contribution}

static func seat_assign(seat_id: int) -> Dictionary:
	return {"type": SEAT_ASSIGN, "seat_id": seat_id}

# `roster` : Array de {"seat_id": int, "display_name": String}, trié par
# seat_id (siège 0 = hôte).
static func start_match(seed: int, roster: Array) -> Dictionary:
	return {"type": START_MATCH, "seed": seed, "roster": roster}

static func type_of(command: Dictionary) -> String:
	return str(command.get("type", ""))
