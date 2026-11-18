extends Node2D

const LOAD_RADIUS := 3
const UNLOAD_RADIUS := 5
const CHECKPOINT_EVERY := 100  # tiles between checkpoints
const ChunkScript := preload("res://scripts/Chunk.gd")
const EnemyScript := preload("res://scripts/Enemy.gd")
const ChestScript := preload("res://scripts/Chest.gd")
const TrapScript := preload("res://scripts/Trap.gd")
const TreeScript := preload("res://scripts/TreeProp.gd")
const LootScript := preload("res://scripts/Loot.gd")
const CheckpointScript := preload("res://scripts/Checkpoint.gd")

@onready var chunks_root: Node2D = $Chunks
@onready var entities_root: Node2D = $Entities
@onready var player: CharacterBody2D = $Player

var loaded_chunks: Dictionary = {}
var save_timer: float = 0.0
var needs_timer: float = 0.0
var spawned_checkpoints: Dictionary = {}
var mega_timer: float = 0.0
const MEGA_SPAWN_INTERVAL := 120.0  # seconds between mega monster spawns


func _ready() -> void:
	if Game.loaded_save:
		player.global_position = Game.respawn_position()
	else:
		var gy: float = Game.ground_height(0)
		player.global_position = Vector2(40, gy - 48)
	Game.player_died.connect(_on_death)
	_stream_chunks(true)
	_spawn_start_checkpoint()


func _process(delta: float) -> void:
	_stream_chunks(false)
	_check_bosses()
	_check_checkpoints()
	_update_sky()
	save_timer += delta
	needs_timer += delta
	mega_timer += delta
	if needs_timer >= 0.25:
		needs_timer = 0.0
		Game.tick_needs(0.25)
	if save_timer >= 8.0:
		save_timer = 0.0
		Game.save_game(player.global_position.x, player.global_position.y)
	# Periodic mega monster spawn
	if mega_timer >= MEGA_SPAWN_INTERVAL:
		mega_timer = 0.0
		_spawn_mega_monster()


func _update_sky() -> void:
	var sky_node: Control = get_node_or_null("Sky/Color")
	if sky_node == null:
		return
	var tiles: int = int(player.global_position.x / Game.TILE)
	var biome: String = Game.biome_at(tiles)
	var colors: Dictionary = Game.biome_colors(biome)
	var target_color: Color = colors.get("sky", Color(0.85, 0.75, 0.90))
	# Smooth sky color transition
	sky_node.color = sky_node.color.lerp(target_color, 0.02)


func _stream_chunks(force: bool) -> void:
	var cx: int = int(floor(player.global_position.x / float(Game.CHUNK_TILES * Game.TILE)))
	for i in range(cx - LOAD_RADIUS, cx + LOAD_RADIUS + 1):
		if not loaded_chunks.has(i):
			_load_chunk(i)
	if force:
		return
	var to_drop: Array = []
	for idx in loaded_chunks.keys():
		if absi(int(idx) - cx) > UNLOAD_RADIUS:
			to_drop.append(idx)
	for idx in to_drop:
		_unload_chunk(int(idx))


func _load_chunk(index: int) -> void:
	var state: Dictionary = Game.ensure_chunk_state(index)
	var chunk: Node = ChunkScript.new()
	chunks_root.add_child(chunk)
	chunk.build(index)
	loaded_chunks[index] = chunk
	for ent in state.entities:
		_spawn_entity(index, ent)


func _unload_chunk(index: int) -> void:
	if not loaded_chunks.has(index):
		return
	var chunk: Node = loaded_chunks[index]
	if is_instance_valid(chunk):
		chunk.queue_free()
	loaded_chunks.erase(index)
	for child in entities_root.get_children():
		if child.get("is_boss"):
			continue
		if child.has_meta("chunk") and int(child.get_meta("chunk")) == index:
			if child.has_method("persist"):
				child.persist()
			child.queue_free()


func _spawn_entity(index: int, ent: Dictionary) -> void:
	var origin_x: int = index * Game.CHUNK_TILES * Game.TILE
	var tx: int = int(ent.get("tx", 0))
	var wx: int = origin_x + tx * Game.TILE + Game.TILE * 0.5
	var gy: float = Game.ground_height(index * Game.CHUNK_TILES + tx)
	match str(ent.get("kind", "")):
		"tree":
			var t: Node2D = TreeScript.new()
			t.position = Vector2(wx, gy)
			t.set_meta("chunk", index)
			entities_root.add_child(t)
		"chest":
			if bool(ent.get("opened", false)):
				return
			var c: Area2D = ChestScript.new()
			c.setup(index, ent)
			c.position = Vector2(wx, gy - 10)
			c.set_meta("chunk", index)
			entities_root.add_child(c)
		"trap":
			var trap_node: Area2D = TrapScript.new()
			trap_node.setup(index, ent)
			trap_node.position = Vector2(wx, gy - 6)
			trap_node.set_meta("chunk", index)
			entities_root.add_child(trap_node)
		"mob":
			if not bool(ent.get("alive", true)):
				return
			var e = EnemyScript.new()
			e.setup(str(ent.get("etype", "slime")), index, ent, false)
			e.position = Vector2(wx, gy - 18)
			e.set_meta("chunk", index)
			e.died.connect(_on_mob_died)
			entities_root.add_child(e)


