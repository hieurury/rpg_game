# Hitbox.gd - gắn vào node Hitbox (Area2D)
extends Area2D

func _ready():
	add_to_group("hitbox")
	# mặc định tắt
	$CollisionShape2D.disabled = true
