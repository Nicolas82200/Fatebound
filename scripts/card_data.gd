extends Resource
class_name CardData

## Identité
@export var card_name: String = "Nouvelle carte"
@export_multiline var description: String = ""
@export var texture: Texture2D
@export var cost: int = 1

## Race / Faction
@export_enum("Undead", "Human", "Elf", "Dwarf", "Demon") var race: String = "Undead"

## Type de carte
@export_enum("Minion", "Spell", "Weapon") var card_type: String = "Minion"

## Stats
@export var attack: int = 0
@export var health: int = 0

## Mots-clés
@export var has_taunt: bool = false
@export var has_charge: bool = false
@export var has_protection: bool = false
@export var has_lifesteal: bool = false
@export var has_fury: bool = false

## Effets
@export_enum("None", "Battlecry", "Deathrattle", "OnTurnStart", "OnTurnEnd","OnMinionsDeath") var trigger_type: String = "None"
@export var effect_id: String = ""
@export var effect_value: int = 0
@export var effect_target: String = "Enemy"

## Rareté
@export_enum("Common", "Rare", "Epic", "Legendary") var rarity: String = "Common"
