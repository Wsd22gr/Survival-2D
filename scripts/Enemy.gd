extends CharacterBody2D
class_name Enemy

signal died(enemy: Enemy, drops: Array, xp_amount: int)

var etype: String = "slime"
var max_hp: float = 30.0
var hp: float = 30.0
var power: int = 10
var damage: int = 8
var speed: float = 70.0
var xp_reward: int = 8
var is_boss: bool = false
var boss_key: String = ""
var chunk_index: int = 0
var ent_ref: Dictionary = {}
var attack_cd: float = 0.0
var flash: float = 0.0
var facing: int = -1
var label: Label
var bar: ColorRect
var bar_bg: ColorRect
var vis: Node2D

# Animation
var anim_timer: float = 0.0
var bounce_timer: float = 0.0
var is_moving: bool = false
var body_node: ColorRect
var eye_left: ColorRect
var eye_right: ColorRect
var mouth: ColorRect
var attack_anim: float = 0.0
var pulse_timer: float = 0.0
var jump_timer: float = 0.0
var can_jump: bool = true


func setup(kind: String, cindex: int, ent: Dictionary, boss: bool) -> void:
	etype = kind
	chunk_index = cindex
	ent_ref = ent
	is_boss = boss
	boss_key = str(ent.get("boss_key", ""))
	collision_layer = 4
	collision_mask = 1
	_stats_from_type()
	_build()


func _stats_from_type() -> void:
	var dist: int = absi(chunk_index * Game.CHUNK_TILES)
	match etype:
		"slime":
			max_hp = 22 + dist / 400.0
			power = 8 + dist / 500
			damage = 6
			speed = 55
			xp_reward = 6
		"goblin":
			max_hp = 34 + dist / 280.0
			power = 14 + dist / 380
			damage = 9
			speed = 85
			xp_reward = 10
		"wolf":
			max_hp = 40 + dist / 250.0
			power = 18 + dist / 320
			damage = 12
			speed = 110
			xp_reward = 14
		"skeleton":
			max_hp = 55 + dist / 200.0
			power = 24 + dist / 260
			damage = 14
			speed = 80
			xp_reward = 18
		"brute":
			max_hp = 90 + dist / 160.0
			power = 32 + dist / 200
			damage = 18
			speed = 60
			xp_reward = 26
		"boss":
			max_hp = 420 + dist / 40.0
			power = 80 + dist / 80
			damage = 28
			speed = 95
			xp_reward = 120
		"mega_boss":
			max_hp = 1200 + dist / 20.0
			power = 120 + dist / 50
			damage = 40
			speed = 130
			xp_reward = 300
	hp = max_hp


func _build() -> void:
	var shape: CollisionShape2D = CollisionShape2D.new()
	var rect: RectangleShape2D = RectangleShape2D.new()
	var w: float = 22.0 if not is_boss else 48.0
	var h: float = 22.0 if not is_boss else 52.0
	rect.size = Vector2(w, h)
	shape.shape = rect
	shape.position = Vector2(0, -h * 0.5)
	add_child(shape)

	vis = Node2D.new()
	add_child(vis)
	
	# Build different visuals per enemy type
	_build_body(w, h)
	_build_face(w, h)
	
	if is_boss:
		var crown: ColorRect = ColorRect.new()
		crown.size = Vector2(20, 8)
		crown.position = Vector2(-10, -h - 8)
		crown.color = Color(0.95, 0.8, 0.15)
		vis.add_child(crown)
		# Boss horns
		for side in [-1, 1]:
			var horn: ColorRect = ColorRect.new()
			horn.size = Vector2(4, 12)
			horn.position = Vector2(side * 18, -h - 12)
			horn.color = Color(0.20, 0.10, 0.10)
			vis.add_child(horn)

	var hitbox: Area2D = Area2D.new()
	hitbox.collision_layer = 4
	hitbox.collision_mask = 2
	var hs: CollisionShape2D = CollisionShape2D.new()
	var hr: RectangleShape2D = RectangleShape2D.new()
	hr.size = Vector2(w + 4, h)
	hs.shape = hr
	hs.position = Vector2(0, -h * 0.5)
	hitbox.add_child(hs)
	hitbox.body_entered.connect(_on_touch_player)
	add_child(hitbox)

	bar_bg = ColorRect.new()
	bar_bg.size = Vector2(36 if not is_boss else 70, 5)
	bar_bg.color = Color(0.1, 0.1, 0.1, 0.8)
	bar_bg.position = Vector2(-bar_bg.size.x * 0.5, -h - 22)
	add_child(bar_bg)
	bar = ColorRect.new()
	bar.size = bar_bg.size
	bar.color = Color(0.85, 0.15, 0.12)
	bar.position = bar_bg.position
	add_child(bar)
	label = Label.new()
	label.position = Vector2(-28, -h - 40)
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", Color(1, 0.92, 0.35))
	add_child(label)
	_refresh_bars()


