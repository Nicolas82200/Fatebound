extends RefCounted
class_name Minion

var card_data: CardData
var attack: int
var health: int
var max_health: int
var can_attack: bool = false
var has_protection: bool = false

func _init(data: CardData):
	card_data = data
	attack = data.attack
	health = data.health
	max_health = data.health
	can_attack = data.has_charge
	has_protection = data.has_protection

func take_damage(amount: int):
	if has_protection:
		has_protection=false
		
	health = max(health - amount, 0)

func heal(amount: int):
	health = min(health + amount, max_health)

func is_dead() -> bool:
	return health <= 0
