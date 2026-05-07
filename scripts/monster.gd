extends CharacterBody2D

@onready var animation = $AnimationPlayer
@onready var detection = $Detection
@onready var hurtbox = $Hurtbox
@onready var sprites = $AnimatedSprite2D

const SPEED = 15.0
const ATTACK_RANGE = 15.0
const ATTACK_COUNTDOWN = 0.5
const BASE_HP = 80.0;
const BASE_DAMAGE = 7.0;


var CURRENT_HP = BASE_HP;
var CURRENT_DAMAGE = BASE_DAMAGE;

var direction: Vector2 = Vector2.ZERO
var move_time = 0;

# Về tấn công
var target_list: Array = [];
var current_target = null;

# Về tấn công
var is_attack: bool = false;
var attack_timer = 0;

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# theo dõi radar
	detection.body_entered.connect(_on_body_entered);
	detection.body_exited.connect(_on_body_exited);
	# Kết nối hurtbox
	hurtbox.took_damage.connect(_on_took_dame);
	# lắng nghe hoạt ảnh tấn công kết thúc
	animation.animation_finished.connect(_on_attack_finished);


# ========================= CÁC PHƯƠNG THỨC HỖ TRỢ ================
# Khi có 1 đối tượng vào radar quan sát
func _on_body_entered(body):
	print("có thằng dô radar quái");
	if body == self:
		return;
	const ghost_enemies = [
		"warrior"
	]
	
	for enemy in ghost_enemies:
		if body.is_in_group(enemy):
			print("là kẻ địch")
			target_list.append(body);

# Khi có 1 đối tượng ra khỏi radar
func _on_body_exited(body):
	target_list.erase(body);

#lắng nghe sự kiện tấn công để reset lần đánh
func _on_attack_finished(animation):
	const animation_attacks = ["attack_right", "attack_left", "attack_up", "attack_down"];
	if animation_attacks.has(animation):
		attack_timer = ATTACK_COUNTDOWN;
		is_attack = false;

# Khi nhận dame
func _on_took_dame(amount):
	#flash_gain_dame(0.3)
	print("quái nhận dame: ", amount);

# Hiệu ứng nhận dame
func flash_gain_dame(time):
	# tạo tween để fade về màu gốc
	var tween = create_tween()
	tween.tween_property(animation, "modulate", Color(1, 1, 1, 1), time)\
		.from(Color(9.999, 2.375, 2.375, 1.0))  # giá trị > 1 = sáng hơn bình thường




# =============================== CÁC LOGIC CHÍNH ================
# tìm kẻ địch gần nhất
func get_closest_enemy(): 
	var closest = null;
	var min_dist = INF;
	
	
	for enemy in target_list:
		if !is_instance_valid(enemy):
			continue;
			
		var dist = global_position.distance_to(enemy.global_position)
		if dist < min_dist:
			min_dist = dist;
			closest = enemy;
	return closest;

func _physics_process(delta: float) -> void:
	
	# Kiểm tra mục tiêu hợp lệ
	if current_target == null or !is_instance_valid(current_target):
		current_target = get_closest_enemy();
	if current_target:
		var dist = global_position.distance_to(current_target.global_position);
		
		if dist > ATTACK_RANGE:
			direction = (current_target.global_position - global_position).normalized();
		else:
			direction = Vector2.ZERO;
			attack_timer -= delta;
			if attack_timer < 0 and !is_attack:
				start_attack();
	else:
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

func start_attack():
	is_attack = true;
	var attack_dir = (current_target.global_position - global_position).normalized();
	var animation_name: String;
	
	if abs(attack_dir.x) > abs(attack_dir.y):
		if attack_dir.x > 0:
			animation_name = "attack_right";
		else:
			animation_name = "attack_left";
	else:
		if attack_dir.y > 0:
			animation_name = "attack_down";
		else:
			animation_name = "attack_up";
	animation.play(animation_name)
	
	
	
func random_way():
	var x = randf_range(-1, 1);
	var y = randf_range(-1, 1);
	direction = Vector2(x, y).normalized();
	
	move_time = randf_range(2, 3);

func direction_sprite(direction: Vector2) -> void:
	if direction == Vector2.ZERO:
		return
	if is_attack:
		return;
	if direction.x > 0:
		sprites.play("move");
	else:
		sprites.play("move");
		
