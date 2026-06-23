extends Resource
class_name EnemyData

@export var enemy_name: String = "Enemy"
@export var enemy_texture: Texture2D
@export var base_health: int = 100
@export var base_damage: int = 10
@export var base_armor: int = 2
@export var base_xp: int = 10
@export var base_gold: int = 5
@export var level_power: float = 1.15
@export var player_power_weight: float = 0.35
@export var drops: Array[Resource] = []

func build_stats(floor_number: int, player_power: float) -> Dictionary:
    var floor_scale: float = pow(level_power, max(0, floor_number - 1))
    var player_scale: float = 1.0 + (player_power * player_power_weight / 100.0)
    return {
        "name": enemy_name,
        "texture": enemy_texture,
        "health": int(base_health * floor_scale * player_scale),
        "max_health": int(base_health * floor_scale * player_scale),
        "damage": int(base_damage * floor_scale * player_scale),
        "armor": int(base_armor * floor_scale),
        "xp": int(base_xp * floor_scale),
        "gold": int(base_gold * floor_scale),
        "drops": drops
    }
