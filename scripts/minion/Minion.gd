extends RefCounted
class_name Minion

var owner_is_player: bool
var card_data: CardData
var base_attack: int
var base_max_health: int
var aura_attack_bonus: int = 0
var aura_health_bonus: int = 0
var damage_taken: int = 0
var attacks_remaining: int = 0
var keywords: Array[int] = []
var human_keywords: Array[int] = []
var board_row: String = "Front"

var frozen_turns: int = 0
var infected: bool = false
var silenced: bool = false
var sacrificed: bool = false

var attack: int:
	get: return max(base_attack + aura_attack_bonus, 0)

var max_health: int:
	get: return max(base_max_health + aura_health_bonus, 1)
	set(value):
		base_max_health = value

var health: int:
	get: return max(max_health - damage_taken, 0)
	set(value):
		damage_taken = max(max_health - value, 0)

func _init(data: CardData, is_player: bool = true, row: String = "Front"):
	owner_is_player = is_player
	card_data = data
	board_row = row
	base_attack = data.attack
	base_max_health = data.health
	keywords = data.get_keyword_values()
	human_keywords = data.get_human_keyword_values()
	if has_keyword(Keyword.Type.CHARGE):
		attacks_remaining = 1
	else:
		attacks_remaining = 0

func can_attack() -> bool:
	return attacks_remaining > 0 and frozen_turns <= 0 and not is_dead()

func refresh_attacks() -> void:
	frozen_turns = max(frozen_turns - 1, 0)
	if frozen_turns > 0:
		attacks_remaining = 0
		return
	if has_keyword(Keyword.Type.FURY):
		attacks_remaining = 2
	else:
		attacks_remaining = 1

func consume_attack() -> void:
	attacks_remaining = max(attacks_remaining - 1, 0)

## Retourne les dégâts effectivement infligés (0 si absorbés par Égide).
func take_damage(amount: int) -> int:
	if has_keyword(Keyword.Type.AEGIS):
		remove_keyword(Keyword.Type.AEGIS)
		return 0
	var before := health
	damage_taken += amount
	return before - health

func heal(amount: int) -> void:
	damage_taken = max(damage_taken - amount, 0)

func is_dead() -> bool:
	return health <= 0

# ─── Keywords ─────────────────────────────────────────────────────────────────

func has_keyword(keyword: int) -> bool:
	return keyword in keywords

func add_keyword(keyword: int) -> void:
	if keyword not in keywords:
		keywords.append(keyword)

func remove_keyword(keyword: int) -> void:
	keywords.erase(keyword)

func has_human_keyword(keyword: int) -> bool:
	return keyword in human_keywords

func get_keywords_text() -> String:
	var names: Array[String] = []
	for keyword in keywords:
		names.append(Keyword.get_name(keyword))
	for keyword in human_keywords:
		names.append(KeywordHuman.get_name(keyword))
	return ", ".join(names)
