extends Node2D

# 3 node con trong scene tree
@onready var tilemap: TileMapLayer = $TileMapLayer
@onready var camera: Camera2D = $Camera2D
#@onready var warrior: Node2D = $Warrior

var warrior_scene: PackedScene = preload("res://scenes/Warrior.tscn");
var map_rect: Rect2

# Khởi tạo dữ liệu thực thể
# WARRIOR
const MAX_WARRIOR = 3;
const SPAWN_TIMER = 5;
var warriors: Array = [];
var spawn_warrior_timer = SPAWN_TIMER;



func _ready() -> void:
	# Đọc kích thước map từ TileMapLayer
	_read_map_size();
	

func _process(delta: float) -> void:
	spawn_warrior_timer -= delta;
	if warriors.size() < MAX_WARRIOR and spawn_warrior_timer < 0:
		_spawn_warrior()
		

func _read_map_size() -> void:
	var used := tilemap.get_used_rect()           # vùng tile đang dùng (đơn vị: tile)
	var ts   := Vector2(tilemap.tile_set.tile_size) # kích thước 1 tile (đơn vị: pixel)
	map_rect = Rect2(
		Vector2(used.position) * ts,  # góc trên trái (pixel)
		Vector2(used.size) * ts       # chiều rộng/cao (pixel)
	)
	print("Map rect: ", map_rect)  # kiểm tra xem đúng chưa


func _spawn_warrior() -> void:
	warriors = warriors.filter(func(warrior): return is_instance_valid(warrior));
	
	if warriors.size() < MAX_WARRIOR:
		# lấy vị trí spawn ngẫu nhiên
		var x := randf_range(map_rect.position.x, map_rect.end.x);
		var y := randf_range(map_rect.position.y, map_rect.end.y);
		var pos = Vector2(x, y);
		if _is_position_blocked(pos):
			return;
		var w = warrior_scene.instantiate() # Khởi tạo warrior
		add_child(w)
		# thêm warrior mới vào danh sách
		warriors.append(w)
		w.global_position = pos
		
		# sau khi spawn 1 con thì thiết lặp lại thời gian spawn
		spawn_warrior_timer = SPAWN_TIMER;

func _is_position_blocked(pos: Vector2) -> bool:
	var space = get_world_2d().direct_space_state
	var params = PhysicsPointQueryParameters2D.new()
	params.position = pos
	params.collision_mask = 1  # layer collision của TileMapLayer (thường là layer 1)
	
	var result = space.intersect_point(params)
	return result.size() > 0  # true = có vật cản tại điểm đó
