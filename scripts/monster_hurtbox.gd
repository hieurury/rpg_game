extends Area2D

signal took_damage(amount);

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	area_entered.connect(_on_took_damage);


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_took_damage(arena):
	print("test")
	# kiểm tra tính hợp lệ của đối tượng gây dame
	if arena.get_parent() == get_parent():
		return;
	if !arena.is_in_group("hitbox"):
		return;
	if arena.get_parent().is_in_group("monster"):
		return;
	
	var dame = arena.get_parent().CURRENT_DAMAGE;
	emit_signal("took_damage", dame);
