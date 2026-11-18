extends Area2D
class_name Checkpoint

var activated: bool = false
var anim_timer: float = 0.0
var flame_node: ColorRect


func _ready() -> void:
	collision_layer = 8
	collision_mask = 0
	monitoring = false
	_build()


func _build() -> void:
	# Stone base
	var base: ColorRect = ColorRect.new()
	base.size = Vector2(20, 14)
	base.position = Vector2(-10, -14)
	base.color = Color(0.45, 0.42, 0.40)
	add_child(base)
	
	# Stone top
	var top: ColorRect = ColorRect.new()
	top.size = Vector2(24, 4)
	top.position = Vector2(-12, -18)
	top.color = Color(0.50, 0.48, 0.45)
	add_child(top)
	
	# Rune carving on stone
	var rune: ColorRect = ColorRect.new()
	rune.size = Vector2(6, 8)
	rune.position = Vector2(-3, -12)
	rune.color = Color(0.30, 0.28, 0.35)
	add_child(rune)
	
	# Flame (animated)
	flame_node = ColorRect.new()
	flame_node.size = Vector2(8, 12)
	flame_node.position = Vector2(-4, -34)
	flame_node.color = Color(1.0, 0.60, 0.10, 0.8)
	add_child(flame_node)
	
	# Flame core (bright)
	var core: ColorRect = ColorRect.new()
	core.size = Vector2(4, 6)
	core.position = Vector2(-2, -30)
	core.color = Color(1.0, 0.95, 0.60, 0.9)
	add_child(core)
	
	# Glow effect
	var glow: ColorRect = ColorRect.new()
	glow.size = Vector2(20, 20)
	glow.position = Vector2(-10, -38)
	glow.color = Color(1.0, 0.55, 0.15, 0.15)
	add_child(glow)


func _process(delta: float) -> void:
	anim_timer += delta
	
	# Animate flame
	if flame_node:
		var flicker: float = sin(anim_timer * 15.0) * 1.5 + sin(anim_timer * 23.0) * 0.8
		flame_node.size.y = 12 + flicker
		flame_node.position.y = -34 - flicker * 0.3
		var alpha: float = 0.7 + sin(anim_timer * 10.0) * 0.15
		flame_node.color.a = alpha
		
		# Color changes when activated
		if activated:
			flame_node.color.r = 0.30
			flame_node.color.g = 0.90
			flame_node.color.b = 0.30
		else:
			flame_node.color.r = 1.0
			flame_node.color.g = 0.60
			flame_node.color.b = 0.10


func interact() -> void:
	if activated:
		Game.log_message.emit("Checkpoint już aktywny.")
		return
	
	activated = true
	Game.set_checkpoint(global_position.x, global_position.y)
	
	# Visual feedback - brief flash
	var tween: Tween = create_tween()
	if flame_node:
		tween.tween_property(flame_node, "modulate:a", 1.0, 0.1)
		tween.tween_property(flame_node, "modulate:a", 0.8, 0.3)


func persist() -> void:
	pass
