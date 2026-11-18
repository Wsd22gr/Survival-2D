extends CanvasLayer

var last_log: String = ""
var log_time: float = 0.0

@onready var hp_bar: ColorRect = $Root/Bars/HpFill
@onready var hunger_bar: ColorRect = $Root/Bars/HungerFill
@onready var thirst_bar: ColorRect = $Root/Bars/ThirstFill
@onready var xp_bar: ColorRect = $Root/Bars/XpFill
@onready var hp_bg: ColorRect = $Root/Bars/HpBg
@onready var hunger_bg: ColorRect = $Root/Bars/HungerBg
@onready var thirst_bg: ColorRect = $Root/Bars/ThirstBg
@onready var xp_bg: ColorRect = $Root/Bars/XpBg
@onready var stats_label: Label = $Root/Stats
@onready var log_label: Label = $Root/Log
@onready var hotbar: HBoxContainer = $Root/Hotbar
@onready var inv_panel: Panel = $Root/InvPanel
@onready var craft_panel: Panel = $Root/CraftPanel
@onready var inv_grid: GridContainer = $Root/InvPanel/Grid
@onready var craft_list: VBoxContainer = $Root/CraftPanel/Scroll/List


func _ready() -> void:
	Game.stats_changed.connect(_refresh_stats)
	Game.inventory_changed.connect(_refresh_inv)
	Game.log_message.connect(_on_log)
	_refresh_stats()
	_refresh_inv()
	inv_panel.visible = false
	craft_panel.visible = false


func _process(delta: float) -> void:
	log_time = maxf(0.0, log_time - delta)
	log_label.modulate.a = clampf(log_time, 0.0, 1.0)
	inv_panel.visible = Game.ui_inventory_open
	craft_panel.visible = Game.ui_craft_open
	# HP bar with dynamic color (green -> yellow -> red)
	var hp_ratio: float = Game.hp / Game.max_hp
	_set_fill(hp_bar, hp_bg, hp_ratio)
	hp_bar.color = _hp_color(hp_ratio)
	# Hunger bar (brown -> orange when low)
	var hunger_ratio: float = Game.hunger / 100.0
	_set_fill(hunger_bar, hunger_bg, hunger_ratio)
	hunger_bar.color = Color(0.55, 0.35, 0.15).lerp(Color(0.9, 0.5, 0.15), 1.0 - hunger_ratio)
	# Thirst bar (blue -> cyan when low)
	var thirst_ratio: float = Game.thirst / 100.0
	_set_fill(thirst_bar, thirst_bg, thirst_ratio)
	thirst_bar.color = Color(0.25, 0.55, 0.95).lerp(Color(0.15, 0.85, 0.95), 1.0 - thirst_ratio)
	# XP bar with rainbow effect based on level
	_set_fill(xp_bar, xp_bg, float(Game.xp) / float(Game.xp_to_level()))
	var xp_hue: float = fmod(float(Game.level) * 0.05, 1.0)
	xp_bar.color = Color.from_hsv(xp_hue, 0.7, 0.9)
	_refresh_stats()


func _hp_color(ratio: float) -> Color:
	if ratio > 0.6:
		return Color(0.25, 0.85, 0.30).lerp(Color(0.20, 0.95, 0.25), (ratio - 0.6) * 2.5)
	elif ratio > 0.3:
		return Color(0.9, 0.75, 0.15).lerp(Color(0.25, 0.85, 0.30), (ratio - 0.3) * 3.33)
	else:
		return Color(0.9, 0.15, 0.15).lerp(Color(0.9, 0.75, 0.15), ratio / 0.3)


func _set_fill(fill: ColorRect, bg: ColorRect, t: float) -> void:
	fill.size.x = bg.size.x * clampf(t, 0.0, 1.0)


func _refresh_stats() -> void:
	var player: Node = get_tree().get_first_node_in_group("player")
	var tiles: int = 0
	if player:
		tiles = int(player.global_position.x / Game.TILE)
	var wname: String = "pięści"
	if Game.equipped_weapon != "":
		wname = Game.item_def(Game.equipped_weapon).name
	var aname: String = "brak"
	if Game.equipped_armor != "":
		aname = Game.item_def(Game.equipped_armor).name
	var rebirth_line: String = ""
	if Game.rebirth_count > 0:
		rebirth_line = "  ✦ Odrodzenia: %d" % Game.rebirth_count
	var biome_name: String = ""
	var p: Node = get_tree().get_first_node_in_group("player")
	if p:
		var bt: int = int(p.global_position.x / Game.TILE)
		biome_name = Game.biome_at(bt)
	var biome_display: String = _biome_display(biome_name)
	stats_label.text = "❤ HP %d/%d   ⚔ MOC %d   ⭐ POZ %d%s\n🍖 %d   💧 %d   📍 Kratka %d   🌿 %s\n⚔ %s   🛡 %s\nNastępny boss za ~%d kratek%s" % [
		int(Game.hp), int(Game.max_hp), Game.player_power(), Game.level, rebirth_line,
		int(Game.hunger), int(Game.thirst), tiles, biome_display,
		wname, aname, Game.next_boss_tiles(tiles),
		"  |  Naciśnij R by się odrodzić" if Game.can_rebirth() else ""
	]


