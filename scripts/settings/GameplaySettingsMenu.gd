extends Control

# Onglet Gameplay du menu Réglages : confirmations avant attaque/sacrifice
# (voir SettingsManager.confirm_before_attack/confirm_before_sacrifice,
# consommées par SelectionSystem/SacrificeSystem via ConfirmActionPopup).

@onready var confirm_attack_check:    CheckButton = %ConfirmAttackCheck
@onready var confirm_sacrifice_check: CheckButton = %ConfirmSacrificeCheck

@onready var _localized_labels := {
	"gameplay.confirm_attack":    $VBox/RowsMargin/RowsScroll/RowsVBox/ConfirmAttackRow/ConfirmAttackLabel,
	"gameplay.confirm_sacrifice": $VBox/RowsMargin/RowsScroll/RowsVBox/ConfirmSacrificeRow/ConfirmSacrificeLabel,
}

func _ready() -> void:
	confirm_attack_check.button_pressed = SettingsManager.confirm_before_attack
	confirm_attack_check.toggled.connect(func(on: bool): SettingsManager.set_confirm_before_attack(on))
	confirm_sacrifice_check.button_pressed = SettingsManager.confirm_before_sacrifice
	confirm_sacrifice_check.toggled.connect(func(on: bool): SettingsManager.set_confirm_before_sacrifice(on))

	SettingsManager.language_changed.connect(func(_l): _retranslate())
	_retranslate()

func _retranslate() -> void:
	for key in _localized_labels:
		_localized_labels[key].text = SettingsManager.t(key)
