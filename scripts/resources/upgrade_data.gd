extends Resource
class_name UpgradeData

enum UpgradeType {
    PLAYER_DAMAGE,
    PLAYER_ARMOR,
    PLAYER_MAX_HEALTH,
    PLAYER_REGEN,
    ENEMY_DAMAGE_REDUCTION,
    ENEMY_ARMOR_REDUCTION
}

@export var upgrade_name: String = "Upgrade"
@export_multiline var description: String = ""
@export var type: UpgradeType = UpgradeType.PLAYER_DAMAGE
@export var base_value: int = 10
@export var value_per_pick: int = 10

func get_value(times_picked: int) -> int:
    return base_value + (times_picked * value_per_pick)
