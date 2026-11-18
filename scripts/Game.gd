extends Node

const TILE := 16
const CHUNK_TILES := 32
const INV_SIZE := 24
const HOTBAR := 8
const FIRST_BOSS_TILES := 1000
const NEXT_BOSS_EVERY := 1000

const ITEMS := {
	"wood": {"name": "Drewno", "type": "resource", "color": Color(0.55, 0.32, 0.12)},
	"stone": {"name": "Kamień", "type": "resource", "color": Color(0.45, 0.45, 0.48)},
	"iron": {"name": "Żelazo", "type": "resource", "color": Color(0.72, 0.73, 0.78)},
	"leather": {"name": "Skóra", "type": "resource", "color": Color(0.62, 0.42, 0.22)},
	"meat": {"name": "Mięso", "type": "food", "hunger": 28, "thirst": 0, "hp": 4, "color": Color(0.75, 0.22, 0.18)},
	"water": {"name": "Woda", "type": "drink", "hunger": 0, "thirst": 35, "hp": 2, "color": Color(0.25, 0.55, 0.95)},
	"herb": {"name": "Zioło", "type": "food", "hunger": 6, "thirst": 4, "hp": 18, "color": Color(0.25, 0.7, 0.28)},
	"potion": {"name": "Mikstura", "type": "food", "hunger": 0, "thirst": 8, "hp": 55, "color": Color(0.85, 0.2, 0.55)},
	"wood_sword": {"name": "Drewniany miecz", "type": "weapon", "ranged": false, "power": 8, "damage": 14, "color": Color(0.7, 0.5, 0.25)},
	"iron_sword": {"name": "Żelazny miecz", "type": "weapon", "ranged": false, "power": 20, "damage": 24, "color": Color(0.8, 0.82, 0.9)},
	"steel_sword": {"name": "Stalowy miecz", "type": "weapon", "ranged": false, "power": 34, "damage": 40, "color": Color(0.55, 0.6, 0.75)},
	"bow": {"name": "Łuk", "type": "weapon", "ranged": true, "power": 12, "damage": 12, "color": Color(0.6, 0.38, 0.18)},
	"iron_bow": {"name": "Żelazny łuk", "type": "weapon", "ranged": true, "power": 26, "damage": 22, "color": Color(0.7, 0.72, 0.8)},
	"leather_armor": {"name": "Skórzana zbroja", "type": "armor", "power": 7, "defense": 5, "color": Color(0.55, 0.35, 0.18)},
	"iron_armor": {"name": "Żelazna zbroja", "type": "armor", "power": 18, "defense": 12, "color": Color(0.65, 0.67, 0.75)},
	"steel_armor": {"name": "Stalowa zbroja", "type": "armor", "power": 30, "defense": 20, "color": Color(0.4, 0.45, 0.58)},
	"boss_blade": {"name": "Ostrze bossa", "type": "weapon", "ranged": false, "power": 55, "damage": 62, "color": Color(0.95, 0.35, 0.15)},
	"katana": {"name": "Katana", "type": "weapon", "ranged": false, "power": 42, "damage": 50, "color": Color(0.88, 0.90, 0.95)},
	"ninja_katana": {"name": "Ninja Katana", "type": "weapon", "ranged": false, "power": 50, "damage": 58, "color": Color(0.15, 0.15, 0.20)},
	"sakura_bow": {"name": "Łuk Sakury", "type": "weapon", "ranged": true, "power": 30, "damage": 28, "color": Color(0.95, 0.70, 0.80)},
	"samurai_armor": {"name": "Zbroja Samuraja", "type": "armor", "power": 38, "defense": 26, "color": Color(0.75, 0.10, 0.10)},
	"shuriken": {"name": "Shuriken", "type": "weapon", "ranged": true, "power": 18, "damage": 16, "color": Color(0.50, 0.50, 0.55)},
}

