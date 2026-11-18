extends CharacterBody2D

const SPEED := 210.0
const JUMP := -430.0
const GRAVITY := 980.0
const MAX_JUMPS := 2
const ArrowScript := preload("res://scripts/Arrow.gd")

var facing: int = 1
var jump_count: int = 0
var attack_cd: float = 0.0
var invuln: float = 0.0
var interact_area: Area2D
var slash: Area2D
var anim_slash: float = 0.0
var walk_timer: float = 0.0
var is_walking: bool = false

# Weapon visual
var weapon_hand: ColorRect
var weapon_blade: ColorRect
var weapon_group: Node2D
var arm_pivot: Node2D

# Item-in-hand visual (food/drink)
var item_hand_group: Node2D
var item_visual: ColorRect

# Animation
var bob_offset: float = 0.0
var attack_anim: float = 0.0
var attack_angle: float = 0.0

@onready var vis: Node2D = $Visual
@onready var cam: Camera2D = $Camera2D


func _ready() -> void:
	add_to_group("player")
	collision_layer = 2
	collision_mask = 1
	_build_visual()
	_build_areas()
	_build_weapon()
	floor_snap_length = 8


func _build_visual() -> void:
	# Hair - longer, samurai style
	var hair: ColorRect = ColorRect.new()
	hair.size = Vector2(18, 8)
	hair.position = Vector2(-9, -42)
	hair.color = Color(0.10, 0.10, 0.15)
	vis.add_child(hair)
	
	# Hair tie / headband
	var headband: ColorRect = ColorRect.new()
	headband.size = Vector2(16, 3)
	headband.position = Vector2(-8, -38)
	headband.color = Color(0.85, 0.12, 0.12)
	vis.add_child(headband)
	
	# Head
	var head: ColorRect = ColorRect.new()
	head.size = Vector2(14, 14)
	head.position = Vector2(-7, -36)
	head.color = Color(0.95, 0.78, 0.62)
	vis.add_child(head)
	
	# Eyes
	var eye: ColorRect = ColorRect.new()
	eye.size = Vector2(3, 3)
	eye.position = Vector2(2, -34)
	eye.color = Color(0.10, 0.10, 0.15)
	vis.add_child(eye)
	
	# Body
	var body: ColorRect = ColorRect.new()
	body.name = "Body"
	body.size = Vector2(16, 16)
	body.position = Vector2(-8, -22)
	body.color = Color(0.2, 0.55, 0.35)
	vis.add_child(body)
	
	# Belt / obi
	var belt: ColorRect = ColorRect.new()
	belt.size = Vector2(18, 4)
	belt.position = Vector2(-9, -10)
	belt.color = Color(0.15, 0.15, 0.20)
	vis.add_child(belt)
	
	# Legs
	var legs: ColorRect = ColorRect.new()
	legs.size = Vector2(14, 14)
	legs.position = Vector2(-7, -6)
	legs.color = Color(0.22, 0.22, 0.38)
	vis.add_child(legs)


func _build_weapon() -> void:
	# Create arm pivot for weapon animation
	arm_pivot = Node2D.new()
	arm_pivot.position = Vector2(4, -18)
	vis.add_child(arm_pivot)
	
	# Hand
	weapon_hand = ColorRect.new()
	weapon_hand.size = Vector2(4, 4)
	weapon_hand.position = Vector2(0, 0)
	weapon_hand.color = Color(0.95, 0.78, 0.62)
	arm_pivot.add_child(weapon_hand)
	
	# Weapon group (sword/weapon - visible by default)
	weapon_group = Node2D.new()
	arm_pivot.add_child(weapon_group)
	
	# Weapon handle (tsuka)
	var handle: ColorRect = ColorRect.new()
	handle.size = Vector2(4, 14)
	handle.position = Vector2(0, -10)
	handle.color = Color(0.55, 0.30, 0.12)
	weapon_group.add_child(handle)
	
	# Handle wrap (itoto - diamond pattern)
	for i in 3:
		var wrap: ColorRect = ColorRect.new()
		wrap.size = Vector2(5, 2)
		wrap.position = Vector2(-0.5, -6 - i * 4)
		wrap.color = Color(0.15, 0.60, 0.75)
		weapon_group.add_child(wrap)
	
	# Guard (tsuba)
	var guard: ColorRect = ColorRect.new()
	guard.size = Vector2(8, 3)
	guard.position = Vector2(-2, -17)
	guard.color = Color(0.85, 0.70, 0.15)
	weapon_group.add_child(guard)
	
	# Blade
	weapon_blade = ColorRect.new()
	weapon_blade.size = Vector2(3, 28)
	weapon_blade.position = Vector2(0.5, -40)
	weapon_blade.color = Color(0.88, 0.90, 0.95)
	weapon_group.add_child(weapon_blade)
	
	# Blade shine line
	var shine: ColorRect = ColorRect.new()
	shine.size = Vector2(1, 24)
	shine.position = Vector2(1, -38)
	shine.color = Color(1.0, 1.0, 1.0, 0.6)
	weapon_group.add_child(shine)
	
	# Item-in-hand group (food/drink - hidden by default)
	item_hand_group = Node2D.new()
	item_hand_group.visible = false
	arm_pivot.add_child(item_hand_group)
	
	# Item visual (will change based on item type)
	item_visual = ColorRect.new()
	item_visual.size = Vector2(8, 8)
	item_visual.position = Vector2(-2, -8)
	item_visual.color = Color(0.75, 0.22, 0.18)
	item_hand_group.add_child(item_visual)
	
	# Initial position - weapon at side
	arm_pivot.rotation = 0.3
	_update_hand_display()


