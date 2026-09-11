extends RefCounted
class_name ArenaGameCommand

# Vocabulaire du protocole de PARTIE Arena (après le handshake d'ouverture —
# voir ArenaNetCommand), en modèle HÔTE AUTORITAIRE (voir README « Réseau &
# Visibilité », choix "simulation centralisée") :
# - un client envoie une REQUEST_* à l'hôte (jamais directement aux autres
#   clients) pour demander une action sur SON PROPRE siège (achat, vente,
#   reroll, positionnement...) ;
# - l'hôte, seul à exécuter réellement ArenaMatch (pool de cartes et RNG
#   partagés, validation des règles — voir ArenaHostAuthority), diffuse
#   ensuite un BOARD_SYNC à tous les clients pour refléter le nouvel état
#   PUBLIC du siège concerné (plateau + PV du héros) — jamais sa main ni sa
#   boutique, strictement privées (voir ArenaRemoteBoardMirror).
#
# Choix délibéré : resynchroniser tout l'état public du siège plutôt que
# d'envoyer un delta d'action. Moins optimisé en bande passante (un plateau
# Arena reste petit, 20 serviteurs max, donc négligeable), mais élimine tout
# risque de dérive entre clients à cause d'un delta mal appliqué — important
# pour un protocole qui n'a encore jamais tourné en conditions réseau réelles.
#
# Portée volontairement réduite pour cette étape de fondation : les
# Incantations achetées (lancer/vendre un sort de la main) et le passage de
# phase (quorum "tout le monde prêt" pour lancer le combat) ne sont pas
# encore couverts — à traiter dans une phase ultérieure, une fois ce
# protocole branché sur une vraie partie.

const REQUEST_BUY := "ARENA_REQUEST_BUY"                      # {shop_index}
const REQUEST_SELL_FROM_HAND := "ARENA_REQUEST_SELL_HAND"     # {hand_index}
const REQUEST_SELL_FROM_BOARD := "ARENA_REQUEST_SELL_BOARD"   # {is_front, board_index}
const REQUEST_REROLL := "ARENA_REQUEST_REROLL"                # {}
const REQUEST_BUY_XP := "ARENA_REQUEST_BUY_XP"                # {}
const REQUEST_TOGGLE_FREEZE := "ARENA_REQUEST_TOGGLE_FREEZE"  # {}
const REQUEST_PLACE := "ARENA_REQUEST_PLACE"                  # {hand_index, is_front, index}
const REQUEST_MOVE := "ARENA_REQUEST_MOVE"                    # {is_front_from, board_index_from, is_front_to, index_to}

# Hôte -> tous : nouvel état public d'un siège (voir ArenaBoardSnapshot).
const BOARD_SYNC := "ARENA_BOARD_SYNC"  # {seat_id, hero_hp, front, back}

static func type_of(command: Dictionary) -> String:
	return str(command.get("type", ""))

static func request_buy(shop_index: int) -> Dictionary:
	return {"type": REQUEST_BUY, "shop_index": shop_index}

static func request_sell_from_hand(hand_index: int) -> Dictionary:
	return {"type": REQUEST_SELL_FROM_HAND, "hand_index": hand_index}

static func request_sell_from_board(is_front: bool, board_index: int) -> Dictionary:
	return {"type": REQUEST_SELL_FROM_BOARD, "is_front": is_front, "board_index": board_index}

static func request_reroll() -> Dictionary:
	return {"type": REQUEST_REROLL}

static func request_buy_xp() -> Dictionary:
	return {"type": REQUEST_BUY_XP}

static func request_toggle_freeze() -> Dictionary:
	return {"type": REQUEST_TOGGLE_FREEZE}

static func request_place(hand_index: int, is_front: bool, index: int) -> Dictionary:
	return {"type": REQUEST_PLACE, "hand_index": hand_index, "is_front": is_front, "index": index}

static func request_move(is_front_from: bool, board_index_from: int, is_front_to: bool, index_to: int) -> Dictionary:
	return {
		"type": REQUEST_MOVE,
		"is_front_from": is_front_from,
		"board_index_from": board_index_from,
		"is_front_to": is_front_to,
		"index_to": index_to,
	}

static func board_sync(seat_id: int, hero_hp: int, front: Array, back: Array) -> Dictionary:
	return {"type": BOARD_SYNC, "seat_id": seat_id, "hero_hp": hero_hp, "front": front, "back": back}
