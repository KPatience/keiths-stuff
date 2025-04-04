extends Node3D

signal track_grid_requested( fn: Callable)

@export_group("Environmental Obstacles")
@export var oil_scene: PackedScene = preload("res://Environmentals/oil_spill.tscn")
@export var test_obstacle_scene: PackedScene = preload("res://Track/Obstacles/test_obstacle.tscn")
@export var debug_marker_scene: PackedScene = preload("res://Debug/debug_marker.tscn")
@export var nuclear_sphere_obstacle: PackedScene = preload("res://Pickups/Collectibles/nuclear_collectible.tscn")
@onready var noise: FastNoiseLite = FastNoiseLite.new()

# TODO: scaling tracks offsets the ground
@export var grid_pos: Vector3 = Vector3.ZERO
@export var grid_size = Vector2.ZERO
var ground_height: float
var grid_scale: float


var cut_off_dist: float
var player_ref: CharacterBody3D

@onready var rand = RandomNumberGenerator.new()

func _ready() -> void:
	rand.randomize()

func set_grid(_grid: Vector4):
	# _grid: # e.g. (2.0, 0.1, 2.0, 7.0)
	grid_scale    = _grid.w
	grid_size.x   = grid_scale * _grid.x
	grid_size.y   = grid_scale * _grid.z
	ground_height = grid_scale * _grid.y / 2.0
	
	generate_obstacles(Vector3.ZERO)

func grid_pos_from_offset(offset: Vector3, grid_indices: Vector2):
	# -- tile pos + grid pos
	var pos = offset - Vector3(grid_size.x / 2, 0., grid_size.y / 2)
	pos += Vector3(grid_indices.x, ground_height, grid_indices.y)
	return pos


func make_an_obstacle(obstacle_instance: Node3D,
					  pos: Vector3,
					  obstacle_height: float,
					  height_offset=0):
	obstacle_instance.player_ref = player_ref
	obstacle_instance.cut_off_dist = cut_off_dist
	add_child(obstacle_instance)
	obstacle_instance.global_position = pos
	obstacle_instance.global_position.y = (height_offset + 1) * obstacle_height
	obstacle_instance.global_position.y += ground_height


func make_a_box(pos: Vector3, k_loop_height_offset=0):
	var box_instance = test_obstacle_scene.instantiate()
	make_an_obstacle(box_instance, pos, box_instance.get_node("MeshInstance3D").mesh.size.y, k_loop_height_offset)


func generate_obstacles(pos_offset: Vector3, noise_offset=0.0):
	# -- single big thing will test against a single random number on the grid
	# -- e.g. a single oil spill
	var rnd_big_x = rand.randi() % int(grid_size.x)
	var rnd_big_y = rand.randi() % int(grid_size.y)
	#print(rnd_big_x, ": ", rnd_big_x)
	for i in range(grid_size.x):
		for j in range( grid_size.y):
			# -- OIL SPILL
			if i == rnd_big_x and j == rnd_big_y:
				var oil = oil_scene.instantiate()
				var pos = grid_pos_from_offset(pos_offset, Vector2(i, j))
				make_an_obstacle(oil, pos, 0.)
				#var marker = debug_marker_scene.instantiate()
				#add_child(marker)
				#marker.global_position = pos
				continue
			# --
			var noise_sample = noise.get_noise_2d(i * 10. + noise_offset, j * 10. + noise_offset)
			if noise_sample > rand.randf():
				var pos = grid_pos_from_offset(pos_offset, Vector2(i, j))
				make_a_box( pos )
				#make_the_object( pos )
				for k in range(4):
					if noise.get_noise_1d( (i + j + k) * 10.0  + noise_offset) > 0.5 * rand.randf():
						var height_pos = Vector3(pos.x, k, pos.z)
						make_a_box( height_pos, k )
						#make_the_object( height_pos, k)
			else:
				if rand.randf() > 0.9:
					var pos = grid_pos_from_offset(pos_offset, Vector2(i, j))
					var nuclear_waste = nuclear_sphere_obstacle.instantiate()
					make_an_obstacle(nuclear_waste, pos, 0.5)



# ----------------- DELETE BUFFER
#func make_the_object(pos: Vector3, height_offset=0):
	#var box = test_obstacle_scene.instantiate()
	#box.player_ref = player_ref
	#box.cut_off_dist = cut_off_dist
	#add_child(box)
	#box.global_position = pos
	#box.global_position.y = (height_offset + 1) * box.get_node("MeshInstance3D").mesh.size.y
	#box.global_position.y += ground_height