func _biome_display(biome: String) -> String:
	match biome:
		"sakura_garden": return "Ogród Sakury 🌸"
		"japanese_forest": return "Las Japoński 🌲"
		"temple_grounds": return "Podwórko Świątyni ⛩"
		"bamboo_valley": return "Dolina Bambusa 🎋"
		"mountain_fuji": return "Góra Fuji 🗻"
		_: return biome
	return biome


func _on_log(text: String) -> void:
	last_log = text
	log_label.text = text
	log_time = 4.0


func _refresh_inv() -> void:
	for c in hotbar.get_children():
		c.queue_free()
	for i in Game.HOTBAR:
		hotbar.add_child(_slot_button(i, true))
	for c in inv_grid.get_children():
		c.queue_free()
	for i in Game.INV_SIZE:
		inv_grid.add_child(_slot_button(i, false))
	# Enhanced crafting list with color-coded buttons
	for c in craft_list.get_children():
		c.queue_free()
	for recipe in Game.RECIPES:
		var b: Button = Button.new()
		var def: Dictionary = Game.item_def(recipe.id)
		var can_make: bool = Game.can_craft(recipe)
		# Color-coded prefix based on item type
		var prefix: String
		match def.get("type", "resource"):
			"weapon": prefix = "⚔"
			"armor": prefix = "🛡"
			"food": prefix = "🍖"
			"drink": prefix = "💧"
			_: prefix = "📦"
		var need_txt: String = ""
		for k in recipe.need.keys():
			var have: int = Game.count_item(k)
			var need: int = int(recipe.need[k])
			var color_marker: String = "✓" if have >= need else "✗"
			need_txt += "%s %s%d/%d  " % [color_marker, Game.item_def(k).name, have, need]
		b.text = "%s %s  [%s]" % [prefix, def.name, need_txt]
		b.disabled = not can_make
		if can_make:
			b.modulate = Color(0.7, 1.0, 0.7)  # Green tint for craftable
		else:
			b.modulate = Color(0.5, 0.5, 0.5)  # Gray for unavailable
		b.pressed.connect(func() -> void: Game.craft(recipe))
		craft_list.add_child(b)


func _slot_button(i: int, is_hot: bool) -> Button:
	var b: Button = Button.new()
	b.custom_minimum_size = Vector2(72, 40) if is_hot else Vector2(110, 36)
	var s = Game.inventory[i]
	if s == null:
		b.text = str(i + 1) if is_hot else "-"
		b.modulate = Color(0.4, 0.4, 0.45)
	else:
		var def: Dictionary = Game.item_def(s.id)
		var type_icon: String
		match def.get("type", "resource"):
			"weapon": type_icon = "⚔"
			"armor": type_icon = "🛡"
			"food": type_icon = "🍖"
			"drink": type_icon = "💧"
			_: type_icon = "·"
		b.text = "%s %s x%d" % [type_icon, def.name, int(s.count)]
		# Highlight equipped items
		var is_equipped: bool = false
		if def.get("type") == "weapon" and Game.equipped_weapon == s.id:
			is_equipped = true
		elif def.get("type") == "armor" and Game.equipped_armor == s.id:
			is_equipped = true
		if is_equipped:
			b.modulate = Color(1.0, 0.95, 0.4)  # Gold glow for equipped
			b.text = "★ %s %s x%d" % [type_icon, def.name, int(s.count)]
		else:
			# Color-coded by type
			match def.get("type", "resource"):
				"food":
					b.modulate = Color(1.0, 0.85, 0.80)
				"drink":
					b.modulate = Color(0.80, 0.85, 1.0)
				"weapon":
					b.modulate = Color(0.90, 0.90, 0.80)
				"armor":
					b.modulate = Color(0.85, 0.80, 0.95)
				_:
					b.modulate = Color(1.0, 1.0, 1.0)
	if is_hot and i == Game.selected_hotbar:
		b.modulate = Color(1.2, 1.15, 0.7)
	b.pressed.connect(func() -> void:
		Game.selected_hotbar = i
		# Click on any slot: eat food, equip weapon/armor directly
		Game.equip_item_from_slot(i)
		Game.inventory_changed.emit()
	)
	return b
