extends Control

const EffectManagerData  = preload("res://scripts/EffectManager/EffectManager.gd")
const EnchantmentSystemScript = preload("res://scripts/systems/EnchantmentSystem.gd")
const BOARD_MINION_SCENE = preload("res://scenes/minion/BoardMinion.tscn")
const CARD_BACK          = preload("res://assets/card_back/card-back.png")
const MAX_STACK_VISUAL   := 8
const ROW_FRONT          := "Front"
const ROW_BACK           := "Back"
const MAX_MINIONS_PER_ROW := 10
const BOARD_MINION_SIZE := Vector2(100, 150)
const DROP_HIGHLIGHT_COLOR := Color(1.0, 0.45, 0.05, 0.28)
const DROP_HIGHLIGHT_BORDER_COLOR := Color(1.0, 0.58, 0.12, 0.9)

@onready var hand: Hand                  = $Hand
@onready var mana_label: Label           = $ManaLabel
@onready var end_turn_button: Button     = $EndTurnButton
@onready var enemy_container: Control    = get_node_or_null("Board/EnemyMinionsContainer") as Control
@onready var player_container: Control   = get_node_or_null("Board/PlayerMinionsContainer") as Control
@onready var player_front_container: Control = get_node_or_null("Board/PlayerFrontLine") as Control
@onready var player_back_container: Control  = get_node_or_null("Board/PlayerBackLine") as Control
@onready var enemy_front_container: Control  = get_node_or_null("Board/EnemyFrontLine") as Control
@onready var enemy_back_container: Control   = get_node_or_null("Board/EnemyBackLine") as Control
@onready var player_graveyard_btn: Button = $PlayerGraveyardButton
@onready var enemy_graveyard_btn: Button  = $EnemyGraveyardButton
@onready var player_graveyard_preview: Card = $PlayerGraveyardButton/CardPreview
@onready var enemy_graveyard_preview: Card  = $EnemyGraveyardButton/CardPreview
@onready var graveyard_view: GraveyardView = $GraveyardView
@onready var deck_button           = $DeckButton
@onready var deck_count_label      = $DeckButton/CountLabel
@onready var turn_choice_panel: TurnChoicePanel = $TurnChoicePanel
@onready var player_enchantment_zone: VBoxContainer = get_node_or_null("PlayerEnchantmentZone") as VBoxContainer
@onready var enemy_enchantment_zone: VBoxContainer  = get_node_or_null("EnemyEnchantmentZone") as VBoxContainer

var player_minions: Array[Minion] = []
var enemy_minions: Array[Minion]  = []

var player_graveyard: Graveyard = Graveyard.new()
var enemy_graveyard: Graveyard  = Graveyard.new()

var pending_card: CardData            = null
var pending_row: String = ROW_FRONT
var pending_insert_index: int = -1
var waiting_for_target: bool = false

var deck: Array[CardData]       = []
var hand_cards: Array[CardData] = []

var mana      := 3
var max_mana  := 3
var player_hero: Hero
var enemy_hero: Hero
var game_over: bool = false

# ─── Systèmes ───────────────────────────────────────────────────────────────

var effect_manager        := EffectManagerData.new()
var hero_system            := HeroSystem.new()
var board_visual_system    := BoardVisualSystem.new()
var combat_system          := CombatSystem.new()
var death_system           := DeathSystem.new()
var board_system           := BoardSystem.new()
var aura_system            := AuraSystem.new()
var animation_system       := AnimationSystem.new()
var selection_system       := SelectionSystem.new()
var targeting_system       := TargetingSystem.new()
var trigger_system         := TriggerSystem.new()
var turn_system            := TurnSystem.new()
var card_system             := CardSystem.new()
var deck_system             := DeckSystem.new()
var enchantment_system      := EnchantmentSystemScript.new()
var card_popup_system      := CardPopupSystem.new()