func _build_body(w: float, h: float) -> void:
	body_node = ColorRect.new()
	body_node.name = "Body"
	body_node.size = Vector2(w, h)
	body_node.position = Vector2(-w * 0.5, -h)
	body_node.color = _color()
	vis.add_child(body_node)
	
	# Type-specific body details
	match etype:
		"slime":
			# Slime - rounded look with highlight
			var highlight: ColorRect = ColorRect.new()
			highlight.size = Vector2(w * 0.3, h * 0.15)
			highlight.position = Vector2(-w * 0.15, -h * 0.85)
			highlight.color = Color(1.0, 1.0, 1.0, 0.35)
			vis.add_child(highlight)
			# Dark spot
			var spot: ColorRect = ColorRect.new()
			spot.size = Vector2(w * 0.2, h * 0.15)
			spot.position = Vector2(w * 0.1, -h * 0.55)
			spot.color = Color(0.20, 0.60, 0.18)
			vis.add_child(spot)
		"goblin":
			# Goblin - ears
			for side in [-1, 1]:
				var ear: ColorRect = ColorRect.new()
				ear.size = Vector2(4, 8)
				ear.position = Vector2(side * (w * 0.45), -h - 4)
				ear.color = Color(0.20, 0.45, 0.18)
				vis.add_child(ear)
			# Belt
			var belt: ColorRect = ColorRect.new()
			belt.size = Vector2(w + 2, 3)
			belt.position = Vector2(-w * 0.5 - 1, -h * 0.45)
			belt.color = Color(0.35, 0.20, 0.10)
			vis.add_child(belt)
		"wolf":
			# Wolf - tail
			var tail: ColorRect = ColorRect.new()
			tail.size = Vector2(10, 4)
			tail.position = Vector2(-w * 0.5 - 8, -h * 0.6)
			tail.color = Color(0.35, 0.35, 0.40)
			vis.add_child(tail)
			# Ears
			for side in [-1, 1]:
				var ear: ColorRect = ColorRect.new()
				ear.size = Vector2(5, 8)
				ear.position = Vector2(side * (w * 0.25), -h - 6)
				ear.color = Color(0.35, 0.35, 0.40)
				vis.add_child(ear)
		"skeleton":
			# Skeleton - rib cage lines
			for i in 3:
				var rib: ColorRect = ColorRect.new()
				rib.size = Vector2(w * 0.6, 2)
				rib.position = Vector2(-w * 0.3, -h * 0.6 + i * 6)
				rib.color = Color(0.70, 0.68, 0.60)
				vis.add_child(rib)
		"brute":
			# Brute - big arms
			for side in [-1, 1]:
				var arm: ColorRect = ColorRect.new()
				arm.size = Vector2(6, h * 0.6)
				arm.position = Vector2(side * (w * 0.55), -h * 0.7)
				arm.color = Color(0.45, 0.15, 0.12)
				vis.add_child(arm)
		"boss":
			# Boss - cape
			var cape: ColorRect = ColorRect.new()
			cape.size = Vector2(w * 0.8, h * 0.7)
			cape.position = Vector2(-w * 0.4, -h * 0.75)
			cape.color = Color(0.30, 0.05, 0.05)
			vis.add_child(cape)
		"mega_boss":
			# Mega boss - massive body with spikes
			for side in [-1, 1]:
				for i in 3:
					var spike: ColorRect = ColorRect.new()
					spike.size = Vector2(3, 8)
					spike.position = Vector2(side * (w * 0.5 + 2), -h * 0.3 + i * 10)
					spike.color = Color(0.15, 0.05, 0.20)
					vis.add_child(spike)
			# Dark aura
			var aura: ColorRect = ColorRect.new()
			aura.size = Vector2(w + 20, h + 20)
			aura.position = Vector2(-w * 0.5 - 10, -h - 10)
			aura.color = Color(0.15, 0.0, 0.20, 0.3)
			vis.add_child(aura)
			# Cape
			var cape: ColorRect = ColorRect.new()
			cape.size = Vector2(w * 0.9, h * 0.8)
			cape.position = Vector2(-w * 0.45, -h * 0.8)
			cape.color = Color(0.10, 0.0, 0.05)
			vis.add_child(cape)


