extends Control

@onready var player: PlayerModel = get_node("PlayerModel")
@onready var enemy_view: EnemyView = get_node("MainLayout/CombatPanel/EnemyView")
@onready var floor_label: Label = get_node("MainLayout/TopBar/FloorLabel")
@onready var player_stats: Label = get_node("MainLayout/TopBar/PlayerStats")
@onready var log_label: RichTextLabel = get_node("MainLayout/LogPanel/LogLabel")
@onready var upgrade_popup: PanelContainer = get_node("UpgradePopup")
@onready var upgrade_buttons: Array[Node] = [
    get_node("UpgradePopup/MarginContainer/VBox/UpgradeA"),
    get_node("UpgradePopup/MarginContainer/VBox/UpgradeB")
]

@export var normal_enemies: Array[EnemyData] = []
@export var boss_enemies: Array[EnemyData] = []
@export var upgrades: Array[UpgradeData] = []

var floor_number: int = 1
var enemy_stats: Dictionary = {}
var combat_running: bool = false
var attack_timer: float = 0.0
var picked_upgrades: Dictionary = {}

func _ready() -> void:
    randomize()
    player.stats_changed.connect(_refresh_ui)
    player.leveled_up.connect(_show_level_up_choices)
    for button in upgrade_buttons:
        button.selected.connect(_on_upgrade_selected)
    upgrade_popup.visible = false
    player.reset_run()
    _spawn_enemy()
    combat_running = true
    _log("Run started. Choose upgrades when you level up.")

func _process(delta: float) -> void:
    if not combat_running:
        return
    attack_timer += delta
    if attack_timer >= 0.85:
        attack_timer = 0.0
        _combat_tick()

func _combat_tick() -> void:
    var enemy_armor: int = max(0, int(enemy_stats["armor"]) - player.enemy_armor_reduction)
    var player_hit: int = max(1, player.damage - enemy_armor)
    enemy_stats["health"] = max(0, int(enemy_stats["health"]) - player_hit)
    enemy_view.update_health(int(enemy_stats["health"]))

    if int(enemy_stats["health"]) <= 0:
        _enemy_defeated()
        return

    var enemy_damage: int = max(1, int(enemy_stats["damage"]) - player.enemy_damage_reduction)
    player.take_damage(enemy_damage)
    if player.regen > 0:
        player.heal(player.regen)

    if player.health <= 0:
        combat_running = false
        _log("[color=red]Game Over.[/color] Floor reached: %s" % floor_number)

func _enemy_defeated() -> void:
    var xp_gain: int = int(enemy_stats["xp"])
    var gold_gain: int = int(enemy_stats["gold"])
    player.add_gold(gold_gain)
    player.add_xp(xp_gain)
    _roll_drops(enemy_stats.get("drops", []))
    _log("Defeated %s. +%s XP, +%s gold." % [enemy_stats["name"], xp_gain, gold_gain])
    floor_number += 1
    _spawn_enemy()

func _spawn_enemy() -> void:
    var list: Array[EnemyData] = normal_enemies
    if floor_number % 5 == 0 and boss_enemies.size() > 0:
        list = boss_enemies
    if list.is_empty():
        push_error("No enemies assigned in Game.tscn inspector.")
        return
    var data: EnemyData = list[randi() % list.size()]
    enemy_stats = data.build_stats(floor_number, player.get_power())
    enemy_view.setup(enemy_stats)
    _refresh_ui()

func _roll_drops(drop_list: Array) -> void:
    for drop in drop_list:
        if drop is ItemData and randf() <= drop.drop_chance:
            player.apply_item(drop)
            _log("[color=yellow]Drop:[/color] %s" % drop.item_name)

func _show_level_up_choices() -> void:
    combat_running = false
    upgrade_popup.visible = true
    var options: Array[UpgradeData] = _get_two_random_upgrades()
    for i in range(upgrade_buttons.size()):
        var data: UpgradeData = options[i]
        var picked_count: int = int(picked_upgrades.get(data.resource_path, 0))
        upgrade_buttons[i].setup(data, picked_count)

func _get_two_random_upgrades() -> Array[UpgradeData]:
    var pool: Array[UpgradeData] = upgrades.duplicate()
    pool.shuffle()
    return [pool[0], pool[1]]

func _on_upgrade_selected(upgrade: UpgradeData) -> void:
    var key: String = upgrade.resource_path
    var picked_count: int = int(picked_upgrades.get(key, 0))
    player.apply_upgrade(upgrade, picked_count)
    picked_upgrades[key] = picked_count + 1
    upgrade_popup.visible = false
    combat_running = true
    _log("[color=cyan]Upgrade selected:[/color] %s" % upgrade.upgrade_name)

func _refresh_ui() -> void:
    floor_label.text = "Floor: %s" % floor_number
    player_stats.text = "HP %s/%s | DMG %s | ARM %s | LV %s | XP %s/%s | Gold %s" % [
        player.health,
        player.max_health,
        player.damage,
        player.armor,
        player.level,
        player.xp,
        player.xp_to_next,
        player.gold
    ]

func _log(message: String) -> void:
    log_label.append_text(message + "\n")