const RECIPES := [
	{"id": "wood_sword", "need": {"wood": 5}},
	{"id": "iron_sword", "need": {"wood": 3, "iron": 4}},
	{"id": "steel_sword", "need": {"wood": 2, "iron": 8, "stone": 3}},
	{"id": "bow", "need": {"wood": 4, "leather": 2}},
	{"id": "iron_bow", "need": {"wood": 3, "iron": 3, "leather": 2}},
	{"id": "leather_armor", "need": {"leather": 6}},
	{"id": "iron_armor", "need": {"leather": 4, "iron": 6}},
	{"id": "steel_armor", "need": {"leather": 4, "iron": 10, "stone": 2}},
	{"id": "potion", "need": {"herb": 2, "water": 1}},
	{"id": "katana", "need": {"iron": 10, "wood": 3, "stone": 5}},
	{"id": "ninja_katana", "need": {"iron": 14, "wood": 2, "stone": 6, "leather": 3}},
	{"id": "sakura_bow", "need": {"wood": 6, "leather": 4, "iron": 3}},
	{"id": "samurai_armor", "need": {"leather": 8, "iron": 12, "stone": 4}},
	{"id": "shuriken", "need": {"iron": 5, "stone": 2}},
]

signal stats_changed
signal inventory_changed
signal log_message(text: String)
signal player_died

var seed_value: int = 0
var inventory: Array = []
var equipped_weapon: String = "wood_sword"
var equipped_armor: String = ""
var selected_hotbar: int = 0

var hp: float = 100.0
var max_hp: float = 100.0
var hunger: float = 100.0
var thirst: float = 100.0
var xp: int = 0
var level: int = 1
var player_x: float = 0.0
var player_y: float = 0.0

# Rebirth system - permanent bonuses after reaching high level
var rebirth_count: int = 0
var rebirth_xp_bonus: float = 1.0  # Multiplier for XP gain
var rebirth_hp_bonus: float = 1.0  # Multiplier for max HP
var rebirth_power_bonus: int = 0   # Flat bonus to power
const REBIRTH_MIN_LEVEL: int = 20  # Minimum level to rebirth
const REBIRTH_XP_BONUS_PER: float = 0.25  # +25% XP per rebirth
const REBIRTH_HP_BONUS_PER: float = 0.15  # +15% HP per rebirth
const REBIRTH_POWER_BONUS_PER: int = 3    # +3 power per rebirth

var chunk_states: Dictionary = {}
var spawned_bosses: Dictionary = {}
var ui_inventory_open: bool = false
var ui_craft_open: bool = false
var ui_pause: bool = false
var loaded_save: bool = false

# Last held consumable item (shown in hand when not wielding weapon)
var last_held_item: String = ""
var last_held_count: int = 0
# Consuming animation state - shows item in hand before actually using it
var is_consuming: bool = false
var consume_timer: float = 0.0
var consume_item_id: String = ""
const CONSUME_DURATION: float = 0.4  # seconds to show item in hand before consuming

# Checkpoint system
var checkpoint_x: float = 0.0
var checkpoint_y: float = 0.0
var has_checkpoint: bool = false


func _ready() -> void:
	_reset_inventory()
	if not load_game():
		seed_value = randi()
		add_item("wood_sword", 1)
		add_item("meat", 3)
		add_item("water", 3)
		add_item("wood", 8)


func _process(delta: float) -> void:
	# Handle consuming animation timer
	if is_consuming:
		consume_timer += delta
		if consume_timer >= CONSUME_DURATION:
			# Animation done - actually consume the item
			is_consuming = false
			var def: Dictionary = item_def(consume_item_id)
			hunger = mini(100.0, hunger + def.get("hunger", 0.0))
			thirst = mini(100.0, thirst + def.get("thirst", 0.0))
			heal(def.get("hp", 0.0))
			remove_item(consume_item_id, 1)
			log_message.emit("Zjedzono: %s" % def.name)
			last_held_count = count_item(consume_item_id)
			if last_held_count <= 0:
				last_held_item = ""
				last_held_count = 0
			consume_item_id = ""
			inventory_changed.emit()


func _reset_inventory() -> void:
	inventory.clear()
	inventory.resize(INV_SIZE)
	for i in INV_SIZE:
		inventory[i] = null


func item_def(id: String) -> Dictionary:
	return ITEMS.get(id, {"name": id, "type": "resource", "color": Color.WHITE})


func add_item(id: String, amount: int = 1) -> bool:
	if amount <= 0:
		return false
	for i in INV_SIZE:
		var s = inventory[i]
		if s != null and s.id == id:
			s.count += amount
			inventory_changed.emit()
			return true
	for i in INV_SIZE:
		if inventory[i] == null:
			inventory[i] = {"id": id, "count": amount}
			inventory_changed.emit()
			return true
	log_message.emit("Ekwipunek pełny!")
	return false


func count_item(id: String) -> int:
	var n := 0
	for s in inventory:
		if s != null and s.id == id:
			n += int(s.count)
	return n


