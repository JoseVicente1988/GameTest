extends Node
class_name PlayerModel

signal stats_changed
signal leveled_up

var level: int = 1
var xp: int = 0
var xp_to_next: int = 25
var gold: int = 0

var max_health: int = 180
var health: int = 180
var damage: int = 18
var armor: int = 5
var regen: int = 0

var enemy_damage_reduction: int = 0
var enemy_armor_reduction: int = 0

func get_power() -> float:
    return float(max_health * 0.25 + damage * 2.5 + armor * 3.0 + regen * 4.0)

func reset_run() -> void:
    level = 1
    xp = 0
    xp_to_next = 25
    max_health = 180
    health = max_health
    damage = 18
    armor = 5
    regen = 0
    enemy_damage_reduction = 0
    enemy_armor_reduction = 0
    stats_changed.emit()

func take_damage(amount: int) -> void:
    var final_damage: int = max(1, amount - armor)
    health = max(0, health - final_damage)
    stats_changed.emit()

func heal(amount: int) -> void:
    health = min(max_health, health + amount)
    stats_changed.emit()

func add_xp(amount: int) -> void:
    xp += amount
    while xp >= xp_to_next:
        xp -= xp_to_next
        level += 1
        xp_to_next = int(float(xp_to_next) * 1.35) + 10
        leveled_up.emit()
    stats_changed.emit()

func add_gold(amount: int) -> void:
    gold += amount
    stats_changed.emit()

func apply_item(item: ItemData) -> void:
    damage += item.damage_bonus
    armor += item.armor_bonus
    max_health += item.max_health_bonus
    health += item.max_health_bonus
    gold += item.gold_bonus
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
