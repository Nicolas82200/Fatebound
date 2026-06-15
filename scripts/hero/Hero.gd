class_name Hero
extends RefCounted

var health: int
var max_health: int

func _init(start_health := 30):
	max_health = start_health
	health = start_health

func take_damage(amount: int) -> void:
	health -= amount

func heal(amount: int) -> void:
	health += amount

func is_dead() -> bool:
	return health <= 0
