extends Control

signal card_played(card_data)

@onready var container = $CardsContainer
var card_scene = preload("res://scenes/card/Card.tscn")

func set_hand(cards: Array[CardData]) -> void:
	for c in container.get_children():
		c.queue_free()
	for card_data in cards:
		var card = card_scene.instantiate()
		container.add_child(card)
		card.set_data(card_data)
		card.card_clicked.connect(_on_card_clicked)

func _on_card_clicked(card_data):
	card_played.emit(card_data)
