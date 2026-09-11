extends RefCounted
class_name CosmeticsPanel

# Sélection de dos de carte parmi ceux débloqués par le niveau de compte local
# (voir CosmeticsManager/SettingsManager.account_level). Purement cosmétique,
# aucun impact gameplay (voir CLAUDE.md, "éviter le Pay-to-Win"). Affichée à
# deux endroits : section "Cosmétiques" en bas de la vue Profil (open, avec
# son propre titre/séparateur — même esprit que ReferralPanel) et onglet
# "Dos de cartes" de la Boutique (build_into directement, le titre y étant
# déjà porté par l'onglet — voir MainMenu.gd).

const SWATCH_SIZE := Vector2(56, 84)

static func open(menu) -> void:
	var existing: Node = menu.profile_body.get_node_or_null("CosmeticsSection")
	if existing:
		existing.queue_free()

	var section := VBoxContainer.new()
	section.name = "CosmeticsSection"
	section.add_theme_constant_override("separation", 6)
	menu.profile_body.add_child(section)

	section.add_child(HSeparator.new())

	var title := Label.new()
	title.text = SettingsManager.t("COSMETICS_TITLE")
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(0.91, 0.835, 0.639, 1))
	section.add_child(title)

	build_into(section, func(): open(menu))

## Construit la grille de dos de carte directement dans `parent` (vidé
## d'abord), avec `on_selection_changed` rappelé après chaque sélection pour
## que l'appelant puisse se reconstruire lui-même (état "sélectionné"/"verrouillé"
## à jour) sans que ce script ait besoin de connaître son conteneur d'origine.
static func build_into(parent: Control, on_selection_changed: Callable) -> void:
	for child in parent.get_children():
		if child is HBoxContainer and child.name == "CosmeticsSwatchRow":
			child.queue_free()

	var row := HBoxContainer.new()
	row.name = "CosmeticsSwatchRow"
	row.add_theme_constant_override("separation", 10)
	parent.add_child(row)

	var card_back_tex: Texture2D = load("res://assets/card_back/card-back.png")
	for i in CosmeticsManager.CARD_BACKS.size():
		row.add_child(_make_swatch(i, card_back_tex, on_selection_changed))

static func _make_swatch(index: int, card_back_tex: Texture2D, on_selection_changed: Callable) -> VBoxContainer:
	var cb: Dictionary = CosmeticsManager.CARD_BACKS[index]
	var unlocked: bool = CosmeticsManager.is_unlocked(index)
	var is_selected: bool = SettingsManager.selected_card_back == index

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 4)

	var swatch := TextureRect.new()
	swatch.texture = card_back_tex
	swatch.custom_minimum_size = SWATCH_SIZE
	swatch.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	swatch.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	swatch.modulate = cb["tint"] if unlocked else Color(0.3, 0.3, 0.3, 0.6)
	col.add_child(swatch)

	var name_label := Label.new()
	name_label.text = SettingsManager.t(cb["key"])
	name_label.add_theme_font_size_override("font_size", 11)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	name_label.custom_minimum_size = Vector2(SWATCH_SIZE.x, 0)
	name_label.add_theme_color_override("font_color", Color(0.9, 0.87, 0.78, 1))
	col.add_child(name_label)

	var action_button := Button.new()
	action_button.custom_minimum_size = Vector2(SWATCH_SIZE.x, 30)
	if not unlocked:
		action_button.text = SettingsManager.t("COSMETICS_LOCKED") % int(cb["level"])
		action_button.disabled = true
	elif is_selected:
		action_button.text = SettingsManager.t("COSMETICS_SELECTED")
		action_button.disabled = true
	else:
		action_button.text = SettingsManager.t("COSMETICS_SELECT")
		action_button.pressed.connect(func():
			CosmeticsManager.select_card_back(index)
			on_selection_changed.call()
		)
	col.add_child(action_button)

	return col
