extends Node
class_name PlayerModel

signal stats_changed
signal leveled_up
signal meta_changed

const SAVE_PATH: String = "user://pocket_dungeon_save.cfg"

var level: int = 1
var xp: int = 0
var xp_to_next: int = 25

var run_gold: int = 0
var persistent_gold: int = 0

var permanent_damage_level: int = 0
var permanent_armor_level: int = 0
var permanent_health_level: int = 0
var permanent_gold_level: int = 0
var permanent_all_stats_level: int = 0
var ad_training_level: int = 0

var max_health: int = 180
var health: int = 180
var damage: int = 18
var armor: int = 5
var regen: int = 0

var enemy_damage_reduction: int = 0
var enemy_armor_reduction: int = 0

func _ready() -> void:
    load_progress()

func get_power() -> float:
    return float(max_health * 0.25 + damage * 2.5 + armor * 3.0 + regen * 4.0)

func reset_run() -> void:
    level = 1
    xp = 0
    xp_to_next = 25
    run_gold = 0

    var all_health_bonus: int = permanent_all_stats_level * 15
    var all_damage_bonus: int = permanent_all_stats_level * 2
    var all_armor_bonus: int = permanent_all_stats_level * 1

    var ad_health_bonus: int = ad_training_level * 8
    var ad_damage_bonus: int = ad_training_level * 1

    max_health = 180 + permanent_health_level * 25 + all_health_bonus + ad_health_bonus
    health = max_health
    damage = 18 + permanent_damage_level * 4 + all_damage_bonus + ad_damage_bonus
    armor = 5 + permanent_armor_level * 2 + all_armor_bonus
    regen = 0
    enemy_damage_reduction = 0
    enemy_armor_reduction = 0
    stats_changed.emit()
    meta_changed.emit()

func take_damage(amount: int) -> void:
    var final_damage: int = max(1, amount - armor)
    health = max(0, health - final_damage)
    stats_changed.emit()

func heal(amount: int) -> void:
    health = min(max_health, health + amount)
    stats_changed.emit()

func revive_from_ad() -> void:
    health = max(1, int(float(max_health) * 0.5))
    stats_changed.emit()

func add_xp(amount: int) -> void:
    xp += amount
    while xp >= xp_to_next:
        xp -= xp_to_next
        level += 1
        xp_to_next = int(float(xp_to_next) * 1.35) + 10
        leveled_up.emit()
    stats_changed.emit()

func add_gold(amount: int) -> int:
    var final_amount: int = int(float(amount) * get_gold_multiplier())
    final_amount = max(1, final_amount)
    run_gold += final_amount
    persistent_gold += final_amount
    save_progress()
    stats_changed.emit()
    meta_changed.emit()
    return final_amount

func add_ad_gold(amount: int) -> int:
    var final_amount: int = max(1, amount)
    run_gold += final_amount
    persistent_gold += final_amount
    save_progress()
    stats_changed.emit()
    meta_changed.emit()
    return final_amount

func double_current_run_gold_from_ad() -> int:
    var bonus: int = max(1, run_gold)
    persistent_gold += bonus
    run_gold += bonus
    save_progress()
    stats_changed.emit()
    meta_changed.emit()
    return bonus

func add_ad_training_level() -> void:
    ad_training_level += 1
    save_progress()
    reset_run()
    meta_changed.emit()

func get_gold_multiplier() -> float:
    return 1.0 + float(permanent_gold_level) * 0.08

func apply_item(item: ItemData) -> void:
    damage += item.damage_bonus
    armor += item.armor_bonus
    max_health += item.max_health_bonus
    health += item.max_health_bonus
    if item.gold_bonus > 0:
        add_gold(item.gold_bonus)
    stats_changed.emit()

