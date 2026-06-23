extends Control

@onready var player: PlayerModel = get_node("PlayerModel")
@onready var enemy_view: EnemyView = get_node("MainLayout/CombatPanel/EnemyView")
@onready var floor_label: Label = get_node("MainLayout/TopBar/FloorLabel")
@onready var player_stats: Label = get_node("MainLayout/TopBar/PlayerStats")
@onready var bank_label: Label = get_node("MainLayout/TopBar/BankLabel")
@onready var feedback_label: Label = get_node("MainLayout/FeedbackLabel")
@onready var log_label: RichTextLabel = get_node("MainLayout/LogPanel/LogLabel")
@onready var upgrade_popup: PanelContainer = get_node("UpgradePopup")
@onready var upgrade_a: UpgradeChoiceCard = get_node("UpgradePopup/MarginContainer/VBox/UpgradeA")
@onready var upgrade_b: UpgradeChoiceCard = get_node("UpgradePopup/MarginContainer/VBox/UpgradeB")
@onready var game_over_popup: PanelContainer = get_node("GameOverPopup")
@onready var summary_label: Label = get_node("GameOverPopup/MarginContainer/VBox/SummaryLabel")
@onready var revive_button: Button = get_node("GameOverPopup/MarginContainer/VBox/ReviveButton")
@onready var restart_button: Button = get_node("GameOverPopup/MarginContainer/VBox/RestartButton")
@onready var shop_label: Label = get_node("MainLayout/ShopPanel/MarginContainer/VBox/ShopLabel")
@onready var damage_button: Button = get_node("MainLayout/ShopPanel/MarginContainer/VBox/DamageButton")
@onready var armor_button: Button = get_node("MainLayout/ShopPanel/MarginContainer/VBox/ArmorButton")
@onready var health_button: Button = get_node("MainLayout/ShopPanel/MarginContainer/VBox/HealthButton")
@onready var gold_button: Button = get_node("MainLayout/ShopPanel/MarginContainer/VBox/GoldButton")

var normal_enemies: Array[EnemyData] = []
var boss_enemies: Array[EnemyData] = []
var upgrades: Array[UpgradeData] = []
var picked_upgrades: Dictionary = {}

var floor_number: int = 1
var enemy_stats: Dictionary = {}
var attack_timer: float = 0.0
var combat_running: bool = false
var revive_used: bool = false
var enemies_defeated: int = 0
var bosses_defeated: int = 0
var run_xp_earned: int = 0
var last_run_gold: int = 0

func _ready() -> void:
    randomize()
    _load_resources()
    player.stats_changed.connect(_refresh_ui)
    player.meta_changed.connect(_refresh_shop)
    player.leveled_up.connect(_show_level_up_choices)
    upgrade_a.selected.connect(_on_upgrade_selected)
    upgrade_b.selected.connect(_on_upgrade_selected)
    revive_button.pressed.connect(_on_revive_button_pressed)
    restart_button.pressed.connect(_start_new_run)
    damage_button.pressed.connect(_on_damage_button_pressed)
    armor_button.pressed.connect(_on_armor_button_pressed)
    health_button.pressed.connect(_on_health_button_pressed)
    gold_button.pressed.connect(_on_gold_button_pressed)
    upgrade_popup.visible = false
    game_over_popup.visible = false
    _start_new_run()

func _load_resources() -> void:
    normal_enemies = [
        load("res://resources/enemies/slime.tres"),
        load("res://resources/enemies/goblin.tres")
    ]
    boss_enemies = [
        load("res://resources/enemies/stone_boss.tres")
    ]
    upgrades = [
        load("res://resources/upgrades/player_damage.tres"),
        load("res://resources/upgrades/player_armor.tres"),
        load("res://resources/upgrades/player_health.tres"),
        load("res://resources/upgrades/player_regen.tres"),
        load("res://resources/upgrades/enemy_damage_down.tres"),
        load("res://resources/upgrades/enemy_armor_down.tres")
    ]

func _process(delta: float) -> void:
    if not combat_running:
        return

    attack_timer += delta
    if attack_timer >= 0.85:
        attack_timer = 0.0
        _combat_tick()

func _start_new_run() -> void:
    floor_number = 1
    picked_upgrades.clear()
    revive_used = false
    enemies_defeated = 0
    bosses_defeated = 0
    run_xp_earned = 0
    last_run_gold = 0
    attack_timer = 0.0
    upgrade_popup.visible = false
    game_over_popup.visible = false
    player.reset_run()
    _spawn_enemy()
    combat_running = true
    _set_feedback("New run started. Kill enemies, earn gold, upgrade permanently.")
    _log("[color=cyan]Run started.[/color]")
    _refresh_shop()

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
        _show_game_over()

func _enemy_defeated() -> void:
    var gold_gain: int = int(enemy_stats["gold"])
    var xp_gain: int = int(enemy_stats["xp"])
    var was_boss: bool = floor_number % 5 == 0

    player.add_gold(gold_gain)
    player.add_xp(xp_gain)
    _roll_drops(enemy_stats.get("drops", []))

    enemies_defeated += 1
    run_xp_earned += xp_gain
    last_run_gold = player.run_gold
    if was_boss:
        bosses_defeated += 1

    _set_feedback("+%s gold | +%s XP | Defeated %s" % [gold_gain, xp_gain, enemy_stats["name"]])
    _log("[color=yellow]+%s gold[/color]  [color=lime]+%s XP[/color]  %s defeated." % [gold_gain, xp_gain, enemy_stats["name"]])

    floor_number += 1
    _spawn_enemy()

