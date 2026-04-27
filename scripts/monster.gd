extends CharacterBody2D

@onready var animation = $AnimationPlayer

const SPEED = 15.0

var direction: Vector2 = Vector2.ZERO
var move_time = 0;

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func _physics_process(delta: float) -> void:
	move_time -= delta;
	if move_time < 0:
		random_way()
	
	if direction:
		velocity = direction * SPEED;
	else:
		velocity = velocity.move_toward(Vector2.ZERO, SPEED);
	direction_sprite(direction);
	move_and_slide();
	
	# khi di chuyển, nếu gặp vật cản thì đổi hướng
	if get_slide_collision_count() > 0:
		random_way();

func random_way():
	var x = randf_range(-1, 1);
	var y = randf_range(-1, 1);
	direction = Vector2(x, y).normalized();
	
	move_time = randf_range(2, 3);

func direction_sprite(direction: Vector2) -> void:
	if direction == Vector2.ZERO:
		return
	if direction.x > 0:
		animation.play("move_right");
	else:
		animation.play("move_left");
		
