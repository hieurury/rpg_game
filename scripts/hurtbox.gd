# Hurtbox.gd - gắn vào node Hurtbox (Area2D)
extends Area2D

signal took_damage(amount);
signal countdown_time(time);

const COUNTDOWN_TIME = 0.3;
var countdown_damge_time = 0.0;

func _ready():
	area_entered.connect(_on_area_entered)


# chạy tiến trình mỗi frame
func _process(delta: float) -> void:
	if countdown_damge_time > 0:
		countdown_damge_time -= delta;

# Nâng cao hơn về nhận dame
# 1. Không nhận dame chính mình
# 2. Không nhận dame ngoài hitbox
# 3. Không nhận dame liên tục, sẽ có thời gian countdown
func _on_area_entered(area):
	print("dô đây")
	if !area.is_in_group("hitbox"):
		return;
	if area.get_parent() == get_parent():
		return;
	if countdown_damge_time > 0:
		return;
	print("gây được dame")
	countdown_damge_time = COUNTDOWN_TIME;
	var damage = area.get_parent().DAMAGE  # lấy damage từ kẻ tấn công
	emit_signal("took_damage", damage)
	emit_signal("countdown_time", COUNTDOWN_TIME);
