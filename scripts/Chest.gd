extends Area2D
class_name Chest

var chunk_index: int = 0
var ent_ref: Dictionary = {}


func setup(cindex: int, ent: Dictionary) -> void:
	chunk_index = cindex
	ent_ref = ent
	collision_layer = 8
	collision_mask = 0
	monitoring = false
	var cs: CollisionShape2D = CollisionShape2D.new()
	var r: RectangleShape2D = RectangleShape2D.new()
	r.size = Vector2(22, 18)
	cs.shape = r
	add_child(cs)
	
	# Japanese-style chest (tansu)
	# Main body - dark wood
	var box: ColorRect = ColorRect.new()
	box.size = Vector2(22, 16)
	box.position = Vector2(-11, -16)
	box.color = Color(0.40, 0.22, 0.10)
	add_child(box)
	
	# Wood grain lines
	for i in 3:
		var grain: ColorRect = ColorRect.new()
		grain.size = Vector2(20, 1)
		grain.position = Vector2(-10, -14 + i * 5)
		grain.color = Color(0.35, 0.18, 0.08)
		add_child(grain)
	
	# Lid - slightly lighter
	var lid: ColorRect = ColorRect.new()
	lid.size = Vector2(24, 5)
	lid.position = Vector2(-12, -21)
	lid.color = Color(0.50, 0.30, 0.14)
	add_child(lid)
	
	# Metal band around chest
	var band: ColorRect = ColorRect.new()
	band.size = Vector2(22, 2)
	band.position = Vector2(-11, -10)
	band.color = Color(0.35, 0.35, 0.40)
	add_child(band)
	
	# Lock plate
	var lock_plate: ColorRect = ColorRect.new()
	lock_plate.size = Vector2(8, 6)
	lock_plate.position = Vector2(-4, -14)
	lock_plate.color = Color(0.85, 0.70, 0.15)
	add_child(lock_plate)
	
	# Keyhole
	var keyhole: ColorRect = ColorRect.new()
	keyhole.size = Vector2(2, 3)
	keyhole.position = Vector2(-1, -13)
	keyhole.color = Color(0.15, 0.10, 0.05)
	add_child(keyhole)
	
	# Corner brackets
	for side in [-1, 1]:
		var bracket: ColorRect = ColorRect.new()
		bracket.size = Vector2(3, 3)
		bracket.position = Vector2(side * 10, -17)
		bracket.color = Color(0.35, 0.35, 0.40)
		add_child(bracket)


func interact() -> void:
	if bool(ent_ref.get("opened", false)):
		return
	ent_ref.opened = true
	var rng: RandomNumberGenerator = Game.rng_for_chunk(chunk_index)
	rng.randf()
	var pool: Array = ["wood", "stone", "iron", "leather", "meat", "water", "herb", "bow"]
	var n: int = rng.randi_range(2, 4)
	for _i in n:
		var id: String = pool[rng.randi_range(0, pool.size() - 1)]
		var c: int = rng.randi_range(1, 3)
		Game.add_item(id, c)
		Game.log_message.emit("Skrzynia: %s x%d" % [Game.item_def(id).name, c])
	if rng.randf() < 0.12:
		Game.add_item("iron_sword", 1)
		Game.log_message.emit("Skrzynia: Żelazny miecz!")
	queue_free()


func persist() -> void:
	pass