func _build_face(w: float, h: float) -> void:
	var eye_color: Color
	var pupil_color: Color = Color(0.05, 0.05, 0.05)
	
	match etype:
		"slime":
			eye_color = Color(0.10, 0.10, 0.10)
		"goblin":
			eye_color = Color(0.90, 0.15, 0.10)
		"wolf":
			eye_color = Color(0.95, 0.85, 0.10)
		"skeleton":
			eye_color = Color(0.05, 0.05, 0.05)
		"brute":
			eye_color = Color(0.90, 0.20, 0.10)
		"boss":
			eye_color = Color(1.0, 0.90, 0.05)
		"mega_boss":
			eye_color = Color(1.0, 0.0, 0.0)
		_:
			eye_color = Color(0.10, 0.10, 0.10)
	
	# Eyes
	var eye_size: float = 3.0 if not is_boss else 6.0
	var eye_y: float = -h * 0.7
	
	eye_left = ColorRect.new()
	eye_left.size = Vector2(eye_size, eye_size)
	eye_left.position = Vector2(-w * 0.25, eye_y)
	eye_left.color = eye_color
	vis.add_child(eye_left)
	
	eye_right = ColorRect.new()
	eye_right.size = Vector2(eye_size, eye_size)
	eye_right.position = Vector2(w * 0.1, eye_y)
	eye_right.color = eye_color
	vis.add_child(eye_right)
	
	# Pupils (for non-skeleton)
	if etype != "skeleton":
		var pupil_size: float = eye_size * 0.45
		for eye in [eye_left, eye_right]:
			var pupil: ColorRect = ColorRect.new()
			pupil.size = Vector2(pupil_size, pupil_size)
			pupil.position = Vector2(eye.position.x + (eye_size - pupil_size) * 0.5, eye.position.y + (eye_size - pupil_size) * 0.5)
			pupil.color = pupil_color
			vis.add_child(pupil)
	
	# Mouth
	mouth = ColorRect.new()
	var mouth_w: float = w * 0.3
	var mouth_h: float = 2.0 if not is_boss else 4.0
	mouth.size = Vector2(mouth_w, mouth_h)
	mouth.position = Vector2(-mouth_w * 0.5, -h * 0.4)
	
	match etype:
		"slime":
			mouth.color = Color(0.15, 0.40, 0.12)
		"goblin":
			mouth.color = Color(0.60, 0.15, 0.10)
			# Teeth
			for i in 3:
				var tooth: ColorRect = ColorRect.new()
				tooth.size = Vector2(2, 2)
				tooth.position = Vector2(-mouth_w * 0.35 + i * 3, mouth.position.y - 2)
				tooth.color = Color(0.95, 0.95, 0.90)
				vis.add_child(tooth)
		"wolf":
			mouth.color = Color(0.30, 0.10, 0.08)
		"skeleton":
			mouth.color = Color(0.05, 0.05, 0.05)
			mouth.size = Vector2(mouth_w, mouth_h * 2)
			# Teeth rows
			for i in 4:
				var tooth: ColorRect = ColorRect.new()
				tooth.size = Vector2(2, 3)
				tooth.position = Vector2(-mouth_w * 0.4 + i * 4, mouth.position.y - 1)
				tooth.color = Color(0.90, 0.88, 0.80)
				vis.add_child(tooth)
		"brute":
			mouth.color = Color(0.50, 0.10, 0.08)
		"boss":
			mouth.color = Color(0.80, 0.05, 0.05)
			mouth.size = Vector2(mouth_w * 1.5, mouth_h * 2)
			mouth.position = Vector2(-mouth_w * 0.75, -h * 0.35)
			# Sharp teeth
			for i in 5:
				var tooth: ColorRect = ColorRect.new()
				tooth.size = Vector2(3, 4)
				tooth.position = Vector2(-mouth_w * 0.6 + i * 5, mouth.position.y - 3)
				tooth.color = Color(0.95, 0.95, 0.90)
				vis.add_child(tooth)
		"mega_boss":
			mouth.color = Color(0.60, 0.0, 0.0)
			mouth.size = Vector2(mouth_w * 2.0, mouth_h * 3)
			mouth.position = Vector2(-mouth_w, -h * 0.3)
			# Massive sharp teeth
			for i in 7:
				var tooth: ColorRect = ColorRect.new()
				tooth.size = Vector2(4, 5)
				tooth.position = Vector2(-mouth_w * 0.8 + i * 5, mouth.position.y - 4)
				tooth.color = Color(0.95, 0.95, 0.90)
				vis.add_child(tooth)
			for i in 5:
				var tooth2: ColorRect = ColorRect.new()
				tooth2.size = Vector2(3, 4)
				tooth2.position = Vector2(-mouth_w * 0.5 + i * 5, mouth.position.y + mouth_h * 2)
				tooth2.color = Color(0.95, 0.95, 0.90)
				vis.add_child(tooth2)
		_:
			mouth.color = Color(0.15, 0.15, 0.15)
	
	vis.add_child(mouth)


