extends Label
@onready var lv_label = $"."
const LABEL_SCALE = 0.3
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var character = get_parent();
	lv_label.scale = Vector2(LABEL_SCALE, LABEL_SCALE);
	lv_label.position = Vector2(-10, -22)
	# lấy lv
	character.lv_changed.connect(_on_lv_changed);


func _on_lv_changed(lv):
	lv_label.text = "LV." + str(lv);