func remove_item(id: String, amount: int) -> bool:
	if count_item(id) < amount:
		return false
	var left := amount
	for i in INV_SIZE:
		var s = inventory[i]
		if s == null or s.id != id:
			continue
		var take: int = mini(left, int(s.count))
		s.count -= take
		left -= take
		if s.count <= 0:
			inventory[i] = null
		if left <= 0:
			break
	inventory_changed.emit()
	return true


func can_craft(recipe: Dictionary) -> bool:
	for k in recipe.need.keys():
		if count_item(k) < int(recipe.need[k]):
			return false
	return true


func craft(recipe: Dictionary) -> bool:
	if not can_craft(recipe):
		log_message.emit("Brak surowców.")
		return false
	for k in recipe.need.keys():
		remove_item(k, int(recipe.need[k]))
	add_item(recipe.id, 1)
	log_message.emit("Wytworzono: %s" % item_def(recipe.id).name)
	return true


func use_selected() -> void:
	var slot = inventory[selected_hotbar]
	if slot == null:
		return
	var def: Dictionary = item_def(slot.id)
	match def.type:
		"food", "drink":
			# Start consuming animation - show item in hand first
			if is_consuming:
				return  # Already consuming, ignore
			is_consuming = true
			consume_timer = 0.0
			consume_item_id = slot.id
			last_held_item = slot.id
			last_held_count = int(slot.count)
		"weapon":
			equipped_weapon = slot.id
			log_message.emit("Wyposażono: %s" % def.name)
			stats_changed.emit()
			inventory_changed.emit()
		"armor":
			equipped_armor = slot.id
			log_message.emit("Założono: %s" % def.name)
			stats_changed.emit()
			inventory_changed.emit()


# Equip a specific item from inventory (for click-to-use)
func equip_item_from_slot(slot_index: int) -> void:
	var slot = inventory[slot_index]
	if slot == null:
		return
	var def: Dictionary = item_def(slot.id)
	match def.type:
		"food", "drink":
			# Start consuming animation - show item in hand first
			if is_consuming:
				return  # Already consuming, ignore
			is_consuming = true
			consume_timer = 0.0
			consume_item_id = slot.id
			last_held_item = slot.id
			last_held_count = int(slot.count)
		"weapon":
			equipped_weapon = slot.id
			log_message.emit("Wyposażono: %s" % def.name)
			stats_changed.emit()
			inventory_changed.emit()
		"armor":
			equipped_armor = slot.id
			log_message.emit("Założono: %s" % def.name)
			stats_changed.emit()
			inventory_changed.emit()


func heal(amount: float) -> void:
	hp = clampf(hp + amount, 0.0, max_hp)
	stats_changed.emit()


func take_damage(amount: float) -> void:
	var def := player_defense()
	var dmg := maxf(1.0, amount - def * 0.35)
	hp -= dmg
	stats_changed.emit()
	if hp <= 0.0:
		hp = 0.0
		player_died.emit()


func add_xp(amount: int) -> void:
	# Apply rebirth XP bonus multiplier
	var bonus_amount: int = int(float(amount) * rebirth_xp_bonus)
	xp += bonus_amount
	while xp >= xp_to_level():
		xp -= xp_to_level()
		level += 1
		max_hp = (100.0 + (level - 1) * 8.0) * rebirth_hp_bonus
		hp = max_hp
		log_message.emit("Poziom %d!" % level)
		if level >= REBIRTH_MIN_LEVEL and level % 20 == 0:
			log_message.emit("✦ Możesz się odrodzić! (Rebirth) Naciśnij R.")
	stats_changed.emit()


func xp_to_level() -> int:
	return 18 + level * 12


func player_power() -> int:
	var p := 10 + (level - 1) * 5 + rebirth_power_bonus
	if equipped_weapon != "":
		p += int(item_def(equipped_weapon).get("power", 0))
	if equipped_armor != "":
		p += int(item_def(equipped_armor).get("power", 0))
	return p


func player_damage() -> int:
	var d := 8
	if equipped_weapon != "":
		d = int(item_def(equipped_weapon).get("damage", 8))
	return d + level


func player_defense() -> int:
	if equipped_armor == "":
		return 0
	return int(item_def(equipped_armor).get("defense", 0))


func weapon_is_ranged() -> bool:
	if equipped_weapon == "":
		return false
	return bool(item_def(equipped_weapon).get("ranged", false))