func _color() -> Color:
	match etype:
		"slime":
			return Color(0.35, 0.85, 0.3)
		"goblin":
			return Color(0.25, 0.55, 0.22)
		"wolf":
			return Color(0.45, 0.45, 0.5)
		"skeleton":
			return Color(0.9, 0.88, 0.8)
		"brute":
			return Color(0.55, 0.2, 0.18)
		"boss":
			return Color(0.75, 0.12, 0.08)
		"mega_boss":
			return Color(0.20, 0.05, 0.15)
	return Color.WHITE


func _physics_process(delta: float) -> void:
	if not is_inside_tree():
		return
	var player: Node = get_tree().get_first_node_in_group("player")
	if player == null:
		return
	if not is_on_floor():
		velocity.y += 980.0 * delta
	var to_p = player.global_position.x - global_position.x
	is_moving = false
	if absf(to_p) > 8.0:
		facing = 1 if to_p > 0.0 else -1
		velocity.x = signf(to_p) * speed
		is_moving = true
	else:
		velocity.x = 0.0
	if is_on_wall() and is_on_floor():
		velocity.y = -320.0
	move_and_slide()
	attack_cd = maxf(0.0, attack_cd - delta)
	flash = maxf(0.0, flash - delta)
	
	# Animations
	anim_timer += delta
	bounce_timer += delta
	pulse_timer += delta
	attack_anim = maxf(0.0, attack_anim - delta * 4.0)
	jump_timer += delta
	
	# Random jump for variety (slimes jump more often)
	var jump_chance: float = 0.02
	if etype == "slime":
		jump_chance = 0.04
	elif etype == "goblin":
		jump_chance = 0.025
	elif etype in ["boss", "mega_boss"]:
		jump_chance = 0.015
	if is_on_floor() and randf() < jump_chance and can_jump:
		velocity.y = -250.0 - randf() * 100.0
		can_jump = false
	if is_on_floor():
		can_jump = true
	
	# Body bounce when moving
	if is_moving and is_on_floor():
		var bounce: float = sin(bounce_timer * 12.0) * 2.5
		vis.position.y = bounce
	else:
		vis.position.y = move_toward(vis.position.y, 0.0, delta * 8.0)
	
	# Idle sway with breathing effect
	if not is_moving:
		var sway: float = sin(anim_timer * 2.0) * 1.2
		vis.position.y = sway
	
	# Body squash and stretch
	if body_node:
		if is_moving:
			var squash: float = 1.0 + sin(bounce_timer * 12.0) * 0.06
			body_node.scale.x = 1.0 / squash
			body_node.scale.y = squash
		else:
			body_node.scale = Vector2(1.0, 1.0)
	
	# Attack animation - lunge forward
	if attack_anim > 0.0:
		var lunge: float = attack_anim * 8.0 * float(facing)
		vis.position.x = lunge
		# Attack shake
		var shake: float = sin(attack_anim * 30.0) * 2.0 * attack_anim
		vis.position.y += shake
	
	# Pulse effect for bosses and mega bosses
	if etype in ["boss", "mega_boss"] and body_node:
		var pulse: float = 1.0 + sin(pulse_timer * 3.0) * 0.03
		body_node.scale.x = pulse
		body_node.scale.y = pulse
	
	# Flash on hit with shake
	if body_node:
		if flash > 0.0:
			body_node.color = Color.WHITE
			var hit_shake: float = sin(flash * 40.0) * 3.0 * flash * 8.0
			vis.position.x += hit_shake
		else:
			body_node.color = _color()
	
	# Eye tracking - look toward player with smooth movement
	if eye_left and eye_right:
		var eye_offset: float = signf(to_p) * 1.0
		eye_left.position.x = -body_node.size.x * 0.25 + eye_offset
		eye_right.position.x = body_node.size.x * 0.1 + eye_offset
		# Eye blink animation
		var blink: float = 1.0
		if int(anim_timer * 3.0) % 120 < 2:
			blink = 0.1
		eye_left.size.y = (3.0 if not is_boss else 6.0) * blink
		eye_right.size.y = (3.0 if not is_boss else 6.0) * blink
	
	# Mouth animation - open/close when moving and attacking
	if mouth:
		var base_mouth_h: float = 2.0 if not is_boss else 4.0
		if is_moving:
			var mouth_open: float = sin(anim_timer * 8.0) * 0.5 + 0.5
			mouth.size.y = base_mouth_h * (0.5 + mouth_open * 0.5)
		if attack_anim > 0.0:
			mouth.size.y = base_mouth_h * (1.0 + attack_anim * 0.5)
	
	_refresh_bars()
	if absf(global_position.x - player.global_position.x) < (28.0 if is_boss else 20.0) and absf(global_position.y - player.global_position.y) < 40.0:
		_hit_player()


