@tool
class_name AnimatorComponent
extends Node

enum AnimMode { ONE_SHOT, INFINITE_IN_OUT, INFINITE_IN }
enum TriggerMode { ALWAYS_ACTIVE, DISTANCE }

var mode: int = 1
var trigger: int = 0
var trigger_distance := 1200.0
var target_rotation_deg := 0.0
var target_translation := Vector2.ZERO
var duration := 2.0
var interval_delay := 0.0
var global_time_offset := 0.0
var is_enabled := false

var is_triggered := false
var has_triggered := false
var start_pos := Vector2.ZERO
var start_rot := 0.0
var initial_captured := false

@onready var parent: Node2D = get_parent() as Node2D
var player: Node2D = null

func _ready() -> void:
	if not Engine.is_editor_hint():
		setup()

func setup() -> void:
	if not parent: parent = get_parent() as Node2D
	
	if parent and not initial_captured:
		start_pos = parent.position
		start_rot = parent.rotation_degrees
		initial_captured = true
	
	is_triggered = (trigger == TriggerMode.ALWAYS_ACTIVE)
	has_triggered = false

func _process(_delta: float) -> void:
	if Engine.is_editor_hint(): return
	
	if not is_enabled or not parent: return
	
	if not is_triggered and trigger == TriggerMode.DISTANCE:
		_check_distance()
	
	if is_triggered:
		if mode == AnimMode.ONE_SHOT:
			if not has_triggered:
				_execute_one_shot()
		else:
			_process_infinite_animation()

func _check_distance() -> void:
	if not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("Player") as Node2D
	
	if player:
		var dist: float = parent.global_position.distance_to(player.global_position)
		if dist <= trigger_distance:
			is_triggered = true

func _execute_one_shot() -> void:
	has_triggered = true
	var tw := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.set_parallel(true)
	
	if target_rotation_deg != 0.0:
		tw.tween_property(parent, "rotation_degrees", start_rot + target_rotation_deg, duration)
	
	if target_translation != Vector2.ZERO:
		tw.tween_property(parent, "position", start_pos + target_translation, duration)

func _process_infinite_animation() -> void:
	var current_time: float = (Time.get_ticks_msec() / 1000.0) + global_time_offset
	var cycle_duration: float = duration + interval_delay
	var progress: float = fmod(current_time, cycle_duration)
	
	if progress > duration:
		return
		
	var factor: float = 0.0
	var t: float = progress / duration
	
	if mode == AnimMode.INFINITE_IN_OUT:
		factor = (sin(t * 2.0 * PI - (PI / 2.0)) + 1.0) / 2.0
	elif mode == AnimMode.INFINITE_IN:
		factor = t
		
	parent.rotation_degrees = lerp(start_rot, start_rot + target_rotation_deg, factor)
	parent.position = start_pos.lerp(start_pos + target_translation, factor)
