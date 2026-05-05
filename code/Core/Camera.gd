extends Camera2D

@export_group("Système Visuel")
@export var lookahead_offset := 480.0

@export_group("Screen Shake")
@export var noise_frequency := 0.5
@export var noise_speed := 30.0

var noise := FastNoiseLite.new()
var shake_intensity := 0.0
var shake_duration := 0.0
var time := 0.0

func _ready() -> void:
	add_to_group("Camera")
	noise.seed = randi()
	noise.frequency = noise_frequency
	offset.x = lookahead_offset

func _process(delta: float) -> void:
	if shake_duration > 0:
		shake_duration -= delta
		time += delta * noise_speed
		
		var noise_x = noise.get_noise_2d(time, 0) * shake_intensity
		var noise_y = noise.get_noise_2d(0, time) * shake_intensity
		
		offset = Vector2(lookahead_offset + noise_x, noise_y)
	else:
		offset = offset.lerp(Vector2(lookahead_offset, 0), delta * 15.0)

func apply_shake(intensity: float, duration: float) -> void:
	shake_intensity = intensity
	shake_duration = duration