func _hit_player() -> void:
	if attack_cd > 0.0:
		return
	attack_cd = 0.85 if is_boss else 1.05
	attack_anim = 1.0
	Game.take_damage(float(damage) * (1.0 + power * 0.01))


func _on_touch_player(body: Node) -> void:
	if body.is_in_group("player"):
		_hit_player()


func hit(raw_damage: int, attacker_power: int) -> void:
	var dmg := maxf(1.0, float(raw_damage) * (1.0 + attacker_power * 0.015) - float(power) * 0.08)
	hp -= dmg
	flash = 0.12
	_refresh_bars()
	if hp <= 0.0:
		_die()


func _refresh_bars() -> void:
	if label:
		label.text = "MOC %d" % power
	if bar and bar_bg:
		var t := clampf(hp / max_hp, 0.0, 1.0)
		bar.size.x = bar_bg.size.x * t


func _die() -> void:
	if ent_ref.has("alive"):
		ent_ref.alive = false
	var drops: Array = _roll_drops()
	died.emit(self, drops, xp_reward)
	queue_free()


func persist() -> void:
	pass


func _roll_drops() -> Array:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.randomize()
	var out: Array = []
	match etype:
		"slime":
			if rng.randf() < 0.7:
				out.append({"id": "herb", "count": rng.randi_range(1, 2)})
			if rng.randf() < 0.4:
				out.append({"id": "water", "count": 1})
		"goblin":
			out.append({"id": "wood", "count": rng.randi_range(1, 3)})
			if rng.randf() < 0.5:
				out.append({"id": "iron", "count": 1})
			if rng.randf() < 0.25:
				out.append({"id": "wood_sword", "count": 1})
		"wolf":
			out.append({"id": "leather", "count": rng.randi_range(1, 3)})
			out.append({"id": "meat", "count": rng.randi_range(1, 2)})
		"skeleton":
			out.append({"id": "iron", "count": rng.randi_range(1, 3)})
			if rng.randf() < 0.3:
				out.append({"id": "bow", "count": 1})
			if rng.randf() < 0.2:
				out.append({"id": "iron_sword", "count": 1})
		"brute":
			out.append({"id": "iron", "count": rng.randi_range(2, 5)})
			out.append({"id": "stone", "count": rng.randi_range(2, 4)})
			if rng.randf() < 0.2:
				out.append({"id": "iron_armor", "count": 1})
		"boss":
			out.append({"id": "boss_blade", "count": 1})
			out.append({"id": "potion", "count": 3})
			out.append({"id": "iron", "count": 12})
			out.append({"id": "steel_armor", "count": 1})
		"mega_boss":
			out.append({"id": "boss_blade", "count": 1})
			out.append({"id": "ninja_katana", "count": 1})
			out.append({"id": "samurai_armor", "count": 1})
			out.append({"id": "potion", "count": 5})
			out.append({"id": "iron", "count": 20})
			out.append({"id": "stone", "count": 15})
			out.append({"id": "leather", "count": 10})
	if rng.randf() < 0.15:
		out.append({"id": "stone", "count": rng.randi_range(1, 2)})
	return out
