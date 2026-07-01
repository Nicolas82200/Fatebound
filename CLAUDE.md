# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

FateBound — a dark-fantasy 1v1 tactical card game (TCG) built in **Godot 4.6** using **GDScript**. Two players place minions in a Front/Back row lane system and try to reduce the enemy hero to 0 HP. Full game rules (mana, lanes, races, keywords, triggers) are documented in `README.md`; the complete card list is in `CARDS.md`.

## Running / building

There is no CLI build or test suite — this is a Godot project, validated by running it in the editor.

- Open the project in Godot 4.6, main scene is `scenes/battle/Battle.tscn` (set via `run/main_scene` in `project.godot`).
- Run with F5, or launch `MainMenu.tscn` to go through the normal game flow (menu → deck → battle).
- After any gameplay-logic change, manually play through a basic scenario: play a card, place a minion, attack, end the turn, check the graveyard. There is no automated test suite, so this manual pass is the only verification.
- `.tres` card resources under `resources/cards/` are regular Godot resources — reload/reimport happens automatically when Godot regains focus.

### Card-authoring helper scripts (Python, run outside Godot)

- `tresGenerator.py` — bulk-generates `.tres` `CardData` resource files for `resources/cards/{human,undead}` from data tables inside the script (keyword/trigger name → enum mappings, stable `ext_resource` UIDs for shared types like `CardEffect`, `KeywordChoice`, `CardData`, `TriggerType`).
- `convert_tres.py` — converts/migrates existing `.tres` card files (e.g. keyword remapping) using its own `KEYWORD_MAP`.
- `update_card_positions.py` / `.sh` — updates each card's `board_position` (Front/Back/Hybrid) in its `.tres` file from a name → lane table sourced from `CARDS.md`.

These scripts hardcode French keyword/card names and enum values that must stay in sync with `scripts/data/Keyword.gd`, `scripts/data/KeywordHuman.gd`, and `scripts/data/TriggerType.gd`. If you add/rename a keyword or trigger, update both the GDScript enum and these scripts' mapping tables.

## Architecture

### Current state: monolithic `Battle.gd` + a partial `systems/` refactor in progress

`scripts/battle/Battle.gd` (~860 lines) is the central controller: it owns board state (`player_minions`, `enemy_minions`, both graveyards, mana, hero references), wires up the `Hand`, drives turn flow, and directly implements most gameplay logic (drop handling, combat, targeting, death cleanup, board refresh).

`scripts/systems/` (`BoardSystem`, `CombatSystem`, `TurnSystem`, `DropSystem`, `TargetingSystem`, `SelectionSystem`, `DeathSystem`, `BoardVisualSystem`, `HeroSystem`, `CardPopupSystem`, `GraveyardSystem`, `DeckSystem`, `EnchantmentSystem`, `AuraSystem`, `AnimationSystem`, `CardSystem`, `TriggersSystem`) is a **work-in-progress decomposition** of `Battle.gd` into focused `Node` classes that each take a `battle` back-reference. **None of these are currently instantiated anywhere in the project** — they exist as scaffolding for an ongoing refactor, not yet wired into `Battle.tscn`/`Battle.gd`.

`scripts/EffectManager/EffectManager.gd` already anticipates this migration: after executing a card effect it does `battle.get("death_system")` / `board_visual_system` / `hero_system`, and only if that system exists and exposes the expected method does it use it — otherwise it falls back to calling the equivalent method directly on `battle` (e.g. `battle.remove_dead_minions()`). When extending `EffectManager` or migrating logic into `systems/`, preserve this fallback pattern so both the old monolithic path and the new system path keep working until the migration is complete.

### Effect system

Card effects are data-driven: `CardEffect` resources (referenced from `CardData.effects`) carry an `effect_id` string (e.g. `"Damage"`, `"Heal"`, `"SummonMinion"`, `"Silence"`, `"Transform"`...). `EffectManager.execute_effect()` is a big `match` over `effect_id` dispatching to private handlers (`_damage`, `_heal`, `_summon_minion`, ...). To add a new effect type: add a case to that `match`, implement the handler, and reference the new `effect_id` from card `.tres` resources (or `tresGenerator.py`).

### Card data model

- `CardData` (`scripts/card/CardData.gd`) is the `Resource` type backing every card `.tres` file: name, cost, race, `card_type` (Minion/Instant/Ritual/Enchantment), attack/health, `board_position` (Front/Back/Hybrid), `keywords`/`human_keywords` (arrays of `KeywordChoice`), `trigger_types`, and `effects`.
- Enums for races, keywords, and triggers live under `scripts/data/` (`Race.gd`, `Keyword.gd`, `KeywordHuman.gd`, `TriggerType.gd`) — each has a `get_name()`/`from_name()` mapping between the enum and the French display string used in the UI and in card resources.
- Human-race cards use a separate keyword set (`KeywordHuman`/`KeywordChoiceHuman`) distinct from the general `Keyword`/`KeywordChoice` used by other races.
- Card resources live under `resources/cards/{human,undead}/`; `CardLibrary` (autoload) recursively scans `resources/cards` at startup to build the full card catalog.

### Autoloads (singletons, `project.godot` `[autoload]`)

`AudioManager`, `DeckManager` (deck CRUD + save/load to `user://decks.cfg`, `scripts/deck/DeckManager.gd`), `TooltipData`, `CardLibrary` (`scripts/loading/CardLibrary.gd`).

### Scene/script pairing

Scenes under `scenes/<area>/` generally pair 1:1 with a script of the same name under `scripts/<area>/` (e.g. `scenes/minion/BoardMinion.tscn` ↔ `scripts/minion/BoardMinion.gd`). Key ones: `battle/Battle`, `card/Card`, `card/enchantment/EnchantmentCard`, `hand/Hand`, `minion/Minion` (logical) vs `minion/BoardMinion` (visual board instance), `graveyard/Graveyard` (data, no scene) vs `graveyard/GraveyardView` (UI), `hero/Hero` (data) vs `hero/HeroPanel` (UI), `deck/DeckBuilder`, `deck/DeckList`.

## Working conventions

- Prefer small, targeted changes; respect the existing scene/script structure rather than introducing parallel systems.
- When touching gameplay logic, check side effects across: UI, hand drag/drop, board placement, mana, graveyard, and end-of-turn flow — these are all threaded through `Battle.gd`.
- Keep variable/function naming consistent with the surrounding code (English identifiers, French user-facing strings/keyword names).
- Don't remove or rename scenes without updating every reference to them.
- New cards: add the `.tres` resource under `resources/cards/{human,undead}/` following the existing structure (or extend `tresGenerator.py`), and update `CARDS.md`.