func apply_upgrade(upgrade: UpgradeData, times_picked: int) -> void:
    var value: int = upgrade.get_value(times_picked)
    if upgrade.type == UpgradeData.UpgradeType.PLAYER_DAMAGE:
        damage += value
    elif upgrade.type == UpgradeData.UpgradeType.PLAYER_ARMOR:
        armor += value
    elif upgrade.type == UpgradeData.UpgradeType.PLAYER_MAX_HEALTH:
        max_health += value
        health += value
    elif upgrade.type == UpgradeData.UpgradeType.PLAYER_REGEN:
        regen += value
    elif upgrade.type == UpgradeData.UpgradeType.ENEMY_DAMAGE_REDUCTION:
        enemy_damage_reduction += value
    elif upgrade.type == UpgradeData.UpgradeType.ENEMY_ARMOR_REDUCTION:
        enemy_armor_reduction += value
    stats_changed.emit()

func get_upgrade_cost(upgrade_id: String) -> int:
    if upgrade_id == "damage":
        return 60 + permanent_damage_level * 45
    elif upgrade_id == "armor":
        return 55 + permanent_armor_level * 40
    elif upgrade_id == "health":
        return 70 + permanent_health_level * 50
    elif upgrade_id == "gold":
        return 90 + permanent_gold_level * 70
    elif upgrade_id == "all_stats":
        return 140 + permanent_all_stats_level * 95
    return 999999

func buy_permanent_upgrade(upgrade_id: String) -> bool:
    var cost: int = get_upgrade_cost(upgrade_id)
    if persistent_gold < cost:
        return false

    persistent_gold -= cost

    if upgrade_id == "damage":
        permanent_damage_level += 1
    elif upgrade_id == "armor":
        permanent_armor_level += 1
    elif upgrade_id == "health":
        permanent_health_level += 1
    elif upgrade_id == "gold":
        permanent_gold_level += 1
    elif upgrade_id == "all_stats":
        permanent_all_stats_level += 1
    else:
        persistent_gold += cost
        return false

    save_progress()
    reset_run()
    meta_changed.emit()
    return true

func get_base_stats_text() -> String:
    return "Base DMG Lv.%s | ARM Lv.%s | HP Lv.%s | Gold Lv.%s | All Lv.%s | Ad Training Lv.%s" % [
        permanent_damage_level,
        permanent_armor_level,
        permanent_health_level,
        permanent_gold_level,
        permanent_all_stats_level,
        ad_training_level
    ]

func save_progress() -> void:
    var config: ConfigFile = ConfigFile.new()
    config.set_value("currency", "persistent_gold", persistent_gold)
    config.set_value("upgrades", "damage", permanent_damage_level)
    config.set_value("upgrades", "armor", permanent_armor_level)
    config.set_value("upgrades", "health", permanent_health_level)
    config.set_value("upgrades", "gold", permanent_gold_level)
    config.set_value("upgrades", "all_stats", permanent_all_stats_level)
    config.set_value("ads", "training", ad_training_level)
    config.save(SAVE_PATH)

func load_progress() -> void:
    var config: ConfigFile = ConfigFile.new()
    var error: Error = config.load(SAVE_PATH)
    if error != OK:
        return

    persistent_gold = int(config.get_value("currency", "persistent_gold", 0))
    permanent_damage_level = int(config.get_value("upgrades", "damage", 0))
    permanent_armor_level = int(config.get_value("upgrades", "armor", 0))
    permanent_health_level = int(config.get_value("upgrades", "health", 0))
    permanent_gold_level = int(config.get_value("upgrades", "gold", 0))
    permanent_all_stats_level = int(config.get_value("upgrades", "all_stats", 0))
    ad_training_level = int(config.get_value("ads", "training", 0))
    meta_changed.emit()

func reset_save() -> void:
    persistent_gold = 0
    permanent_damage_level = 0
    permanent_armor_level = 0
    permanent_health_level = 0
    permanent_gold_level = 0
    permanent_all_stats_level = 0
    ad_training_level = 0
    save_progress()
    reset_run()