func _build_areas() -> void:
	interact_area = Area2D.new()
	interact_area.collision_layer = 0
	interact_area.collision_mask = 8
	var ishape: CollisionShape2D = CollisionShape2D.new()
	var irect: RectangleShape2D = RectangleShape2D.new()
	irect.size = Vector2(36, 40)
	ishape.shape = irect
	ishape.position = Vector2(0, -16)
	interact_area.add_child(ishape)
	add_child(interact_area)

	slash = Area2D.new()
	slash.collision_layer = 0
	slash.collision_mask = 4
	slash.monitoring = false
	var sshape: CollisionShape2D = CollisionShape2D.new()
	var srect: RectangleShape2D = RectangleShape2D.new()
	srect.size = Vector2(38, 28)
	sshape.shape = srect
	sshape.position = Vector2(24, -16)
	slash.add_child(sshape)
	add_child(slash)

	var hurt: Area2D = Area2D.new()
	hurt.collision_layer = 0
	hurt.collision_mask = 16
	var hshape: CollisionShape2D = CollisionShape2D.new()
	var hrect: RectangleShape2D = RectangleShape2D.new()
	hrect.size = Vector2(18, 32)
	hshape.shape = hrect
	hshape.position = Vector2(0, -16)
	hurt.add_child(hshape)
	hurt.area_entered.connect(_on_hurt_area)
	add_child(hurt)


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	var dir = Input.get_axis("move_left", "move_right")
	is_walking = (dir != 0.0)
	if is_walking:
		walk_timer += delta
	if dir != 0.0:
		facing = 1 if dir > 0.0 else -1
		velocity.x = dir * SPEED
		vis.scale.x = float(facing)
	else:
		velocity.x = move_toward(velocity.x, 0.0, SPEED * 6.0 * delta)
		walk_timer = 0.0
	if is_on_floor():
		jump_count = 0
	if Input.is_action_just_pressed("jump") and jump_count < MAX_JUMPS:
		velocity.y = JUMP
		jump_count += 1
	move_and_slide()
	attack_cd = maxf(0.0, attack_cd - delta)
	invuln = maxf(0.0, invuln - delta)
	anim_slash = maxf(0.0, anim_slash - delta)
	if anim_slash <= 0.0:
		slash.monitoring = false
	
	# Walking bob animation
	if is_walking and is_on_floor():
		bob_offset = sin(walk_timer * 10.0) * 2.0
	else:
		bob_offset = move_toward(bob_offset, 0.0, delta * 10.0)
	vis.position.y = bob_offset
	
	# Attack animation
	attack_anim = maxf(0.0, attack_anim - delta)
	if attack_anim > 0.0:
		var progress = attack_anim / 0.25
		if progress > 0.5:
			# Swing forward
			attack_angle = lerp(0.0, -2.5, (progress - 0.5) * 2.0)
		else:
			# Return
			attack_angle = lerp(-2.5, 0.3, (0.5 - progress) * 2.0)
		if arm_pivot:
			arm_pivot.rotation = attack_angle * float(facing) + 0.3
	# Idle weapon sway
	elif arm_pivot:
		var idle_sway = sin(walk_timer * 2.0) * 0.05
		arm_pivot.rotation = 0.3 + idle_sway
	
	_update_armor_color()
	_update_hand_display()
	_update_weapon_color()
	if global_position.y > 1600.0:
		Game.take_damage(999)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("attack"):
		_try_attack()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_try_attack()
	elif event.is_action_pressed("shoot"):
		_try_shoot()
	elif event.is_action_pressed("interact"):
		_try_interact()
	elif event.is_action_pressed("use_item"):
		Game.use_selected()
	elif event.is_action_pressed("inventory"):
		Game.ui_inventory_open = not Game.ui_inventory_open
		if Game.ui_inventory_open:
			Game.ui_craft_open = false
		Game.inventory_changed.emit()
	elif event.is_action_pressed("craft"):
		Game.ui_craft_open = not Game.ui_craft_open
		if Game.ui_craft_open:
			Game.ui_inventory_open = false
		Game.inventory_changed.emit()
	elif event is InputEventKey and event.pressed and not event.echo:
		var k: int = event.physical_keycode
		if k >= KEY_1 and k <= KEY_8:
			Game.selected_hotbar = k - KEY_1
			# Auto-equip the item in the selected slot (weapon/armor) or use it (food/drink)
			Game.equip_item_from_slot(Game.selected_hotbar)
			Game.inventory_changed.emit()
		elif k == KEY_R:
			# Rebirth - press R to rebirth when eligible
			if Game.can_rebirth():
				Game.do_rebirth()
			else:
				Game.log_message.emit("Potrzebujesz poziomu %d by się odrodzić (obecnie %d)." % [Game.REBIRTH_MIN_LEVEL, Game.level])