func _ready() -> void:
	_init_systems()
	set_process(false)

	deck_system.load_deck()
	var enemy_card: CardData = load("res://resources/cards/undead/infected-berserker.tres") as CardData
	enemy_minions.append(Minion.new(enemy_card, false, ROW_FRONT))
	player_hero = Hero.new(30)
	enemy_hero  = Hero.new(30)

	hand.card_played.connect(card_system.handle_card_played)
	end_turn_button.pressed.connect(_on_end_turn_pressed)
	$EnemyHeroPanel.hero_clicked.connect(selection_system.on_enemy_hero_clicked)
	$EnemyHeroPanel.hero_clicked.connect(targeting_system.on_enemy_hero_clicked)
	turn_choice_panel.draw_selected.connect(turn_system.choose_draw)
	turn_choice_panel.mana_selected.connect(turn_system.choose_mana)

	player_graveyard_preview.visible = false
	enemy_graveyard_preview.visible  = false
	player_graveyard_btn.visible     = false
	enemy_graveyard_btn.visible      = false
	player_graveyard.graveyard_changed.connect(
		func(): _update_graveyard_btn(
			player_graveyard,
			player_graveyard_preview,
			$PlayerGraveyardButton/CountLabel
		)
	)
	enemy_graveyard.graveyard_changed.connect(
		func(): _update_graveyard_btn(
			enemy_graveyard,
			enemy_graveyard_preview,
			$EnemyGraveyardButton/CountLabel
		)
	)
	var card_native_size := Vector2(200, 300)
	var btn_size         := Vector2(120, 180)
	var card_scale       := btn_size / card_native_size
	player_graveyard_preview.scale = card_scale
	enemy_graveyard_preview.scale  = card_scale
	player_graveyard_btn.pressed.connect(func(): graveyard_view.open(player_graveyard))
	enemy_graveyard_btn.pressed.connect(func():  graveyard_view.open(enemy_graveyard))
	if player_graveyard_preview.has_method("set_non_interactive"):
		player_graveyard_preview.set_non_interactive()
	if enemy_graveyard_preview.has_method("set_non_interactive"):
		enemy_graveyard_preview.set_non_interactive()
	hand.drag_started.connect(_on_hand_drag_started)
	hand.drag_ended.connect(_on_hand_drag_ended)
	update_mana_ui()
	hero_system.update_ui()
	deck_system.update_deck_ui()
	board_visual_system.refresh_board()
	deck_system.start_game()

func _init_systems() -> void:
	add_child(hero_system)
	add_child(combat_system)
	add_child(animation_system)
	add_child(selection_system)
	add_child(targeting_system)
	add_child(trigger_system)
	add_child(turn_system)
	add_child(card_system)
	add_child(deck_system)
	add_child(enchantment_system)

	hero_system.init(self)
	board_visual_system.init(self)
	combat_system.init(self)
	death_system.init(self)
	board_system.init(self)
	aura_system.init(self)
	animation_system.init(self)
	selection_system.init(self)
	targeting_system.init(self)
	trigger_system.init(self)
	turn_system.init(self)
	card_system.init(self)
	deck_system.init(self)
	enchantment_system.init(self)
	card_popup_system.init(self)

func _process(_delta: float) -> void:
	if targeting_system.is_targeting():
		targeting_system.update_arrow()

# ─── Mana ─────────────────────────────────────────────────────────────────────

func update_mana_ui() -> void:
	mana_label.text = "%d/%d" % [mana, max_mana]

func _pay_mana(cost: int) -> void:
	mana -= cost
	update_mana_ui()

# ─── Carte jouée / ciblage ────────────────────────────────────────────────────

func summon_minion(card_data: CardData, is_player: bool = true, row: String = ROW_FRONT, insert_index: int = -1) -> void:
	await board_system.summon_minion(card_data, is_player, row, insert_index)

func reset_targeting_state() -> void:
	pending_card          = null
	pending_row           = ROW_FRONT
	pending_insert_index  = -1
	waiting_for_target    = false

# ─── Serviteurs ───────────────────────────────────────────────────────────────

func get_owner_minions(minion: Minion) -> Array[Minion]:
	if minion == null:
		return player_minions
	return player_minions if minion.owner_is_player else enemy_minions