func _spawn_enemy() -> void:
    var list: Array[EnemyData] = normal_enemies
    if floor_number % 5 == 0 and boss_enemies.size() > 0:
        list = boss_enemies
        _set_feedback("Boss incoming. Floor %s." % floor_number)

    if list.is_empty():
        push_error("No enemies loaded.")
        return

    var data: EnemyData = list[randi() % list.size()]
    enemy_stats = data.build_stats(floor_number, player.get_power())
    enemy_view.setup(enemy_stats)
    _refresh_ui()

func _roll_drops(drop_list: Array) -> void:
    for drop in drop_list:
        if drop is ItemData and randf() <= drop.drop_chance:
            player.apply_item(drop)
            _log("[color=orange]Drop:[/color] %s - %s" % [drop.item_name, drop.description])
            _set_feedback("Drop found: %s" % drop.item_name)

func _show_level_up_choices() -> void:
    combat_running = false
    upgrade_popup.visible = true

    var pool: Array[UpgradeData] = upgrades.duplicate()
    pool.shuffle()
    upgrade_a.setup(pool[0], int(picked_upgrades.get(pool[0].resource_path, 0)))
    upgrade_b.setup(pool[1], int(picked_upgrades.get(pool[1].resource_path, 0)))
    _set_feedback("Level up! Choose one upgrade.")

func _on_upgrade_selected(upgrade: UpgradeData) -> void:
    var count: int = int(picked_upgrades.get(upgrade.resource_path, 0))
    player.apply_upgrade(upgrade, count)
    picked_upgrades[upgrade.resource_path] = count + 1
    upgrade_popup.visible = false
    combat_running = true
    _set_feedback("Upgrade selected: %s" % upgrade.upgrade_name)
    _log("[color=cyan]Upgrade:[/color] %s" % upgrade.upgrade_name)

func _show_game_over() -> void:
    combat_running = false
    game_over_popup.visible = true
    revive_button.visible = not revive_used
    summary_label.text = "Run finished\nFloor: %s\nEnemies defeated: %s\nBosses defeated: %s\nRun gold: %s\nXP earned: %s\nBank gold: %s" % [
        floor_number,
        enemies_defeated,
        bosses_defeated,
        player.run_gold,
        run_xp_earned,
        player.persistent_gold
    ]
    _set_feedback("You died. Revive once with rewarded ad or spend gold in base upgrades.")
    _log("[color=red]Game Over.[/color] Floor reached: %s. Run gold: %s." % [floor_number, player.run_gold])

func _on_revive_button_pressed() -> void:
    if revive_used:
        return

    revive_used = true
    game_over_popup.visible = false
    player.revive_from_ad()
    combat_running = true
    _set_feedback("Rewarded ad completed. Revived with 50% HP.")
    _log("[color=lime]Rewarded revive used.[/color]")

func _on_damage_button_pressed() -> void:
    _buy_upgrade("damage")

func _on_armor_button_pressed() -> void:
    _buy_upgrade("armor")

func _on_health_button_pressed() -> void:
    _buy_upgrade("health")

func _on_gold_button_pressed() -> void:
    _buy_upgrade("gold")

func _buy_upgrade(upgrade_id: String) -> void:
    var bought: bool = player.buy_permanent_upgrade(upgrade_id)
    if bought:
        _set_feedback("Permanent upgrade bought: %s" % upgrade_id)
        _log("[color=cyan]Base upgrade bought:[/color] %s" % upgrade_id)
        _start_new_run()
    else:
        _set_feedback("Not enough gold for %s upgrade." % upgrade_id)

func _refresh_ui() -> void:
    floor_label.text = "Floor: %s" % floor_number
    player_stats.text = "HP %s/%s | DMG %s | ARM %s | LV %s | XP %s/%s | Run Gold %s" % [
        player.health,
        player.max_health,
        player.damage,
        player.armor,
        player.level,
        player.xp,
        player.xp_to_next,
        player.run_gold
    ]
    bank_label.text = "Bank Gold: %s" % player.persistent_gold

func _refresh_shop() -> void:
    shop_label.text = "Base Upgrades | Bank Gold: %s" % player.persistent_gold
    damage_button.text = "Damage Lv.%s (+4) - Cost %s" % [player.permanent_damage_level, player.get_upgrade_cost("damage")]
    armor_button.text = "Armor Lv.%s (+2) - Cost %s" % [player.permanent_armor_level, player.get_upgrade_cost("armor")]
    health_button.text = "Health Lv.%s (+25) - Cost %s" % [player.permanent_health_level, player.get_upgrade_cost("health")]
    gold_button.text = "Gold Lv.%s (+8%%) - Cost %s" % [player.permanent_gold_level, player.get_upgrade_cost("gold")]
    _refresh_ui()

func _set_feedback(message: String) -> void:
    feedback_label.text = message

func _log(message: String) -> void:
    log_label.append_text(message + "\n")
    log_label.scroll_to_line(log_label.get_line_count())
