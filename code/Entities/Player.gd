extends CharacterBody2D

enum ShiftMode { RED, BLUE, YELLOW }

@export_group("Mouvement Rouge (Lourd)")
@export var red_jump_velocity := -1100.0
@export var red_gravity := 4500.0

@export_group("Mouvement Bleu (Fluide)")
@export var blue_jump_velocity := -850.0
@export var blue_gravity := 2200.0

@export_group("Mouvement Jaune (Céleste)")
@export var yellow_gravity := 4500.0

@export_group("Système")
@export var speed := 450.0
@export var reset_delay := 0.5
@export var transition_duration := 0.15
@export var death_particles_scene: PackedScene = preload("res://VFX/DeathParticles.tscn")

const MASK_WORLD := 1

const LAYER_LETHAL_RED := 4
const LAYER_LETHAL_BLUE := 8
const LAYER_LETHAL_YELLOW := 16

const LAYER_SOLID_RED := 32
const LAYER_SOLID_BLUE := 64
const LAYER_SOLID_YELLOW := 128

const LAYER_SOLID_UNIVERSAL := 256
const LAYER_LETHAL_UNIVERSAL := 512

const COLOR_RED_INNER := Color("#f44336")
const COLOR_RED_OUTER := Color("#b71c1c")
const COLOR_BLUE_INNER := Color("#2196f3")
const COLOR_BLUE_OUTER := Color("#0d47a1")
const COLOR_YELLOW_INNER := Color("#ffeb3b")
const COLOR_YELLOW_OUTER := Color("#fbc02d")

var current_mode := ShiftMode.RED
var is_dead := false
var color_tween: Tween

@onready var visual_inner: ColorRect = get_node_or_null("Visual_Inner")
@onready var visual_outer: ColorRect = get_node_or_null("Visual_Outer")
@onready var lethal_detector: Area2D = get_node_or_null("LethalDetector")

func _ready() -> void:
	assert(visual_inner != null, "Erreur : 'Visual_Inner' introuvable.")
	assert(visual_outer != null, "Erreur : 'Visual_Outer' introuvable.")
	assert(lethal_detector != null, "Erreur : 'LethalDetector' introuvable.")
	
	lethal_detector.body_entered.connect(_on_lethal_collision)
	lethal_detector.area_entered.connect(_on_lethal_collision)
	update_state(ShiftMode.RED, true)

func _physics_process(delta: float) -> void:
	if is_dead: return
	
	if lethal_detector.has_overlapping_areas() or lethal_detector.has_overlapping_bodies():
		die()
		
	apply_gravity(delta)
	handle_input()
	
	velocity.x = speed
	move_and_slide()
	
	handle_rotation(delta)

	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		
		if abs(collision.get_normal().x) > 0.8:

			var player_feet_threshold = global_position.y + 20.0 
			
			if collision.get_position().y < player_feet_threshold:
				die()

func apply_gravity(delta: float) -> void:
	match current_mode:
		ShiftMode.RED:
			velocity.y += red_gravity * delta
		ShiftMode.BLUE:
			var multiplier: float = 1.0
			if velocity.y < 0.0 and not Input.is_action_pressed("jump"):
				multiplier = 2.5
			velocity.y += blue_gravity * multiplier * delta
		ShiftMode.YELLOW:
			velocity.y -= yellow_gravity * delta

func handle_input() -> void:
	if Input.is_action_just_pressed("jump"):
		if is_on_floor() or is_on_ceiling():
			match current_mode:
				ShiftMode.RED: velocity.y = red_jump_velocity
				ShiftMode.BLUE: velocity.y = blue_jump_velocity
				ShiftMode.YELLOW: velocity.y = -red_jump_velocity
		elif current_mode == ShiftMode.RED:
			velocity.y = 2000.0
	
	if Input.is_action_just_pressed("shift"):
		toggle_shift()

