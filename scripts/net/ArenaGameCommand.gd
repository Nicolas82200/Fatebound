extends RefCounted
class_name ArenaGameCommand

# Vocabulaire du protocole de PARTIE Arena (après le handshake d'ouverture —
# voir ArenaNetCommand), en modèle HÔTE AUTORITAIRE (voir README « Réseau &
# Visibilité », choix "simulation centralisée") :
# - un client envoie une REQUEST_* à l'hôte (jamais directement aux autres
#   clients) pour demander une action sur SON PROPRE siège (achat, vente,
#   reroll, positionnement...) ;
# - l'hôte, seul à exécuter réellement ArenaMatch (pool de cartes et RNG
#   partagés, validation des règles — voir ArenaHostAuthority), répond
#   ensuite par DEUX messages distincts (voir ArenaHostAuthority.apply,
#   qui produit les deux à chaque REQUEST_* traitée) :
#   - un BOARD_SYNC DIFFUSÉ À TOUS (plateau + PV du héros — état PUBLIC) ;
#   - un PRIVATE_STATE_SYNC envoyé UNIQUEMENT au siège concerné (main,
#     Incantations achetées, offre de boutique, or/XP/niveau/gel — état
#     PRIVÉ, voir ArenaPrivateStateSnapshot). Indispensable : sans ce second
#     message, un client n'aurait jamais aucun moyen de savoir ce qu'il a
#     reçu en boutique, combien d'or il lui reste, ou même si son reroll a
#     réussi — BOARD_SYNC ne reflète jamais cette information, privée par
#     design (voir README « Réseau & Visibilité »).
#
# Choix délibéré : resynchroniser tout l'état (public ET privé) plutôt que
# d'envoyer un delta d'action. Moins optimisé en bande passante (un plateau/
# une main Arena restent petits, négligeable), mais élimine tout risque de
# dérive entre clients à cause d'un delta mal appliqué — important pour un
# protocole qui n'a encore jamais tourné en conditions réseau réelles.
#
# Portée volontairement réduite pour cette étape de fondation : les
# Incantations achetées (LANCER/vendre un sort de la main — leur contenu est
# bien synchronisé via PRIVATE_STATE_SYNC, mais aucune REQUEST_* ne permet
# encore de les jouer) et le passage de phase (quorum "tout le monde prêt"
# pour lancer le combat) ne sont pas encore couverts — à traiter dans une
# phase ultérieure, une fois ce protocole branché sur une vraie partie.

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

# Hôte -> le siège concerné UNIQUEMENT (jamais diffusé) : voir
# ArenaPrivateStateSnapshot.
const PRIVATE_STATE_SYNC := "ARENA_PRIVATE_STATE_SYNC"  # {seat_id, gold, xp, level, shop_frozen, hand, spell_hand, shop_offer}

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

static func private_state_sync(seat_id: int, gold: int, xp: int, level: int, shop_frozen: bool,
		hand: Array, spell_hand: Array, shop_offer: Array) -> Dictionary:
	return {
		"type": PRIVATE_STATE_SYNC,
		"seat_id": seat_id,
		"gold": gold,
		"xp": xp,
		"level": level,
		"shop_frozen": shop_frozen,
		"hand": hand,
		"spell_hand": spell_hand,
		"shop_offer": shop_offer,
	}