func get_enemy_minions(minion: Minion) -> Array[Minion]:
	if minion == null:
		return enemy_minions
	return enemy_minions if minion.owner_is_player else player_minions

func get_row_minions(is_player: bool, row: String) -> Array[Minion]:
	var source: Array[Minion] = player_minions if is_player else enemy_minions
	return source.filter(func(m): return m.board_row == row)

func get_front_minions(is_player: bool) -> Array[Minion]:
	return get_row_minions(is_player, ROW_FRONT)

func get_back_minions(is_player: bool) -> Array[Minion]:
	return get_row_minions(is_player, ROW_BACK)

func can_summon_to_row(is_player: bool, row: String) -> bool:
	return get_row_minions(is_player, row).size() < MAX_MINIONS_PER_ROW

func get_allowed_rows_for_card(card_data: CardData) -> Array[String]:
	if card_data == null or card_data.card_type != "Minion":
		return [ROW_FRONT, ROW_BACK]
	match card_data.board_position:
		ROW_FRONT:
			return [ROW_FRONT]
		ROW_BACK:
			return [ROW_BACK]
		_:
			return [ROW_FRONT, ROW_BACK]

func can_play_card_on_row(card_data: CardData, row: String) -> bool:
	return row in get_allowed_rows_for_card(card_data)

func has_enemy_taunt_for(attacker: Minion) -> bool:
	for minion in get_attackable_enemy_minions(attacker):
		if minion.has_keyword(Keyword.Type.TAUNT):
			return true
	return false

func get_attackable_enemy_minions(attacker: Minion) -> Array[Minion]:
	if attacker and attacker.has_keyword(Keyword.Type.BLACK_WINGS):
		return enemy_minions
	var front: Array[Minion] = get_front_minions(false)
	if not front.is_empty():
		return front
	return enemy_minions

# ─── Combat — règles ──────────────────────────────────────────────────────────

func _can_attack_minion_target(attacker: Minion, target: Minion) -> bool:
	if attacker == null or not attacker.can_attack():
		return false
	if target not in get_attackable_enemy_minions(attacker):
		return false
	if has_enemy_taunt_for(attacker) and not target.has_keyword(Keyword.Type.TAUNT):
		return false
	return true

func _can_attack_hero(attacker: Minion) -> bool:
	if attacker == null or not attacker.can_attack():
		return false
	if has_enemy_taunt_for(attacker):
		return false
	if not attacker.has_keyword(Keyword.Type.BLACK_WINGS) and not get_front_minions(false).is_empty():
		return false
	return true

func _update_graveyard_btn(graveyard: Graveyard, preview: Card, label: Label) -> void:
	var last: CardData = graveyard.last_card_data()
	if last == null:
		preview.visible = false
		label.text = "0"
		return
	preview.visible = true
	preview.get_parent().visible = true
	preview.set_data(last)
	label.text = str(graveyard.size())

# ─── Tours ────────────────────────────────────────────────────────────────────

func _on_end_turn_pressed() -> void:
	if game_over:
		return
	turn_system.end_turn()

# ─── Fin de partie ────────────────────────────────────────────────────────────

func check_game_end() -> void:
	if enemy_hero.is_dead() or player_hero.is_dead():
		game_over = true

# ─── Input ────────────────────────────────────────────────────────────────────

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().quit()

func _find_zone_at(mouse: Vector2, group: String) -> Control:
	for zone in get_tree().get_nodes_in_group(group):
		if zone is Control and zone.get_global_rect().has_point(mouse):
			return zone
	return null

# ─── Drag & drop de la main vers le board ─────────────────────────────────────

var _drop_highlights: Dictionary = {}
var _drop_placeholder: Control = null
var _drop_placeholder_row: String = ""
var _drop_placeholder_index: int = -1
var _drag_board_preview: BoardMinion = null
var _drag_preview_card_data: CardData = null
var _drag_preview_row: String = ""
var _last_placeholder_index: int = -1
var _last_placeholder_row: String = ""