func biome_at(world_tile_x: int) -> String:
	var n := _hnoise(world_tile_x, 0.0017, seed_value + 17)
	if n > 0.45:
		return "sakura_garden"
	if n > 0.12:
		return "japanese_forest"
	if n > -0.15:
		return "temple_grounds"
	if n > -0.45:
		return "bamboo_valley"
	return "mountain_fuji"


func biome_colors(biome: String) -> Dictionary:
	match biome:
		"sakura_garden":
			return {
				"grass": Color(0.50, 0.80, 0.42),
				"dirt": Color(0.48, 0.32, 0.22),
				"stone": Color(0.60, 0.55, 0.52),
				"sky": Color(0.90, 0.82, 0.95),
				"accent": Color(1.0, 0.68, 0.82),
				"water": Color(0.55, 0.75, 0.95),
				"tree_trunk": Color(0.35, 0.22, 0.15),
				"tree_leaves": Color(1.0, 0.72, 0.85),
			}
		"japanese_forest":
			return {
				"grass": Color(0.12, 0.52, 0.18),
				"dirt": Color(0.28, 0.16, 0.08),
				"stone": Color(0.22, 0.22, 0.25),
				"sky": Color(0.22, 0.50, 0.78),
				"accent": Color(0.85, 0.45, 0.55),
				"water": Color(0.15, 0.40, 0.60),
				"tree_trunk": Color(0.25, 0.15, 0.08),
				"tree_leaves": Color(0.08, 0.42, 0.15),
			}
		"temple_grounds":
			return {
				"grass": Color(0.42, 0.68, 0.32),
				"dirt": Color(0.58, 0.42, 0.28),
				"stone": Color(0.65, 0.60, 0.55),
				"sky": Color(0.72, 0.82, 0.95),
				"accent": Color(0.95, 0.80, 0.58),
				"water": Color(0.40, 0.65, 0.85),
				"tree_trunk": Color(0.40, 0.28, 0.18),
				"tree_leaves": Color(0.35, 0.60, 0.28),
			}
		"bamboo_valley":
			return {
				"grass": Color(0.22, 0.62, 0.20),
				"dirt": Color(0.32, 0.22, 0.12),
				"stone": Color(0.28, 0.30, 0.25),
				"sky": Color(0.48, 0.72, 0.90),
				"accent": Color(0.30, 0.75, 0.28),
				"water": Color(0.20, 0.55, 0.75),
				"tree_trunk": Color(0.30, 0.55, 0.20),
				"tree_leaves": Color(0.25, 0.65, 0.22),
			}
		"mountain_fuji":
			return {
				"grass": Color(0.65, 0.72, 0.78),
				"dirt": Color(0.48, 0.42, 0.38),
				"stone": Color(0.38, 0.40, 0.45),
				"sky": Color(0.50, 0.60, 0.82),
				"accent": Color(0.95, 0.92, 0.98),
				"water": Color(0.35, 0.55, 0.80),
				"tree_trunk": Color(0.30, 0.25, 0.22),
				"tree_leaves": Color(0.55, 0.65, 0.60),
			}
		_:
			return {
				"grass": Color(0.40, 0.70, 0.35),
				"dirt": Color(0.42, 0.28, 0.16),
				"stone": Color(0.38, 0.35, 0.35),
				"sky": Color(0.50, 0.72, 0.92),
				"accent": Color(0.96, 0.64, 0.78),
				"water": Color(0.30, 0.60, 0.85),
				"tree_trunk": Color(0.35, 0.22, 0.12),
				"tree_leaves": Color(0.30, 0.65, 0.25),
			}


func ground_height(world_tile_x: int) -> float:
	var n1 := _hnoise(world_tile_x, 0.035, seed_value)
	var n2 := _hnoise(world_tile_x, 0.008, seed_value + 91)
	var n3 := _hnoise(world_tile_x, 0.09, seed_value + 4)
	var h := 360.0 + n1 * 78.0 + n2 * 46.0 + n3 * 10.0
	match biome_at(world_tile_x):
		"sakura_garden":
			h = 370.0 + n1 * 30.0 + n2 * 15.0 + n3 * 8.0
		"japanese_forest":
			h = 350.0 + n1 * 65.0 + n2 * 35.0 + n3 * 12.0
		"temple_grounds":
			h = 380.0 + n1 * 20.0 + n2 * 10.0
		"bamboo_valley":
			h = 390.0 + n1 * 25.0 + n2 * 12.0
		"mountain_fuji":
			h = 320.0 + n1 * 110.0 + n2 * 60.0 + n3 * 15.0
	return h


