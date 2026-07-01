# SKILL.md — Guide Claude pour FateBound

Ce projet est un jeu de cartes tactique en Godot 4.6, écrit en GDScript. Le cœur du gameplay est la bataille, le placement des cartes, la gestion de la main, les serviteurs et les effets de cartes.

## Contexte du projet
- Nom du jeu : FateBound
- Moteur : Godot 4.6
- Langage : GDScript
- Point d'entrée principal : project.godot
- Scène de bataille principale : scenes/battle/Battle.tscn

## Structure importante
- scripts/battle/ : logique de bataille, board, rangées, tour, mana, effets globaux
- scripts/card/ : logique d'affichage et de drag/drop des cartes
- scripts/minion/ : logique des serviteurs
- scripts/hero/ : logique des héros
- scripts/data/ : structures de données comme CardData, races, mots-clés
- resources/cards/ : définitions des cartes sous forme de ressources .tres
- scenes/ : scènes Godot principales et UI

## Règles de travail
- Préférer des changements petits et ciblés.
- Respecter la structure existante des scènes et des scripts.
- Éviter d’écrire du code “à la place” si une logique similaire existe déjà.
- Lorsque tu modifies un système de gameplay, vérifier les effets de bord : UI, drag/drop, placement sur le board, mana, graveyard, fin de tour.
- Garder les noms de variables et fonctions cohérents avec l’architecture actuelle.

## Conventions utiles
- Utiliser des chemins res:// pour les assets et scripts.
- Les scènes et scripts Godot sont souvent liés par des nœuds @onready et des signaux.
- Les cartes sont souvent gérées via des données de type CardData et des instances de scène (Card, Minion, BoardMinion).
- Les effets de cartes doivent rester cohérents avec le système existant dans Battle.gd / EffectManager.
- Éviter de casser les signaux liés au drag/drop de la main.

## Modifications fréquentes
### Si tu ajoutes une nouvelle mécanique
1. Identifier le composant concerné : bataille, serviteur, carte, effet, UI.
2. Implémenter la logique au bon endroit.
3. Mettre à jour la scène si l’UI doit changer.
4. Vérifier l’intégration avec les cartes existantes et les ressources .tres.

### Si tu crées une nouvelle carte
- Ajouter la ressource dans resources/cards/ avec la structure déjà utilisée par les autres cartes.
- Vérifier les champs : nom, coût, type, attaque, santé, description, race, texture, rareté.
- S’assurer que la carte est compatible avec les effets et le placement sur le board.

## Validation
- Vérifier le projet dans Godot après chaque modification importante.
- Si Godot est disponible, lancer le projet depuis la scène Battle.tscn.
- En cas de changement de logique de gameplay, tester au moins un scénario de base : jouer une carte, placer un serviteur, attaquer, finir le tour.

## À éviter
- Ne pas modifier les fichiers générés automatiquement si ce n’est pas nécessaire.
- Ne pas supprimer ou renommer des scènes sans mettre à jour les références.
- Éviter de dupliquer des systèmes déjà présents.

## Références utiles
- README.md : règles, mécaniques, roadmap et contexte du jeu
- project.godot : configuration du projet et autoloads
- scripts/battle/Battle.gd : logique centrale de la bataille
- scripts/card/Card.gd : rendu et interaction des cartes