func get_player_drop_row_at(mouse: Vector2, card_data: CardData = null) -> String:
	var allowed_rows: Array[String] = get_allowed_rows_for_card(card_data)
	if player_front_container is Control and player_front_container.get_global_rect().has_point(mouse):
		return ROW_FRONT if ROW_FRONT in allowed_rows else ""
	if player_back_container is Control and player_back_container.get_global_rect().has_point(mouse):
		return ROW_BACK if ROW_BACK in allowed_rows else ""
	return ""

func get_player_drop_index_at(mouse: Vector2, row: String) -> int:
	return _get_stable_player_drop_index_at(mouse, row)

func _get_raw_player_drop_index_at(mouse: Vector2, row: String) -> int:
	var container: Control = _get_player_row_container(row)
	if container == null:
		return -1
	var index: int = 0
	for child in container.get_children():
		if child is BoardMinion:
			var rect: Rect2 = child.get_global_rect()
			if mouse.x < rect.position.x + rect.size.x * 0.5:
				return index
			index += 1
	return index

func update_player_drop_highlight(card_data: CardData, mouse: Vector2, display_show: bool) -> bool:
	_ensure_drop_highlights()
	var allowed_rows: Array[String] = get_allowed_rows_for_card(card_data)
	for row in [ROW_FRONT, ROW_BACK]:
		var panel: Panel = _drop_highlights.get(row) as Panel
		var row_container: Control = _get_player_row_container(row)
		if panel == null or row_container == null:
			continue
		var can_show: bool = display_show and row in allowed_rows and can_summon_to_row(true, row)
		panel.visible = can_show
		if can_show:
			_fit_drop_highlight_to(row_container, panel)
	var drop_row: String = get_player_drop_row_at(mouse, card_data)
	if display_show and not drop_row.is_empty() and can_summon_to_row(true, drop_row):
		var insert_index: int = _get_stable_player_drop_index_at(mouse, drop_row)
		_update_drop_placeholder(drop_row, insert_index)
		_update_drag_board_preview(card_data, drop_row, mouse)
		return true
	_clear_drop_placeholder()
	_clear_drag_board_preview()
	return false

func clear_player_drop_highlight() -> void:
	for panel in _drop_highlights.values():
		var control: Control = panel as Control
		if control != null:
			control.visible = false
	_clear_drop_placeholder()
	_clear_drag_board_preview()

func _ensure_drop_highlights() -> void:
	if not _drop_highlights.is_empty():
		return
	var board: Control = get_node_or_null("Board") as Control
	if board == null:
		return
	for row in [ROW_FRONT, ROW_BACK]:
		var panel: Panel = Panel.new()
		panel.name = "Player%sDropHighlight" % row
		panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.visible = false
		var style: StyleBoxFlat = StyleBoxFlat.new()
		style.bg_color = DROP_HIGHLIGHT_COLOR
		style.border_color = DROP_HIGHLIGHT_BORDER_COLOR
		style.border_width_left = 3
		style.border_width_right = 3
		style.border_width_top = 3
		style.border_width_bottom = 3
		style.corner_radius_top_left = 8
		style.corner_radius_top_right = 8
		style.corner_radius_bottom_left = 8
		style.corner_radius_bottom_right = 8
		panel.add_theme_stylebox_override("panel", style)
		board.add_child(panel)
		_drop_highlights[row] = panel

func _fit_drop_highlight_to(row_container: Control, panel: Control) -> void:
	var board: Control = get_node_or_null("Board") as Control
	if board == null:
		return
	var rect: Rect2 = row_container.get_global_rect()
	var board_origin: Vector2 = board.global_position
	panel.position = rect.position - board_origin
	panel.size = rect.size
	board.move_child(panel, 0)

func _get_player_row_container(row: String) -> Control:
	if row == ROW_BACK:
		return player_back_container
	return player_front_container