func _try_attack() -> void:
	if attack_cd > 0.0:
		return
	if Game.weapon_is_ranged():
		_try_shoot()
		return
	attack_cd = 0.38
	anim_slash = 0.16
	attack_anim = 0.25
	slash.position.x = 10.0 * facing
	slash.scale.x = float(facing)
	slash.monitoring = true
	await get_tree().physics_frame
	await get_tree().physics_frame
	var hit_nodes: Dictionary = {}
	for a in slash.get_overlapping_bodies():
		if a.has_method("hit"):
			a.hit(Game.player_damage(), Game.player_power())
			hit_nodes[a] = true
	for a in slash.get_overlapping_areas():
		var p: Node = a.get_parent()
		if p and p.has_method("hit") and not hit_nodes.has(p):
			p.hit(Game.player_damage(), Game.player_power())
			hit_nodes[p] = true


func _try_shoot() -> void:
	if attack_cd > 0.0:
		return
	if not Game.weapon_is_ranged():
		Game.log_message.emit("Załóż łuk (Q na łuku w hotbarze).")
		return
	attack_cd = 0.55
	var p: Area2D = ArrowScript.new()
	p.setup(facing, Game.player_damage(), Game.player_power())
	p.global_position = global_position + Vector2(18 * facing, -20)
	get_parent().add_child(p)


func _try_interact() -> void:
	for a in interact_area.get_overlapping_areas():
		var n: Node = a
		if n.has_method("interact"):
			n.interact()
			return
		if n.get_parent() and n.get_parent().has_method("interact"):
			n.get_parent().interact()
			return


func _on_hurt_area(area: Area2D) -> void:
	if invuln > 0.0:
		return
	if area.get("damage") != null:
		invuln = 0.7
		Game.take_damage(float(area.damage))


func _update_armor_color() -> void:
	var body: Node = vis.get_node_or_null("Body")
	if body == null:
		return
	if Game.equipped_armor == "":
		body.color = Color(0.2, 0.55, 0.35)
	else:
		body.color = Game.item_def(Game.equipped_armor).color


func _update_weapon_color() -> void:
	if weapon_blade == null:
		return
	var weapon_id: String = Game.equipped_weapon
	if weapon_id == "":
		# No weapon equipped, hide the weapon group
		if weapon_group:
			weapon_group.visible = false
		return
	# Weapon equipped, make sure it's visible
	if weapon_group:
		weapon_group.visible = true
	var def: Dictionary = Game.item_def(weapon_id)
	var color: Color = def.get("color", Color(0.88, 0.90, 0.95))
	weapon_blade.color = color
	
	# Special effects for special weapons
	if weapon_id == "katana":
		weapon_blade.color = Color(0.90, 0.92, 0.97)
	elif weapon_id == "ninja_katana":
		weapon_blade.color = Color(0.12, 0.12, 0.18)
	elif weapon_id == "sakura_bow":
		weapon_blade.color = Color(0.95, 0.70, 0.80)
	elif weapon_id == "boss_blade":
		weapon_blade.color = Color(0.95, 0.35, 0.15)
	elif weapon_id == "shuriken":
		weapon_blade.color = Color(0.50, 0.50, 0.55)
	elif weapon_id == "wood_sword":
		weapon_blade.color = Color(0.70, 0.50, 0.25)
	elif weapon_id == "iron_sword":
		weapon_blade.color = Color(0.80, 0.82, 0.90)
	elif weapon_id == "steel_sword":
		weapon_blade.color = Color(0.55, 0.60, 0.75)
	elif weapon_id == "bow":
		weapon_blade.color = Color(0.60, 0.38, 0.18)
	elif weapon_id == "iron_bow":
		weapon_blade.color = Color(0.70, 0.72, 0.80)


func _update_hand_display() -> void:
	# Show item in hand while consuming (animation in progress)
	if Game.is_consuming and Game.last_held_item != "":
		# Show the consumable item, hide weapon
		var item_def: Dictionary = Game.item_def(Game.last_held_item)
		var item_color: Color = item_def.get("color", Color.WHITE)
		
		if item_visual:
			item_visual.color = item_color
			# Different shapes for different item types
			var def_type: String = item_def.get("type", "food")
			if def_type == "drink":
				# Water bottle shape - tall and narrow
				item_visual.size = Vector2(6, 12)
				item_visual.position = Vector2(-1, -10)
			else:
				# Food shape - chunky
				item_visual.size = Vector2(10, 8)
				item_visual.position = Vector2(-3, -8)
		
		if item_hand_group:
			item_hand_group.visible = true
		if weapon_group:
			weapon_group.visible = false
	else:
		# Hide item, show weapon only if equipped
		if item_hand_group:
			item_hand_group.visible = false
		# Weapon visibility is controlled by _update_weapon_color()
		# Don't override it here