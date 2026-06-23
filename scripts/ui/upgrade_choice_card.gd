extends Button
class_name UpgradeChoiceCard

signal selected(upgrade: UpgradeData)

var upgrade_data: UpgradeData
var times_picked: int = 0

func setup(data: UpgradeData, picked_count: int) -> void:
    upgrade_data = data
    times_picked = picked_count
    var value: int = data.get_value(times_picked)
    text = "%s\n%s %s" % [data.upgrade_name, data.description, value]

func _pressed() -> void:
    selected.emit(upgrade_data)
