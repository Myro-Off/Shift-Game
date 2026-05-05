extends Node2D

@export_group("Configuration")
@export var start_sequence: Array[PackedScene]
@export var random_chunk_scenes: Array[PackedScene]
@export var initial_random_chunks := 2

@export_group("Joueur")
@export var player_path: NodePath
@export_range(0.0, 1.0) var spawn_ratio := 0.5

var last_chunk_end_position := Vector2.ZERO
var spawned_chunks: Array[Node2D] = []
var player: Node2D

func _ready() -> void:
	player = get_node_or_null(player_path)
	
	for scene in start_sequence:
		spawn_specific_chunk(scene)
		
	for i in range(initial_random_chunks):
		spawn_random_chunk()
		
	align_player_start()

func _process(_delta: float) -> void:
	if not is_instance_valid(player): return
	
	var screen_margin := get_viewport_rect().size.x * 1.5 
	
	if player.global_position.x > last_chunk_end_position.x - screen_margin:
		spawn_random_chunk()
		clean_old_chunks()

func spawn_specific_chunk(scene: PackedScene) -> void:
	if not scene: return
		
	var chunk := scene.instantiate() as Node2D
	add_child(chunk)
	chunk.global_position = last_chunk_end_position
	
	var end_marker := chunk.get_node_or_null("EndPosition") as Marker2D
	if end_marker:
		last_chunk_end_position = end_marker.global_position
	else:
		push_error("LevelManager: EndPosition manquant sur " + chunk.name)
		
	spawned_chunks.append(chunk)

func spawn_random_chunk() -> void:
	if random_chunk_scenes.is_empty(): return
	var random_index := randi() % random_chunk_scenes.size()
	spawn_specific_chunk(random_chunk_scenes[random_index])

func clean_old_chunks() -> void:
	var max_chunks := start_sequence.size() + initial_random_chunks + 2
	if spawned_chunks.size() > max_chunks:
		var old_chunk: Node2D = spawned_chunks.pop_front() as Node2D
		if is_instance_valid(old_chunk):
			old_chunk.queue_free()

func align_player_start() -> void:
	if not is_instance_valid(player) or spawned_chunks.is_empty(): return
	
	var first_chunk = spawned_chunks[0]
	var end_marker = first_chunk.get_node_or_null("EndPosition") as Marker2D
	
	if end_marker:
		var chunk_length = end_marker.position.x
		player.global_position.x = first_chunk.global_position.x + (chunk_length * spawn_ratio)
