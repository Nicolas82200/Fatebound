extends RefCounted
class_name Minion

var owner_is_player: bool
var card_data: CardData

var attack: int
var health: int
var max_health: int

var attacks_remaining: int = 0

var has_protection: bool = false
var has_lifesteal: bool = false
var has_fury: bool = false


func _init(
	data: CardData,
	is_player: bool = true
):
	owner_is_player = is_player
	card_data = data
	attack = data.attack
	health = data.health
	max_health = data.health
	has_lifesteal = data.has_lifesteal
	has_protection = data.has_protection
	has_fury = data.has_fury
	if data.has_charge:
		attacks_remaining = 1

func can_attack() -> bool:
	return attacks_remaining > 0

func refresh_attacks():
	if has_fury:
		attacks_remaining = 2
	else:
		attacks_remaining = 1

func consume_attack():
	attacks_remaining = max(attacks_remaining - 1, 0)

func take_damage(amount: int):
	if has_protection:
		has_protection = false
		return
	health = max(health - amount, 0)

func heal(amount: int):
	health = min(health + amount, max_health)

func is_dead() -> bool:
	return health <= 0
