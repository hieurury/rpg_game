extends CharacterBody2D

@onready var sprites = $AnimatedSprite2D
@onready var detection_arena = $DetectionArena
@onready var animationPlayer = $AnimationPlayer
@onready var hurtbox = $Hurtbox
@onready var hitbox = $Hitbox


# Thông số cơ bản
const DAMAGE = 10.0
const HP = 100.0
const SPEED = 20.0
const ATTACK_RANGE = 20.0
const ATTACK_COUNTDOWN = 0.4

# Chỉ số có thể biến đổi
var CURRENT_HP = HP;


# Di chuyển
var latest_direction: Vector2 = Vector2.ZERO
var change_time = 0;
var direction: Vector2 = Vector2.ZERO;

# mục tiêu tấn công
var target_list: Array = [];
var current_target = null;

# attack
var is_attack = false;
var attack_timer = 0.0;


# signal
#khi hp đổi
signal hp_changed(max_hp, current_hp)

# Quét các mục tiêu trong và ngoài phạm vi
func _ready() -> void:
	detection_arena.body_entered.connect(_on_body_entered);
	detection_arena.body_exited.connect(_on_body_exited);
	
	# xác định thời gian hoàn thành animation
	animationPlayer.animation_finished.connect(_on_attack_finished);
	# Kết nối hurtbox
	hurtbox.took_damage.connect(_on_took_damage);
	hurtbox.countdown_time.connect(flash);
	# đặt hp bar
	#bắn signal cho HPbar để khởi tạo
	emit_signal("hp_changed", HP, CURRENT_HP);
	

func _on_attack_finished(anim_name: StringName):
	const attack_list = ["attack_left", "attack_down", "attack_up"];
	if attack_list.has(anim_name):
		is_attack = false;
		attack_timer = ATTACK_COUNTDOWN;

# Thêm các mục tiêu trong phạm vi vào danh sách
func _on_body_entered(body):
	if body == self:
		return
	if !body.is_in_group("warrior"):
		return
	
	target_list.append(body)

# loại bỏ các mục tiêu ngoài phạm vi
func _on_body_exited(body):
	target_list.erase(body)
	

func _on_took_damage(amount):
	# xử lý máu ở đây
	print("nhận damage: ", amount)
	CURRENT_HP -= amount;
	# dính dame hả? Dính thì bắn signal cho HPbar biết
	emit_signal("hp_changed", HP, CURRENT_HP);
	if CURRENT_HP <= 0:
		print("die");
		queue_free();
		

func flash(time):
	# sáng trắng lên
	sprites.modulate = Color(1, 1, 1, 1)  # trắng
	
	# tạo tween để fade về màu gốc
	var tween = create_tween()
	tween.tween_property(sprites, "modulate", Color(1, 1, 1, 1), time)\
		.from(Color(10, 10, 10, 1))  # giá trị > 1 = sáng hơn bình thường

# tìm mục tiêu gần nhất
func get_closest_target():
	var closest = null;
	var min_dist = INF;
	
	for target in target_list:
		# coi nó có tồn tại không
		if !is_instance_valid(target):
			continue;
		var dist = global_position.distance_to(target.global_position);
		
		if dist < min_dist:
			min_dist = dist;
			closest = target;
	
	return closest;
	
func _physics_process(delta: float) -> void:
	
	# phân chia logic giữa đi đến mục tiêu và đi ngẫu hứng
	#Nếu không có mục tiêu hoặc mục tiêu đó không tồn tại thì tìm thằng mới
	if current_target == null or !is_instance_valid(current_target):
		current_target = get_closest_target();
		
	if current_target:
		# lấy khoảng cách đến mục tiêu
		var dist = global_position.distance_to(current_target.global_position);
		
		# xác định xem mục tiêu đã đến tầm tấn công chưa
		# nếu chưa đến thì đi lại nó
		if dist > ATTACK_RANGE:
			direction = (current_target.global_position - global_position).normalized();
		else:
			# cho dừng lại
			direction = Vector2.ZERO;
			# tính thời gian tấn công dựa vào countdown (tốc đánh)
			attack_timer -= delta;
			if attack_timer <= 0 and !is_attack:
				start_attack();
				
		
	# Nếu không có mục tiêu thì di chuyển ngẫu nhiên trên map
	else:
		change_time -= delta;
		# khi điếm ngược về 0 thì di chuyển ngẫu nhiên
		if change_time < 0:
			random_way();
	
	if direction:
		velocity = direction * SPEED
		latest_direction = velocity;
	else:
		velocity = velocity.move_toward(Vector2.ZERO, SPEED);
	
	if !is_attack:
		direction_sprite(direction);
	move_and_slide()
	
	# khi di chuyển, nếu gặp vật cản thì đổi hướng
	if get_slide_collision_count() > 0:
		random_way();

func random_way() -> void:
	var randomX = randf_range(-1, 1);
	var randomY = randf_range(-1, 1);
	direction = Vector2(randomX, randomY).normalized();
	# dat lai thoi gian di chuyen
	change_time = randf_range(2, 3);

func start_attack():
	is_attack = true
	var attack_dir = (current_target.global_position - global_position).normalized();
	var animation_name: String = "";
	
	
	if abs(attack_dir.x) > abs(attack_dir.y):
		animation_name = "attack_left";
		if attack_dir.x > 0:
			sprites.flip_h = true;
			hitbox.position.x = abs(hitbox.position.x);
		else:
			sprites.flip_h = false;
			hitbox.position.x = -abs(hitbox.position.x);
	elif attack_dir.y > 0:
		animation_name = "attack_down";
	else:
		animation_name = "attack_up";
	
	animationPlayer.play(animation_name);
	sprites.play(animation_name);

func direction_sprite(direction: Vector2) -> void:
	# can xac dinh xem co dang di chuyen khong da
	if is_attack:
		return;
		
	if direction == Vector2.ZERO:
		if abs(latest_direction.x) > abs(latest_direction.y):
			# di ngang
			sprites.play("idle_left");
			if latest_direction.x > 0:
				sprites.flip_h = true;
			else:
				sprites.flip_h = false;
		else:
			if latest_direction.y > 0:
				sprites.play("idle_down");
			else:
				sprites.play("idle_up");
	else:
		if abs(direction.x) > abs(direction.y):
			# di ngang
			sprites.play("move_left");
			if direction.x > 0:
				sprites.flip_h = true;
			else:
				sprites.flip_h = false;
		else:
			if direction.y > 0:
				sprites.play("move_down");
			else:
				sprites.play("move_up");