func _check_bosses() -> void:
	var tiles: int = int(player.global_position.x / Game.TILE)
	var dist: int = absi(tiles)
	if dist < Game.FIRST_BOSS_TILES:
		return
	var milestone: int = Game.boss_tile_for_distance(dist)
	for sign_dir in [-1, 1]:
		var key: String = "%d" % (sign_dir * milestone)
		if Game.spawned_bosses.get(key, "") == "dead":
			continue
		if sign_dir < 0 and tiles > -milestone + 80:
			continue
		if sign_dir > 0 and tiles < milestone - 80:
			continue
		if _boss_exists(key):
			continue
		_spawn_boss(sign_dir * milestone, key)


func _boss_exists(key: String) -> bool:
	for child in entities_root.get_children():
		if child.get("boss_key") == key and is_instance_valid(child):
			return true
	return false


func _spawn_boss(tile_x: int, key: String) -> void:
	Game.spawned_bosses[key] = "alive"
	var wx: int = tile_x * Game.TILE
	var gy: float = Game.ground_height(tile_x)
	var e = EnemyScript.new()
	var fake: Dictionary = {"kind": "mob", "tx": 0, "alive": true, "etype": "boss", "boss_key": key}
	e.setup("boss", int(floor(float(tile_x) / Game.CHUNK_TILES)), fake, true)
	e.position = Vector2(wx, gy - 40)
	e.set_meta("chunk", int(floor(float(tile_x) / Game.CHUNK_TILES)))
	e.died.connect(_on_mob_died)
	entities_root.add_child(e)
	Game.log_message.emit("BOSS pojawia się na kratce %d!" % tile_x)


func _on_mob_died(enemy, drops: Array, xp_amount: int) -> void:
	Game.add_xp(xp_amount)
	for d in drops:
		Game.add_item(d.id, int(d.count))
	if enemy.is_boss and enemy.boss_key != "":
		Game.spawned_bosses[enemy.boss_key] = "dead"
		Game.log_message.emit("Boss pokonany! Świat idzie dalej — kolejny boss za 1000 kratek.")
	Game.log_message.emit("Łup: %s  (+%d XP)" % [_fmt_drops(drops), xp_amount])


func _fmt_drops(drops: Array) -> String:
	if drops.is_empty():
		return "nic"
	var parts: PackedStringArray = []
	for d in drops:
		parts.append("%s x%d" % [Game.item_def(d.id).name, int(d.count)])
	return ", ".join(parts)


func _on_death() -> void:
	var respawn: Vector2 = Game.respawn_position()
	player.global_position = respawn
	Game.hp = Game.max_hp * 0.5
	Game.hunger = maxf(Game.hunger, 35.0)
	Game.thirst = maxf(Game.thirst, 35.0)
	if Game.has_checkpoint:
		Game.log_message.emit("Omdlenie... budzisz się przy checkpointu.")
	else:
		Game.log_message.emit("Omdlenie... budzisz się przy starcie.")
	Game.stats_changed.emit()


func spawn_loot(world_pos: Vector2, item_id: String, count: int) -> void:
	var l: Area2D = LootScript.new()
	l.setup(item_id, count)
	l.global_position = world_pos
	entities_root.add_child(l)


func _spawn_start_checkpoint() -> void:
	var cp: Area2D = CheckpointScript.new()
	var gy: float = Game.ground_height(0)
	cp.position = Vector2(60, gy - 10)
	cp.interact()  # Auto-activate starting checkpoint
	entities_root.add_child(cp)
	spawned_checkpoints["start"] = true


func _check_checkpoints() -> void:
	var tiles: int = int(player.global_position.x / Game.TILE)
	var dist: int = absi(tiles)
	# Spawn checkpoints every CHECKPOINT_EVERY tiles (co 100 kratek)
	for sign_dir in [-1, 1]:
		for mult in range(1, 200):  # up to ~20000 tiles
			var tile_x: int = sign_dir * mult * CHECKPOINT_EVERY
			if absi(tile_x) > dist + CHECKPOINT_EVERY * 3:
				continue
			var key: String = "cp_%d" % tile_x
			if spawned_checkpoints.has(key):
				continue
			if absi(tile_x) <= dist + CHECKPOINT_EVERY * 2:
				var wx: int = tile_x * Game.TILE
				var gy: float = Game.ground_height(tile_x)
				var cp: Area2D = CheckpointScript.new()
				cp.position = Vector2(wx, gy - 10)
				entities_root.add_child(cp)
				spawned_checkpoints[key] = true


func _spawn_mega_monster() -> void:
	# Spawn a huge mega monster near the player periodically
	var player_tile: int = int(player.global_position.x / Game.TILE)
	var offset: int = randi_range(-15, 15)
	var tile_x: int = player_tile + offset
	var wx: int = tile_x * Game.TILE
	var gy: float = Game.ground_height(tile_x)
	var e = EnemyScript.new()
	var fake: Dictionary = {"kind": "mob", "tx": 0, "alive": true, "etype": "mega_boss"}
	e.setup("mega_boss", int(floor(float(tile_x) / Game.CHUNK_TILES)), fake, false)
	e.position = Vector2(wx, gy - 50)
	e.set_meta("chunk", int(floor(float(tile_x) / Game.CHUNK_TILES)))
	e.died.connect(_on_mob_died)
	entities_root.add_child(e)
	Game.log_message.emit("⚠ OGROMNY POTWÓR pojawia się w pobliżu!")
