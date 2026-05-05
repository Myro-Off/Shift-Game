@tool
extends StaticBody2D

enum ShiftColor { RED, BLUE, YELLOW, UNIVERSAL }

@export_group("Configuration Bicolore")
@export var color_left: ShiftColor = ShiftColor.RED:
	set(value):
		color_left = value
		_update_visuals()

@export var color_right: ShiftColor = ShiftColor.BLUE:
	set(value):
		color_right = value
		_update_visuals()

const L_SOLID := { "RED": 32, "BLUE": 64, "YELLOW": 128, "UNIVERSAL": 256 }
const COLORS := { 
	"RED": Color("#f44336"), 
	"BLUE": Color("#2196f3"), 
	"YELLOW": Color("#ffeb3b"), 
	"UNIVERSAL": Color("#e0e0e0") 
}

@onready var detector: Area2D = get_node_or_null("ApproachDetector")
@onready var visual_left: ColorRect = get_node_or_null("VisualLeft")
@onready var visual_right: ColorRect = get_node_or_null("VisualRight")

func _ready() -> void:
	_update_visuals()
	
	if Engine.is_editor_hint(): 
		return
		
	assert(detector != null, "Erreur fatale : 'ApproachDetector' manquant sur " + name)
	detector.body_entered.connect(_on_approach)
	detector.body_exited.connect(_on_approach_exit)
	
	collision_layer = 0

func _update_visuals() -> void:
	var left_key = ShiftColor.keys()[color_left]
	var right_key = ShiftColor.keys()[color_right]
	
	if visual_left: 
		visual_left.modulate = COLORS[left_key]
	if visual_right: 
		visual_right.modulate = COLORS[right_key]

func _on_approach(body: Node2D) -> void:
	if body.is_in_group("Player"):
		var local_body_pos := to_local(body.global_position)
		var is_left := local_body_pos.x < 0.0
		var active_color_idx: int = color_left if is_left else color_right
		var color_key = ShiftColor.keys()[active_color_idx]
		
		var target_layer = L_SOLID[color_key]
		set_deferred("collision_layer", target_layer)

func _on_approach_exit(body: Node2D) -> void:
	if body.is_in_group("Player"):
		set_deferred("collision_layer", 0)
