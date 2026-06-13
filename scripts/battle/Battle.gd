extends Control

@onready var hand = $Hand
@onready var mana_label = $ManaLabel
@onready var end_turn_button = $EndTurnButton
@onready var enemy_container = $Board/EnemyMinionsContainer
@onready var player_container = $Board/PlayerMinionsContainer

var player_minions: Array[Minion] = []
var enemy_minions: Array[Minion] = []
var selected_attacker: Minion
var selected_board_minion: BoardMinion
var deck: Array[CardData] = []
var hand_cards: Array[CardData] = []
var mana := 3
var max_mana := 3
var player_hero: Hero
var enemy_hero: Hero
var game_over := false

const BOARD_MINION_SCENE = preload("res://scenes/minion/BoardMinion.tscn")

func _ready():
	load_deck()
	var enemy_card = load("res://resources/cards/undead/decaying-crawler.tres")
	enemy_minions.append(Minion.new(enemy_card))
	player_hero = Hero.new(30)
	enemy_hero = Hero.new(30)
	hand.card_played.connect(_on_card_played)
	end_turn_button.pressed.connect(_on_end_turn_pressed)
	$EnemyHeroPanel.hero_clicked.connect(_on_enemy_hero_clicked)
	update_mana_ui()
	update_hero_ui()
	refresh_board()
	start_game()

func load_deck():
	var card = load("res://resources/cards/undead/zombified-cultist.tres")
	for i in range(10):
		deck.append(card)

func start_game():
	deck.shuffle()
	for i in range(5):
		draw_card()
	hand.set_hand(hand_cards)

func draw_card():
	if deck.is_empty():
		# TODO: fatigue damage au héros
		return
	hand_cards.append(deck.pop_back())

func _on_card_played(card_data: CardData):
	if game_over:
		return
	if card_data.cost > mana:
		return
	mana -= card_data.cost
	update_mana_ui()
	hand_cards.erase(card_data)
	hand.set_hand(hand_cards)
	summon_minion(card_data)

func update_mana_ui():
	mana_label.text = str(mana) + "/" + str(max_mana)

func _on_end_turn_pressed():
	if game_over:
		return
	end_turn()

func end_turn():
	start_new_turn()

func start_new_turn():
	max_mana = min(max_mana + 1, 10)
	mana = max_mana
	for minion in player_minions:
		minion.can_attack = true
	draw_card()
	hand.set_hand(hand_cards)
	update_mana_ui()
	refresh_board()

func summon_minion(card_data: CardData):
	var minion = Minion.new(card_data)
	player_minions.append(minion)
	refresh_board()

func refresh_board():
	
	for child in player_container.get_children():
		child.queue_free()
	for child in enemy_container.get_children():
		child.queue_free()
	for minion in player_minions:
		var visual = BOARD_MINION_SCENE.instantiate()
		player_container.add_child(visual)
		visual.set_minion(minion)
		visual.minion_clicked.connect(_on_player_minion_clicked)
	for minion in enemy_minions:
		var visual = BOARD_MINION_SCENE.instantiate()
		enemy_container.add_child(visual)
		visual.set_minion(minion)
		visual.minion_clicked.connect(_on_enemy_minion_clicked)
	if selected_attacker and not selected_attacker in player_minions:
		selected_attacker = null
		selected_board_minion = null


func _on_player_minion_clicked(minion: Minion, board_minion: BoardMinion):
	if game_over:
		return
	if not minion.can_attack:
		return
	if selected_board_minion:
		selected_board_minion.set_selected(false)
	selected_attacker = minion
	selected_board_minion = board_minion
	selected_board_minion.set_selected(true)
	

func _on_enemy_minion_clicked(target: Minion, _target_board_minion: BoardMinion):
	if game_over or selected_attacker == null:
		return
	if has_enemy_taunt() and not target.card_data.has_taunt:
		return
	resolve_combat(selected_attacker, target)
	clear_selection()
	

func resolve_combat(attacker: Minion, defender: Minion):
	defender.take_damage(attacker.attack)
	attacker.take_damage(defender.attack)
	attacker.can_attack = false
	remove_dead_minions()
	refresh_board()
	check_game_end()
	

func remove_dead_minions():
	player_minions = player_minions.filter(func(m): return not m.is_dead())
	enemy_minions = enemy_minions.filter(func(m): return not m.is_dead())

func update_hero_ui():
	$PlayerHeroPanel/HealthLabel.text = str(max(player_hero.health, 0))
	$EnemyHeroPanel/HealthLabel.text = str(max(enemy_hero.health, 0))

func has_enemy_taunt() -> bool:
	for minion in enemy_minions:
		if minion.card_data.has_taunt:
			return true
	return false

func _on_enemy_hero_clicked():
	if game_over or selected_attacker == null:
		return
	if has_enemy_taunt():
		return
	enemy_hero.take_damage(selected_attacker.attack)
	selected_attacker.can_attack = false
	clear_selection()
	update_hero_ui()
	check_game_end()
	refresh_board()

func clear_selection():
	if selected_board_minion:
		selected_board_minion.set_selected(false)
	selected_board_minion = null
	selected_attacker = null

func check_game_end():
	if enemy_hero.is_dead():
		game_over = true
	elif player_hero.is_dead():
		game_over = true
