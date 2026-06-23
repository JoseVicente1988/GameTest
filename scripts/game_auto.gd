extends Control

@onready var player: PlayerModel = get_node("PlayerModel")
@onready var enemy_view: EnemyView = get_node("MainLayout/CombatPanel/EnemyView")
@onready var floor_label: Label = get_node("MainLayout/TopBar/FloorLabel")
@onready var player_stats: Label = get_node("MainLayout/TopBar/PlayerStats")
@onready var log_label: RichTextLabel = get_node("MainLayout/LogPanel/LogLabel")
@onready var upgrade_popup: PanelContainer = get_node("UpgradePopup")
@onready var upgrade_a: UpgradeChoiceCard = get_node("UpgradePopup/MarginContainer/VBox/UpgradeA")
@onready var upgrade_b: UpgradeChoiceCard = get_node("UpgradePopup/MarginContainer/VBox/UpgradeB")

var normal_enemies: Array[EnemyData] = []
var boss_enemies: Array[EnemyData] = []
var upgrades: Array[UpgradeData] = []
var picked_upgrades: Dictionary = {}
var floor_number: int = 1
var enemy_stats: Dictionary = {}
var attack_timer: float = 0.0
var combat_running: bool = false

func _ready() -> void:
    randomize()
    normal_enemies = [load("res://resources/enemies/slime.tres"), load("res://resources/enemies/goblin.tres")]
    boss_enemies = [load("res://resources/enemies/stone_boss.tres")]
    upgrades = [
        load("res://resources/upgrades/player_damage.tres"),
        load("res://resources/upgrades/player_armor.tres"),
        load("res://resources/upgrades/player_health.tres"),
        load("res://resources/upgrades/player_regen.tres"),
        load("res://resources/upgrades/enemy_damage_down.tres"),
        load("res://resources/upgrades/enemy_armor_down.tres")
    ]
    player.stats_changed.connect(_refresh_ui)
    player.leveled_up.connect(_show_level_up_choices)
    upgrade_a.selected.connect(_on_upgrade_selected)
    upgrade_b.selected.connect(_on_upgrade_selected)
    upgrade_popup.visible = false
    player.reset_run()
    _spawn_enemy()
    combat_running = true
    _log("Run started.")

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
    if player.health <= 0:
        combat_running = false
        _log("Game Over. Floor reached: %s" % floor_number)

func _enemy_defeated() -> void:
    player.add_gold(int(enemy_stats["gold"]))
    player.add_xp(int(enemy_stats["xp"]))
    _roll_drops(enemy_stats.get("drops", []))
    _log("Defeated %s." % enemy_stats["name"])
    floor_number += 1
    _spawn_enemy()

func _spawn_enemy() -> void:
    var list: Array[EnemyData] = normal_enemies
    if floor_number % 5 == 0:
        list = boss_enemies
    var data: EnemyData = list[randi() % list.size()]
    enemy_stats = data.build_stats(floor_number, player.get_power())
    enemy_view.setup(enemy_stats)
    _refresh_ui()

func _roll_drops(drop_list: Array) -> void:
    for drop in drop_list:
        if drop is ItemData and randf() <= drop.drop_chance:
            player.apply_item(drop)
            _log("Drop: %s" % drop.item_name)

func _show_level_up_choices() -> void:
    combat_running = false
    upgrade_popup.visible = true
    var pool: Array[UpgradeData] = upgrades.duplicate()
    pool.shuffle()
    upgrade_a.setup(pool[0], int(picked_upgrades.get(pool[0].resource_path, 0)))
    upgrade_b.setup(pool[1], int(picked_upgrades.get(pool[1].resource_path, 0)))

func _on_upgrade_selected(upgrade: UpgradeData) -> void:
    var count: int = int(picked_upgrades.get(upgrade.resource_path, 0))
    player.apply_upgrade(upgrade, count)
    picked_upgrades[upgrade.resource_path] = count + 1
    upgrade_popup.visible = false
    combat_running = true
    _log("Upgrade: %s" % upgrade.upgrade_name)

func _refresh_ui() -> void:
    floor_label.text = "Floor: %s" % floor_number
    player_stats.text = "HP %s/%s | DMG %s | ARM %s | LV %s | XP %s/%s | Gold %s" % [player.health, player.max_health, player.damage, player.armor, player.level, player.xp, player.xp_to_next, player.gold]

func _log(message: String) -> void:
    log_label.append_text(message + "\n")
