# Hitbox.gd - gắn vào node Hitbox (Area2D)
extends Area2D
@onready var hitbox = $CollisionShape2D

func _ready():
	add_to_group("hitbox")
	# mặc định tắt
	hitbox.disabled = true
