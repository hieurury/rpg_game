extends CharacterBody2D

@onready var sprites = $AnimatedSprite2D
@onready var detection_arena = $DetectionArena
@onready var animationPlayer = $AnimationPlayer
@onready var hurtbox = $Hurtbox
@onready var hitbox = $Hitbox


# Thông số cơ bản
var BASE_DAMAGE = 10.0 # sát thương cơ bản
const BASE_HP = 100.0 # HP cơ bản
const SPEED = 20.0 # tốc độ di chuyển
const ATTACK_RANGE = 20.0 # Tầm đánh
const ATTACK_COUNTDOWN = 0.4 # tốc đánh
const PERCENT_HP_RECOVERY = 10 # Hồi hp khi không bị tấn công

# Chỉ số có thể biến đổi
var LEVEL;
var MAX_HP = BASE_HP;
var CURRENT_HP = BASE_HP;
var CURRENT_DAMAGE = BASE_DAMAGE;


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

# Các biến timer
var recovery_timer = 3;


# signal
#khi hp đổi
signal hp_changed(max_hp, current_hp);
signal lv_changed(lv);
signal is_death();

# Quét các mục tiêu trong và ngoài phạm vi
func _ready() -> void:
	detection_arena.body_entered.connect(_on_body_entered);
	detection_arena.body_exited.connect(_on_body_exited);
	
	# xác định thời gian hoàn thành animation
	animationPlayer.animation_finished.connect(_on_attack_finished);
	# Kết nối hurtbox
	hurtbox.took_damage.connect(_on_took_damage);
	hurtbox.countdown_time.connect(flash_gain_dame);
	# Khởi tạo lại chỉ số theo lv
	# Khởi tạo lv ngẫu nhiên
	LEVEL = randi_range(1, 5);
	MAX_HP = BASE_HP * (1 + LEVEL * 0.25)
	CURRENT_DAMAGE = BASE_DAMAGE * (1 + LEVEL * 0.2)
	CURRENT_HP = MAX_HP;
	# đặt hp bar
	#bắn signal cho HPbar để khởi tạo
	emit_signal("hp_changed", MAX_HP, CURRENT_HP);
	#bắn signal lv lần đầu
	emit_signal("lv_changed", LEVEL);
	
	

# ================================= CÁC HÀM HỖ TRỢ CHO CÁC CHỨC NĂNG ================
# lắng nghe animation kết thúc
func _on_attack_finished(anim_name: StringName):
	# các animation cần lắng nghe
	const attack_list = ["attack_left", "attack_right", "attack_down", "attack_up"];
	if attack_list.has(anim_name):
		is_attack = false;
		# đặt lại thời gian tấn công khi tấn công xong 1 lần
		attack_timer = ATTACK_COUNTDOWN;

# Thêm các mục tiêu trong phạm vi vào danh sách
func _on_body_entered(body):
	# không đánh bản thân
	if body == self:
		return
	# mục tiêu cần đánh
	const warrior_enemies: Array = [
		"archer",
		"magie",
		"monster"
	]
	for enemy in warrior_enemies:
		if body.is_in_group(enemy):
			target_list.append(body)

	

# loại bỏ các mục tiêu ngoài phạm vi
func _on_body_exited(body):
	target_list.erase(body)
	

func _on_took_damage(amount):
	# xử lý máu ở đây
	print("nhận damage: ", amount)
	CURRENT_HP -= amount;
	# dính dame hả? Dính thì bắn signal cho HPbar biết
	emit_signal("hp_changed", MAX_HP, CURRENT_HP);
	
	# điều kiện cook
	if CURRENT_HP <= 0:
		print("die");
		queue_free();
		emit_signal("is_death");
		

#khi nhận exp thay đổi
func _on_gain_exp():
	# muốn exp gì đó thì ở đây
	emit_signal("lv_changed", LEVEL);


func flash_gain_dame(time):
	# sáng đỏ lên
	sprites.modulate = Color(1.0, 0.29, 0.29, 1.0)  # trắng
	
	# tạo tween để fade về màu gốc
	var tween = create_tween()
	tween.tween_property(sprites, "modulate", Color(1, 1, 1, 1), time)\
		.from(Color(9.999, 2.375, 2.375, 1.0))  # giá trị > 1 = sáng hơn bình thường

func flash_recovery(time):
	# sáng đỏ lên
	sprites.modulate = Color(0.223, 0.69, 0.32, 1.0)  # trắng
	
	# tạo tween để fade về màu gốc
	var tween = create_tween()
	tween.tween_property(sprites, "modulate", Color(1, 1, 1, 1), time)\
		.from(Color(0.602, 1.042, 0.481, 1.0))  # giá trị > 1 = sáng hơn bình thường

# ===================== CÁC HÀM LIÊN QUAN ĐẾN LOGIC CHÍNH CỦA NHÂN VẬT ==========================
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
	# Khi đánh thì không làm gì cả, chỉ đánh thôi
	if is_attack:
		velocity = Vector2.ZERO
		move_and_slide()
		return
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
		
		# Hồi phục hp theo thời gian
		if !is_attack:
			recovery_timer -= delta
			if recovery_timer < 0:
				nature_hp_recovery(PERCENT_HP_RECOVERY);
		# khi điếm ngược về 0 thì di chuyển ngẫu nhiên
		if change_time < 0:
			random_way();
	
	# Nhận được hướng di chuyển, thì cứ đi thôi
	if direction:
		velocity = direction * SPEED
		latest_direction = velocity;
	else: # Không nhận được hướng di chuyển -> đứng yên
		velocity = velocity.move_toward(Vector2.ZERO, SPEED);
		
	
	if !is_attack:
		direction_sprite(direction);
	move_and_slide()
	
	# khi di chuyển, nếu gặp vật cản thì đổi hướng
	if get_slide_collision_count() > 0:
		random_way();

# HÀM XÁC ĐỊNH HƯỚNG DI CHUYỂN NGẪU NHIÊN
func random_way() -> void:
	var randomX = randf_range(-1, 1);
	var randomY = randf_range(-1, 1);
	direction = Vector2(randomX, randomY).normalized();
	# dat lai thoi gian di chuyen
	change_time = randf_range(2, 3);

# HÀM THỰC HIỆN TẤN CÔNG
func start_attack():
	is_attack = true
	var attack_dir = (current_target.global_position - global_position).normalized();
	var animation_name: String = "";
	
	
	if abs(attack_dir.x) > abs(attack_dir.y):
		if attack_dir.x > 0:
			animation_name = "attack_right";
		else:
			animation_name = "attack_left";
	elif attack_dir.y > 0:
		animation_name = "attack_down";
	else:
		animation_name = "attack_up";
	
	animationPlayer.play(animation_name);
	sprites.play(animation_name);

# HÀM XÁC ĐỊNH SPRITE CẦN CHO DI CHUYỂN
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

# HỒI HP TỰ NHIÊN
func nature_hp_recovery(hp_recovery: float) -> void:
	if CURRENT_HP >= MAX_HP:
		return;
	CURRENT_HP += CURRENT_HP / 100 * hp_recovery;
	flash_recovery(0.3);
	recovery_timer = 3;
	if CURRENT_HP > MAX_HP:
		CURRENT_HP = MAX_HP;
	emit_signal("hp_changed", MAX_HP, CURRENT_HP);
