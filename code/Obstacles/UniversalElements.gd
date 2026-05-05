@tool
extends StaticBody2D

enum ShiftColor { RED, BLUE, YELLOW, UNIVERSAL }
enum ElementType { BLOCK, SPIKE }

enum AnimMode { ONE_SHOT, INFINITE_IN_OUT, INFINITE_IN }
enum TriggerMode { ALWAYS_ACTIVE, DISTANCE }

@export_group("Configuration")
@export var element_type: ElementType = ElementType.BLOCK:
	set(value):
		element_type = value
		_update_properties()

@export var element_color: ShiftColor = ShiftColor.RED:
	set(value):
		element_color = value
		_update_properties()

@export var is_lethal: bool = false:
	set(value):
		is_lethal = value
		_update_properties()

@export_group("Animation")
@export var anim_active: bool = false:
	set(value):
		anim_active = value
		_update_properties()

@export_subgroup("Configuration Anim")
@export var anim_mode: AnimMode = AnimMode.INFINITE_IN_OUT:
	set(value):
		anim_mode = value
		_update_properties()
@export var anim_trigger: TriggerMode = TriggerMode.ALWAYS_ACTIVE:
	set(value):
		anim_trigger = value
		_update_properties()
@export var anim_trigger_distance: float = 1200.0:
	set(value):
		anim_trigger_distance = value
		_update_properties()

@export_subgroup("Transformations")
@export var anim_translation: Vector2 = Vector2.ZERO:
	set(value):
		anim_translation = value
		_update_properties()
@export var anim_rotation_deg: float = 0.0:
	set(value):
		anim_rotation_deg = value
		_update_properties()

@export_subgroup("Temps & Synchro")
@export var anim_duration: float = 2.0:
	set(value):
		anim_duration = value
		_update_properties()
@export var anim_delay: float = 0.0:
	set(value):
		anim_delay = value
		_update_properties()
@export var anim_global_offset: float = 0.0:
	set(value):
		anim_global_offset = value
		_update_properties()

const L_LETHAL := { RED = 4, BLUE = 8, YELLOW = 16, UNIVERSAL = 512 }
const L_SOLID := { RED = 32, BLUE = 64, YELLOW = 128, UNIVERSAL = 256 }
const COLORS := { RED = Color("#f44336"), BLUE = Color("#2196f3"), YELLOW = Color("#ffeb3b"), UNIVERSAL = Color("#e0e0e0") }

func _ready() -> void:
	_update_properties()

func _update_properties() -> void:
	var is_block: bool = (element_type == ElementType.BLOCK)
	var color_key: String = ShiftColor.keys()[element_color]
	
	var v_block = get_node_or_null("VisualBlock")
	var v_spike = get_node_or_null("VisualSpike")
	if v_block: 
		v_block.visible = is_block
		v_block.modulate = COLORS[color_key]
	if v_spike: 
		v_spike.visible = not is_block
		v_spike.modulate = COLORS[color_key]

	var c_block = get_node_or_null("CollisionBlock")
	var c_spike = get_node_or_null("CollisionSpike")
	if c_block: c_block.set_deferred("disabled", not is_block)
	if c_spike: c_spike.set_deferred("disabled", is_block)

	collision_layer = 0
	if is_lethal: collision_layer = L_LETHAL[color_key]
	else: collision_layer = L_SOLID[color_key]

	var animator = get_node_or_null("AnimatorComponent")
	
	if animator:
		if "is_enabled" in animator: 
			animator.is_enabled = anim_active
			animator.mode = anim_mode
			animator.trigger = anim_trigger
			animator.trigger_distance = anim_trigger_distance
			animator.target_translation = anim_translation
			animator.target_rotation_deg = anim_rotation_deg
			animator.duration = anim_duration
			animator.interval_delay = anim_delay
			animator.global_time_offset = anim_global_offset
			
			if animator.has_method("setup"):
				animator.setup()