func handle_rotation(delta: float) -> void:
	if not is_on_floor() and not is_on_ceiling():
		var current_jump: float = red_jump_velocity
		var current_grav: float = red_gravity
		
		match current_mode:
			ShiftMode.BLUE:
				current_jump = blue_jump_velocity
				current_grav = blue_gravity
			ShiftMode.YELLOW:
				current_jump = -red_jump_velocity
				current_grav = yellow_gravity
		
		var flight_time: float = 2.0 * abs(current_jump) / current_grav
		var rotation_speed: float = PI / flight_time
		
		visual_inner.rotation += rotation_speed * delta
		visual_outer.rotation += rotation_speed * delta
	else:
		var snapped_rotation: float = snapped(visual_inner.rotation, PI / 2.0)
		visual_inner.rotation = lerp_angle(visual_inner.rotation, snapped_rotation, delta * 25.0)
		visual_outer.rotation = lerp_angle(visual_outer.rotation, snapped_rotation, delta * 25.0)

func toggle_shift() -> void:
	var next_mode: int = (current_mode + 1) % 3
	update_state(next_mode as ShiftMode)

func update_state(new_mode: ShiftMode, instant := false) -> void:
	current_mode = new_mode
	
	up_direction = Vector2.DOWN if current_mode == ShiftMode.YELLOW else Vector2.UP
	
	var target_inner: Color
	var target_outer: Color
	
	match current_mode:
		ShiftMode.RED:
			target_inner = COLOR_RED_INNER
			target_outer = COLOR_RED_OUTER
		ShiftMode.BLUE:
			target_inner = COLOR_BLUE_INNER
			target_outer = COLOR_BLUE_OUTER
		ShiftMode.YELLOW:
			target_inner = COLOR_YELLOW_INNER
			target_outer = COLOR_YELLOW_OUTER
	
	if color_tween: color_tween.kill()
	
	if instant:
		visual_inner.color = target_inner
		visual_outer.color = target_outer
	else:
		color_tween = create_tween().set_parallel(true)
		color_tween.tween_property(visual_inner, "color", target_inner, transition_duration)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		color_tween.tween_property(visual_outer, "color", target_outer, transition_duration)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	match current_mode:
		ShiftMode.RED:
			lethal_detector.collision_mask = LAYER_LETHAL_UNIVERSAL | LAYER_LETHAL_BLUE | LAYER_LETHAL_YELLOW
			collision_mask = MASK_WORLD | LAYER_SOLID_UNIVERSAL | LAYER_SOLID_BLUE | LAYER_SOLID_YELLOW
		ShiftMode.BLUE:
			lethal_detector.collision_mask = LAYER_LETHAL_UNIVERSAL | LAYER_LETHAL_RED | LAYER_LETHAL_YELLOW
			collision_mask = MASK_WORLD | LAYER_SOLID_UNIVERSAL | LAYER_SOLID_RED | LAYER_SOLID_YELLOW
		ShiftMode.YELLOW:
			lethal_detector.collision_mask = LAYER_LETHAL_UNIVERSAL | LAYER_LETHAL_RED | LAYER_LETHAL_BLUE
			collision_mask = MASK_WORLD | LAYER_SOLID_UNIVERSAL | LAYER_SOLID_RED | LAYER_SOLID_BLUE

func _on_lethal_collision(_node: Node2D) -> void:
	if not is_dead: die()

func die() -> void:
	if is_dead: return 
	is_dead = true
	
	var tree := get_tree()
	if not tree: return

	set_physics_process(false)
	visual_inner.visible = false
	visual_outer.visible = false
	lethal_detector.set_deferred("monitoring", false)
	
	spawn_death_particles()
	trigger_screen_shake()

	await tree.create_timer(reset_delay).timeout

	if tree:
		tree.reload_current_scene()

func spawn_death_particles() -> void:
	if death_particles_scene:
		var particles := death_particles_scene.instantiate() as CPUParticles2D
		get_tree().current_scene.add_child(particles)
		particles.global_position = global_position
		particles.emitting = true
 
func trigger_screen_shake() -> void:
	get_tree().call_group("Camera", "apply_shake", 15.0, 0.3)
