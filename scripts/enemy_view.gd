extends Control
class_name EnemyView

@onready var name_label: Label = get_node("Panel/VBox/NameLabel")
@onready var hp_bar: ProgressBar = get_node("Panel/VBox/HealthBar")
@onready var sprite: ColorRect = get_node("Panel/VBox/EnemySprite")
@onready var stats_label: Label = get_node("Panel/VBox/StatsLabel")

var current_stats: Dictionary = {}

func setup(stats: Dictionary) -> void:
    current_stats = stats
    name_label.text = str(stats.get("name", "Enemy"))
    hp_bar.max_value = int(stats.get("max_health", 1))
    hp_bar.value = int(stats.get("health", 1))
    sprite.color = stats.get("color", Color.RED)
    stats_label.text = "DMG %s / ARM %s" % [stats.get("damage", 0), stats.get("armor", 0)]

func update_health(value: int) -> void:
    current_stats["health"] = value
    hp_bar.value = value