func _hnoise(x: int, freq: float, s: int) -> float:
	return sin(float(x) * freq + float(s % 1000) * 0.01) * 0.55 + sin(float(x) * freq * 2.17 + 1.7) * 0.28 + sin(float(x) * freq * 5.3 + 4.2) * 0.17


func rng_for_chunk(index: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([seed_value, index])
	return rng


func boss_tile_for_distance(dist_tiles: int) -> int:
	if dist_tiles < FIRST_BOSS_TILES:
		return FIRST_BOSS_TILES
	return FIRST_BOSS_TILES + int(floor(float(dist_tiles - FIRST_BOSS_TILES) / float(NEXT_BOSS_EVERY))) * NEXT_BOSS_EVERY


func next_boss_tiles(player_tiles: int) -> int:
	var d := absi(player_tiles)
	if d < FIRST_BOSS_TILES:
		return FIRST_BOSS_TILES - d
	var passed := FIRST_BOSS_TILES + int(floor(float(d - FIRST_BOSS_TILES) / float(NEXT_BOSS_EVERY))) * NEXT_BOSS_EVERY
	return (passed + NEXT_BOSS_EVERY) - d


func ensure_chunk_state(index: int) -> Dictionary:
	var key: String = str(index)
	if chunk_states.has(key):
		return chunk_states[key]
	if chunk_states.has(index):
		return chunk_states[index]
	var rng: RandomNumberGenerator = rng_for_chunk(index)
	var entities: Array = []
	var dist: int = absi(index * CHUNK_TILES)
	var danger: float = 1.0 + dist / 1800.0
	if rng.randf() < 0.50:  # Increased from 28% to 50% chance for chests
		entities.append({"kind": "chest", "tx": rng.randi_range(4, CHUNK_TILES - 5), "opened": false})
	# Second chest chance for more loot
	if rng.randf() < 0.30:
		entities.append({"kind": "chest", "tx": rng.randi_range(4, CHUNK_TILES - 5), "opened": false})
	if rng.randf() < 0.22:
		entities.append({"kind": "trap", "tx": rng.randi_range(3, CHUNK_TILES - 4)})
	var mob_n: int = rng.randi_range(0, mini(4, 1 + int(danger)))
	for _i in mob_n:
		entities.append({
			"kind": "mob",
			"tx": rng.randi_range(2, CHUNK_TILES - 3),
			"alive": true,
			"etype": _pick_mob(rng, dist),
		})
	# Multiple trees per chunk for dense Japanese landscape
	var tree_count = rng.randi_range(2, 5)
	for _t in tree_count:
		if rng.randf() < 0.85:
			entities.append({"kind": "tree", "tx": rng.randi_range(2, CHUNK_TILES - 3)})
	var state: Dictionary = {"entities": entities}
	chunk_states[key] = state
	return state


func _pick_mob(rng: RandomNumberGenerator, dist: int) -> String:
	if dist > 8000:
		return ["skeleton", "wolf", "goblin", "brute"][rng.randi_range(0, 3)]
	if dist > 3000:
		return ["goblin", "wolf", "slime"][rng.randi_range(0, 2)]
	return ["slime", "goblin"][rng.randi_range(0, 1)]


func tick_needs(delta: float) -> void:
	hunger = maxf(0.0, hunger - delta * 0.0575)
	thirst = maxf(0.0, thirst - delta * 0.0725)
	if hunger <= 0.0 or thirst <= 0.0:
		hp -= delta * 0.2
		if hp <= 0.0:
			hp = 0.0
			player_died.emit()
	stats_changed.emit()


func save_game(px: float, py: float) -> void:
	player_x = px
	player_y = py
	var data: Dictionary = {
		"seed": seed_value,
		"hp": hp,
		"max_hp": max_hp,
		"hunger": hunger,
		"thirst": thirst,
		"xp": xp,
		"level": level,
		"px": px,
		"py": py,
		"weapon": equipped_weapon,
		"armor": equipped_armor,
		"hotbar": selected_hotbar,
		"inventory": inventory,
		"chunks": chunk_states,
		"bosses": spawned_bosses,
		"checkpoint_x": checkpoint_x,
		"checkpoint_y": checkpoint_y,
		"has_checkpoint": has_checkpoint,
		"rebirth_count": rebirth_count,
		"rebirth_xp_bonus": rebirth_xp_bonus,
		"rebirth_hp_bonus": rebirth_hp_bonus,
		"rebirth_power_bonus": rebirth_power_bonus,
	}
	var f: FileAccess = FileAccess.open("user://survival_save.json", FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data))


