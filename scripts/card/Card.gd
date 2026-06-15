extends Control
class_name Card

signal card_clicked(card)

var data: CardData

const BORDER_TEXTURES := {
	"Undead": preload("res://assets/borders/undead-border-card.png"),
}

const RACE_NAMES := {
	"Undead": "Mort-vivant",
	"Human": "Humain",
	"Demon": "Démon",
	"Dwarf": "Bête",
	"Elf": "Elfe"
}

const RARITY_COLORS := {
	"Common":    Color("80808096"),
	"Rare":      Color("3498db96"),
	"Epic":      Color("9b59b696"),
	"Legendary": Color("f39c1296")
}

const RACE_COLORS := {
	"Undead": Color("#342e1aa5"),
	"Human":  Color("#5a4a3596"),
	"Elf":    Color("#2f5d5096"),
	"Dwarf":  Color("#5a3a2296"),
	"Demon":  Color("#5a1f1f96")
}

const BORDER_RACE_COLORS := {
	"Undead": Color("342e1ae1"),
	"Human":  Color("5a4a35e1"),
	"Elf":    Color("2f5d50e1"),
	"Dwarf":  Color("5a3a22e1"),
	"Demon":  Color("5a1f1fe1")
}

@onready var art: TextureRect    = $Art
@onready var name_label: Label   = $NameLabel
@onready var cost_label: Label   = $CostLabel
@onready var attack_label: Label = $AttackLabel
@onready var health_label: Label = $HealthLabel
@onready var desc_label: Label   = $DescLabel
@onready var race_label: Label   = $RaceLabel
@onready var border: TextureRect = $BorderFrame
@onready var text_background: Control = $TextBackground
@onready var rarity_panel: Control    = $RarityPanel
@onready var border_color: Panel      = $BorderFrameColor

# Styles mis en cache pour éviter de recréer des objets à chaque affichage
var _rarity_style := StyleBoxFlat.new()
var _race_bg_style := StyleBoxFlat.new()
var _race_border_style := StyleBoxFlat.new()

func _ready() -> void:
	_init_rarity_style()
	_init_race_border_style()


func set_data(new_data: CardData) -> void:
	data = new_data
	update_display()


func update_display() -> void:
	name_label.text   = data.card_name
	cost_label.text   = str(data.cost)
	attack_label.text = str(data.attack)
	health_label.text = str(data.health)
	desc_label.text   = data.description
	race_label.text   = RACE_NAMES.get(data.race, data.race)

	if data.texture:
		art.texture = data.texture

	if BORDER_TEXTURES.has(data.race):
		border.texture = BORDER_TEXTURES[data.race]
	else:
		push_warning("Pas de bordure définie pour la race: " + data.race)

	_apply_race_style()
	_apply_rarity_style()


func _init_rarity_style() -> void:
	_rarity_style.border_width_left   = 2
	_rarity_style.border_width_right  = 2
	_rarity_style.border_width_top    = 2
	_rarity_style.border_width_bottom = 2
	_rarity_style.corner_radius_top_left     = 12
	_rarity_style.corner_radius_top_right    = 12
	_rarity_style.corner_radius_bottom_left  = 12
	_rarity_style.corner_radius_bottom_right = 12
	rarity_panel.add_theme_stylebox_override("panel", _rarity_style)


func _init_race_border_style() -> void:
	_race_border_style.bg_color           = Color.TRANSPARENT
	_race_border_style.border_width_left  = 8
	_race_border_style.border_width_right = 8
	_race_border_style.border_width_top   = 15
	_race_border_style.border_width_bottom = 0
	_race_border_style.border_blend       = true
	border_color.add_theme_stylebox_override("panel", _race_border_style)
	text_background.add_theme_stylebox_override("panel", _race_bg_style)


func _apply_rarity_style() -> void:
	_rarity_style.border_color = RARITY_COLORS.get(data.rarity, Color.WHITE)
	rarity_panel.queue_redraw()


func _apply_race_style() -> void:
	_race_bg_style.bg_color = RACE_COLORS.get(data.race, Color.WHITE)
	_race_border_style.border_color = BORDER_RACE_COLORS.get(data.race, Color.WHITE)
	text_background.queue_redraw()
	border_color.queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton \
		and event.pressed \
		and event.button_index == MOUSE_BUTTON_LEFT:
		card_clicked.emit(data)
