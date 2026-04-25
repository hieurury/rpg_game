extends Node2D

@onready var bg = $BG
@onready var fill = $FILL


const BAR_WIDTH = 20.0;



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	bg.size = Vector2(BAR_WIDTH, 2);
	bg.color = Color(0.2, 0.2, 0.2)
	
	fill.size = Vector2(BAR_WIDTH, 2)
	fill.color = Color(1, 0, 0)  # đỏ
	
	var character = get_parent();
	character.hp_changed.connect(_on_hp_changed)

func _on_hp_changed(max_hp, current_hp):
	var ratio = current_hp / max_hp;
	fill.size.x = BAR_WIDTH * ratio;
	
