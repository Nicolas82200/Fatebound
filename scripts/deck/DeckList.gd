extends Control
class_name DeckList

@onready var decks_container: VBoxContainer = %DecksContainer
@onready var create_button: Button          = %CreateButton
@onready var back_button: Button            = %BackButton

const DECK_BUILDER_SCENE := "res://scenes/deck/DeckBuilder.tscn"

func _ready() -> void:
	create_button.pressed.connect(_on_create_deck)
	back_button.pressed.connect(_on_back)
	_refresh()

func _refresh() -> void:
	for child in decks_container.get_children():
		child.queue_free()
	for i in range(DeckManager.decks.size()):
		var deck: DeckData = DeckManager.decks[i]
		var row := _make_deck_row(deck, i)
		decks_container.add_child(row)

func _make_deck_row(deck: DeckData, index: int) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.custom_minimum_size = Vector2(0, 48)

	var card_bg := StyleBoxFlat.new()
	card_bg.bg_color = Color(0.16, 0.13, 0.10, 0.9)
	card_bg.corner_radius_top_left = 8
	card_bg.corner_radius_top_right = 8
	card_bg.corner_radius_bottom_left = 8
	card_bg.corner_radius_bottom_right = 8
	card_bg.border_color = Color(0.54, 0.41, 0.16, 0.75)
	card_bg.border_width_left = 1
	card_bg.border_width_right = 1
	card_bg.border_width_top = 1
	card_bg.border_width_bottom = 1
	card_bg.content_margin_left = 10
	card_bg.content_margin_right = 10
	card_bg.content_margin_top = 6
	card_bg.content_margin_bottom = 6
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", card_bg)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.custom_minimum_size = Vector2(0, 44)
	row.add_child(panel)

	var inner := HBoxContainer.new()
	inner.add_theme_constant_override("separation", 10)
	panel.add_child(inner)

	var active_indicator := Label.new()
	active_indicator.text = "★" if index == DeckManager.active_deck_index else "☆"
	active_indicator.custom_minimum_size = Vector2(24, 0)
	active_indicator.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	active_indicator.add_theme_color_override("font_color", Color(0.95, 0.82, 0.35, 1))
	inner.add_child(active_indicator)

	var name_lbl := Label.new()
	name_lbl.text = "%s  (%d/40)" % [deck.name, deck.size()]
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lbl.add_theme_color_override("font_color", Color(0.95, 0.88, 0.72, 1))
	inner.add_child(name_lbl)

	var select_btn := Button.new()
	select_btn.text = "Choisir"
	select_btn.pressed.connect(_on_select_deck.bind(index))
	inner.add_child(select_btn)

	var edit_btn := Button.new()
	edit_btn.text = "Editer"
	edit_btn.pressed.connect(_on_edit_deck.bind(index))
	inner.add_child(edit_btn)

	var del_btn := Button.new()
	del_btn.text = "X"
	del_btn.pressed.connect(_on_delete_deck.bind(index))
	inner.add_child(del_btn)

	return row

func _on_select_deck(index: int) -> void:
	DeckManager.set_active_deck(index)
	_refresh()

func _on_edit_deck(index: int) -> void:
	var scene := load(DECK_BUILDER_SCENE) as PackedScene
	if scene == null:
		return
	var builder = scene.instantiate()
	get_tree().current_scene.add_child(builder)
	builder.load_deck(DeckManager.decks[index])
	hide()
	builder.tree_exited.connect(func():
		show()
		_refresh()
	)

func _on_create_deck() -> void:
	var deck := DeckManager.create_deck()
	var scene := load(DECK_BUILDER_SCENE) as PackedScene
	if scene == null:
		return
	var builder = scene.instantiate()
	get_tree().current_scene.add_child(builder)
	builder.load_deck(deck)
	hide()
	builder.tree_exited.connect(func():
		show()
		_refresh()
	)

func _on_delete_deck(index: int) -> void:
	DeckManager.delete_deck(index)
	_refresh()

func _on_back() -> void:
	hide()
