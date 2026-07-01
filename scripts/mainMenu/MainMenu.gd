# MainMenu.gd
extends Control

const BATTLE_SCENE := "res://scenes/battle/Battle.tscn"

@onready var play_button:     Button = $CenterContainer/VBoxContainer/PlayButton
@onready var future_button:   Button = $CenterContainer/VBoxContainer/FutureButton
@onready var settings_button: Button = $CenterContainer/VBoxContainer/SettingsButton
@onready var credits_button:  Button = $CenterContainer/VBoxContainer/CreditsButton
@onready var quit_button:     Button = $CenterContainer/VBoxContainer/QuitButton
@onready var credits_panel:   Panel  = $CreditsPanel
@onready var close_credits:   Button = $CreditsPanel/CloseCreditsButton
@onready var decks_button:    Button = $CenterContainer/VBoxContainer/DecksButton
@onready var deck_list:       Control = $DeckList
# [FIX] Non typé — typer en AudioSettingsMenu cassait _ready() si le type ne matchait pas
@onready var settings_menu = $SettingsMenu

func _ready() -> void:
	AudioManager.play_battle_music()
	_style_all_buttons()
	play_button.pressed.connect(_on_play)
	future_button.pressed.connect(_on_future)
	credits_button.pressed.connect(_on_credits)
	quit_button.pressed.connect(_on_quit)
	decks_button.pressed.connect(_on_decks_button_pressed)
	close_credits.pressed.connect(func(): credits_panel.hide())
	# [FIX] Null-check restauré — settings_menu peut légitimement être absent
	if settings_menu:
		settings_button.pressed.connect(settings_menu.open)
	else:
		push_error("SettingsMenu introuvable !")
	credits_panel.hide()

func _on_decks_button_pressed() -> void:
	if not CardLibrary.is_loaded:
		push_warning("CardLibrary pas encore chargé !")
		return
	deck_list.visible = true
	if deck_list.has_method("_refresh"):
		deck_list._refresh()

func _on_play() -> void:
	get_tree().change_scene_to_file(BATTLE_SCENE)

func _on_future() -> void:
	pass

func _on_credits() -> void:
	credits_panel.visible = not credits_panel.visible

func _on_quit() -> void:
	get_tree().quit()

# ─── Style ────────────────────────────────────────────────────────────────────

# [NOTE] _style_button est dupliqué dans DeckBuilder.gd
# À terme : extraire dans un autoload UITheme ou un Theme Godot global

func _style_all_buttons() -> void:
	for btn in $CenterContainer/VBoxContainer.get_children():
		if btn is Button:
			_style_button(btn)

func _style_button(btn: Button) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color                   = Color("1e1a2fdd")
	normal.border_width_left          = 2
	normal.border_width_right         = 2
	normal.border_width_top           = 2
	normal.border_width_bottom        = 2
	normal.border_color               = Color("8b6914")
	normal.corner_radius_top_left     = 10
	normal.corner_radius_top_right    = 10
	normal.corner_radius_bottom_left  = 10
	normal.corner_radius_bottom_right = 10
	normal.shadow_size                = 6
	normal.shadow_color               = Color(0, 0, 0, 0.25)
	btn.add_theme_stylebox_override("normal", normal)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color     = Color("32415eee")
	hover.border_color = Color("c9a227")
	btn.add_theme_stylebox_override("hover", hover)
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color     = Color("0f1729ee")
	pressed.border_color = Color("f0c040")
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_color_override("font_color",       Color("e8d5a3"))
	btn.add_theme_color_override("font_hover_color", Color("fff5d6"))
	btn.add_theme_font_size_override("font_size", 22)