func _update_drop_placeholder(row: String, insert_index: int) -> void:
	var container: Control = _get_player_row_container(row)
	if container == null:
		return
	if _drop_placeholder == null:
		_drop_placeholder = _create_drop_placeholder()
	if _drop_placeholder.get_parent() != container:
		if _drop_placeholder.get_parent() != null:
			_drop_placeholder.get_parent().remove_child(_drop_placeholder)
		container.add_child(_drop_placeholder)
	_drop_placeholder.visible = true
	_drop_placeholder.custom_minimum_size = BOARD_MINION_SIZE
	_drop_placeholder_row = row
	_drop_placeholder_index = insert_index
	# Only rearrange if the index actually changed to prevent constant layout recalculation
	if _last_placeholder_index != insert_index or _last_placeholder_row != row:
		var child_index: int = _get_row_child_index_for_insert(container, insert_index)
		container.move_child(_drop_placeholder, child_index)
		_last_placeholder_index = insert_index
		_last_placeholder_row = row

func _create_drop_placeholder() -> Panel:
	var placeholder: Panel = Panel.new()
	placeholder.name = "DropPlaceholder"
	placeholder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	placeholder.custom_minimum_size = BOARD_MINION_SIZE
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(1.0, 0.45, 0.05, 0.16)
	style.border_color = DROP_HIGHLIGHT_BORDER_COLOR
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	placeholder.add_theme_stylebox_override("panel", style)
	return placeholder

func _get_row_child_index_for_insert(container: Control, insert_index: int) -> int:
	var seen_minions: int = 0
	var fallback_index: int = container.get_child_count()
	for i in range(container.get_child_count()):
		var child: Node = container.get_child(i)
		if child == _drop_placeholder:
			continue
		if child is BoardMinion:
			if seen_minions == insert_index:
				return i
			seen_minions += 1
		fallback_index = i + 1
	return fallback_index

func _get_stable_player_drop_index_at(mouse: Vector2, row: String) -> int:
	if _drop_placeholder != null and _drop_placeholder.visible and _drop_placeholder_row == row:
		var placeholder_rect: Rect2 = _drop_placeholder.get_global_rect().grow(35.0)
		if placeholder_rect.has_point(mouse):
			return _drop_placeholder_index
	return _get_raw_player_drop_index_at(mouse, row)

func _clear_drop_placeholder() -> void:
	if _drop_placeholder == null:
		return
	_drop_placeholder.visible = false
	_drop_placeholder_row = ""
	_drop_placeholder_index = -1
	_last_placeholder_index = -1
	_last_placeholder_row = ""
	if _drop_placeholder.get_parent() != null:
		_drop_placeholder.get_parent().remove_child(_drop_placeholder)

func _update_drag_board_preview(card_data: CardData, row: String, _mouse: Vector2) -> void:
	var board: Control = get_node_or_null("Board") as Control
	if board == null:
		return
	if _drag_board_preview == null or _drag_preview_card_data != card_data:
		_clear_drag_board_preview()
		_drag_board_preview = BOARD_MINION_SCENE.instantiate() as BoardMinion
		if _drag_board_preview == null:
			return
		_drag_board_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_drag_board_preview.z_index = 500
		_drag_board_preview.set_anchors_preset(Control.PRESET_TOP_LEFT, false)
		_drag_board_preview.custom_minimum_size = BOARD_MINION_SIZE
		_drag_board_preview.size = BOARD_MINION_SIZE
		board.add_child(_drag_board_preview)
		_drag_preview_card_data = card_data
		_drag_preview_row = ""
	_drag_board_preview.visible = true
	if _drag_preview_row != row:
		_drag_board_preview.set_minion(Minion.new(card_data, true, row))
		_drag_preview_row = row
	_drag_board_preview.scale = Vector2.ONE
	_drag_board_preview.modulate = Color(1.0, 1.0, 1.0, 0.92)
	_drag_board_preview.position = board.get_local_mouse_position() - BOARD_MINION_SIZE * 0.5

func _clear_drag_board_preview() -> void:
	if _drag_board_preview != null:
		_drag_board_preview.queue_free()
	_drag_board_preview = null
	_drag_preview_card_data = null
	_drag_preview_row = ""

func _on_hand_drag_started() -> void:
	# Compacter la main pour laisser la place au placeholder
	hand.set_compact(true)

func _on_hand_drag_ended() -> void:
	# Restaurer la main à son espacement normal
	hand.set_compact(false)