func load_game() -> bool:
	if not FileAccess.file_exists("user://survival_save.json"):
		return false
	var f: FileAccess = FileAccess.open("user://survival_save.json", FileAccess.READ)
	if f == null:
		return false
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return false
	seed_value = int(parsed.get("seed", randi()))
	hp = float(parsed.get("hp", 100))
	max_hp = float(parsed.get("max_hp", 100))
	hunger = float(parsed.get("hunger", 100))
	thirst = float(parsed.get("thirst", 100))
	xp = int(parsed.get("xp", 0))
	level = int(parsed.get("level", 1))
	player_x = float(parsed.get("px", 0))
	player_y = float(parsed.get("py", 200))
	equipped_weapon = str(parsed.get("weapon", "wood_sword"))
	equipped_armor = str(parsed.get("armor", ""))
	selected_hotbar = int(parsed.get("hotbar", 0))
	var inv = parsed.get("inventory", [])
	_reset_inventory()
	if inv is Array:
		for i in mini(INV_SIZE, inv.size()):
			inventory[i] = inv[i]
	chunk_states = parsed.get("chunks", {})
	spawned_bosses = parsed.get("bosses", {})
	checkpoint_x = float(parsed.get("checkpoint_x", 0))
	checkpoint_y = float(parsed.get("checkpoint_y", 200))
	has_checkpoint = bool(parsed.get("has_checkpoint", false))
	rebirth_count = int(parsed.get("rebirth_count", 0))
	rebirth_xp_bonus = float(parsed.get("rebirth_xp_bonus", 1.0))
	rebirth_hp_bonus = float(parsed.get("rebirth_hp_bonus", 1.0))
	rebirth_power_bonus = int(parsed.get("rebirth_power_bonus", 0))
	inventory_changed.emit()
	stats_changed.emit()
	loaded_save = true
	return true


func new_game() -> void:
	if FileAccess.file_exists("user://survival_save.json"):
		DirAccess.remove_absolute(ProjectSettings.globalize_path("user://survival_save.json"))
	_reset_inventory()
	seed_value = randi()
	hp = 100
	max_hp = 100
	hunger = 100
	thirst = 100
	xp = 0
	level = 1
	player_x = 0
	player_y = 200
	checkpoint_x = 0.0
	checkpoint_y = 200.0
	has_checkpoint = false
	equipped_weapon = "wood_sword"
	equipped_armor = ""
	chunk_states.clear()
	spawned_bosses.clear()
	rebirth_count = 0
	rebirth_xp_bonus = 1.0
	rebirth_hp_bonus = 1.0
	rebirth_power_bonus = 0
	add_item("wood_sword", 1)
	add_item("meat", 3)
	add_item("water", 3)
	add_item("wood", 8)
	stats_changed.emit()
	inventory_changed.emit()


func set_checkpoint(px: float, py: float) -> void:
	checkpoint_x = px
	checkpoint_y = py
	has_checkpoint = true
	log_message.emit("✦ Checkpoint zapisany!")


func respawn_position() -> Vector2:
	if has_checkpoint:
		return Vector2(checkpoint_x, checkpoint_y)
	return Vector2(40, ground_height(0) - 48)


func can_rebirth() -> bool:
	return level >= REBIRTH_MIN_LEVEL


func do_rebirth() -> void:
	if not can_rebirth():
		log_message.emit("Potrzebujesz poziomu %d do odrodzenia." % REBIRTH_MIN_LEVEL)
		return
	rebirth_count += 1
	rebirth_xp_bonus += REBIRTH_XP_BONUS_PER
	rebirth_hp_bonus += REBIRTH_HP_BONUS_PER
	rebirth_power_bonus += REBIRTH_POWER_BONUS_PER
	# Reset level and XP but keep inventory and equipment
	level = 1
	xp = 0
	max_hp = 100.0 * rebirth_hp_bonus
	hp = max_hp
	hunger = 100.0
	thirst = 100.0
	log_message.emit("✦✦✦ ODRODZENIE %d! ✦✦✦" % rebirth_count)
	log_message.emit("Bonus XP: +%d%% | Bonus HP: +%d%% | Bonus MOC: +%d" % [
		int((rebirth_xp_bonus - 1.0) * 100),
		int((rebirth_hp_bonus - 1.0) * 100),
		rebirth_power_bonus
	])
	stats_changed.emit()
	inventory_changed.emit()
