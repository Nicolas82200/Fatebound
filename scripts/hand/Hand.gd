extends Control

signal card_played(card_data)

@onready var container = $CardsContainer

const CARD_SCENE = preload("res://scenes/card/Card.tscn")
const SPACING := 140.0
const BASE_Y   := 850.0
const ARC_STRENGTH := 20.0
const MAX_ROTATION := 5.0

func set_hand(cards: Array[CardData]) -> void:
	for c in container.get_children():
		c.queue_free()
	await get_tree().process_frame
	for card_data in cards:
		var card: Card = CARD_SCENE.instantiate()
		container.add_child(card)
		card.set_data(card_data)
		card.card_clicked.connect(_on_card_clicked)
	_update_hand_layout()

func _on_card_clicked(card_data: CardData) -> void:
	card_played.emit(card_data)

func _update_hand_layout() -> void:
	var cards := container.get_children()
	var count := cards.size()
	if count == 0:
		return
	var center_x := get_viewport_rect().size.x * 0.5
	var start_x := center_x - (float(count - 1) * SPACING) / 2.0
	for i in range(count):
		var offset := float(i) - float(count - 1) / 2.0
		cards[i].position = Vector2(
			start_x + i * SPACING,
			BASE_Y + abs(offset) * ARC_STRENGTH
		)
		cards[i].rotation_degrees = offset * MAX_ROTATION
