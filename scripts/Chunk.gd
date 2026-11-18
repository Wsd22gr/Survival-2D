extends StaticBody2D
class_name WorldChunk

var index: int = 0
var heights: PackedFloat32Array = PackedFloat32Array()


func build(chunk_index: int) -> void:
	index = chunk_index
	position = Vector2(chunk_index * Game.CHUNK_TILES * Game.TILE, 0)
	heights.resize(Game.CHUNK_TILES + 1)
	for i in range(Game.CHUNK_TILES + 1):
		var wt := chunk_index * Game.CHUNK_TILES + i
		heights[i] = Game.ground_height(wt)
	_build_collision()
	z_index = -2
	queue_redraw()


func _build_collision() -> void:
	var chunk_width: float = float(Game.CHUNK_TILES) * float(Game.TILE)
	
	# === Build terrain collision ===
	# Solid surface layer — player walks on top
	for i in range(Game.CHUNK_TILES):
		var x0: float = float(i) * float(Game.TILE)
		var y0: float = heights[i]
		
		# Surface layer — player walks on top
		var tile_body: StaticBody2D = StaticBody2D.new()
		add_child(tile_body)
		var tile_shape: CollisionShape2D = CollisionShape2D.new()
		var tile_rect: RectangleShape2D = RectangleShape2D.new()
		tile_rect.size = Vector2(Game.TILE, 6.0)
		tile_shape.shape = tile_rect
		tile_shape.position = Vector2(Game.TILE * 0.5, 0.0)
		tile_body.position = Vector2(x0, y0)
		tile_body.add_child(tile_shape)
	
	# Multi-level platforms - elevated platforms above ground that player can jump onto (increased frequency)
	for i in range(Game.CHUNK_TILES):
		var plat_seed: int = hash([index, i, "platform"])
		if absi(plat_seed) % 8 == 0:  # Increased from 12 to 8 for more platforms
			var x0: float = float(i) * float(Game.TILE)
			var top: float = heights[i]
			# Platform at varying heights above ground
			var plat_height: float = 40.0 + float(absi(hash([index, i, "plat_h"])) % 60)
			var plat_y: float = top - plat_height
			var plat_width: float = float(Game.TILE) * (2.0 + float(absi(hash([index, i, "plat_w"])) % 3))
			
			var plat_body: StaticBody2D = StaticBody2D.new()
			plat_body.position = Vector2(x0, plat_y)
			add_child(plat_body)
			
			var shape: CollisionShape2D = CollisionShape2D.new()
			var rect: RectangleShape2D = RectangleShape2D.new()
			rect.size = Vector2(plat_width, 4.0)
			shape.shape = rect
			shape.position = Vector2(plat_width * 0.5, 0)
			plat_body.add_child(shape)
	
	# === Floating Islands collision (multi-level, jumpable chain) ===
	# Fewer islands (~every 12 tiles) but arranged in jumpable chains at similar heights
	for i in range(Game.CHUNK_TILES):
		var island_seed: int = hash([index, i, "floating_island"])
		if absi(island_seed) % 12 == 0:  # Reduced frequency: fewer islands, easier to jump between them
			var x0: float = float(i) * float(Game.TILE)
			var top: float = heights[i]
			# Narrower height range (60-100px above ground) so islands are at similar, jumpable heights
			var island_height: float = 60.0 + float(absi(hash([index, i, "island_h"])) % 40)
			var island_y: float = top - island_height
			var island_width: float = float(Game.TILE) * (3.0 + float(absi(hash([index, i, "island_w"])) % 4))
			var island_center_x: float = x0 + float(Game.TILE) * 0.5
			
			# Main island platform
			var island_body: StaticBody2D = StaticBody2D.new()
			island_body.position = Vector2(island_center_x - island_width * 0.5, island_y)
			add_child(island_body)
			
			var shape: CollisionShape2D = CollisionShape2D.new()
			var rect: RectangleShape2D = RectangleShape2D.new()
			rect.size = Vector2(island_width, 4.0)
			shape.shape = rect
			shape.position = Vector2(island_width * 0.5, 0)
			island_body.add_child(shape)
			
			# Multi-level: upper platform (jumpable distance ~30-45px above main)
			var multi_seed: int = hash([index, i, "island_multi"])
			if absi(multi_seed) % 2 == 0:
				var upper_y: float = island_y - 30.0 - float(absi(multi_seed) % 15)  # 30-45px above, jumpable
				var upper_width: float = island_width * 0.6
				var upper_body: StaticBody2D = StaticBody2D.new()
				upper_body.position = Vector2(island_center_x - upper_width * 0.5, upper_y)
				add_child(upper_body)
				var upper_shape: CollisionShape2D = CollisionShape2D.new()
				var upper_rect: RectangleShape2D = RectangleShape2D.new()
				upper_rect.size = Vector2(upper_width, 4.0)
				upper_shape.shape = upper_rect
				upper_shape.position = Vector2(upper_width * 0.5, 0)
				upper_body.add_child(upper_shape)
			
			# Multi-level: lower platform (jumpable distance ~20-35px below main)
			var lower_seed: int = hash([index, i, "island_lower"])
			if absi(lower_seed) % 2 == 0:
				var lower_y: float = island_y + 20.0 + float(absi(lower_seed) % 15)  # 20-35px below, jumpable
				var lower_width: float = island_width * 0.5
				var lower_body: StaticBody2D = StaticBody2D.new()
				lower_body.position = Vector2(island_center_x - lower_width * 0.5, lower_y)
				add_child(lower_body)
				var lower_shape: CollisionShape2D = CollisionShape2D.new()
				var lower_rect: RectangleShape2D = RectangleShape2D.new()
				lower_rect.size = Vector2(lower_width, 4.0)
				lower_shape.shape = lower_rect
				lower_shape.position = Vector2(lower_width * 0.5, 0)
				lower_body.add_child(lower_shape)
			
			# Multi-level: side platform (close enough to jump)
			var side_seed: int = hash([index, i, "island_side"])
			if absi(side_seed) % 3 == 0:
				var side_offset: float = island_width * 0.5 + 15.0 + float(absi(side_seed) % 10)  # 15-25px gap
				var side_dir: int = 1 if absi(side_seed) % 2 == 0 else -1
				var side_y: float = island_y + 10.0 + float(absi(side_seed) % 15)  # 10-25px below main
				var side_width: float = 24.0 + float(absi(side_seed) % 16)
				var side_body: StaticBody2D = StaticBody2D.new()
				side_body.position = Vector2(island_center_x + side_dir * side_offset - side_width * 0.5, side_y)
				add_child(side_body)
				var side_shape: CollisionShape2D = CollisionShape2D.new()
				var side_rect: RectangleShape2D = RectangleShape2D.new()
				side_rect.size = Vector2(side_width, 4.0)
				side_shape.shape = side_rect
				side_shape.position = Vector2(side_width * 0.5, 0)
				side_body.add_child(side_shape)

	# Stairs / steps leading up to higher ground at terrain transitions
	for i in range(Game.CHUNK_TILES - 1):
		var h_diff: float = absf(heights[i] - heights[i + 1])
		if h_diff > 30.0:
			var steps: int = int(h_diff / 12.0)
			var x0: float = float(i) * float(Game.TILE)
			var start_y: float = heights[i]
			var end_y: float = heights[i + 1]
			var step_dir: float = -1.0 if end_y < start_y else 1.0
			
			for s in steps:
				var step_y: float = start_y + step_dir * float(s + 1) * 12.0
				var step_x: float = x0 + float(s) * 6.0
				
				var step_body: StaticBody2D = StaticBody2D.new()
				step_body.position = Vector2(step_x, step_y)
				add_child(step_body)
				
				var shape: CollisionShape2D = CollisionShape2D.new()
				var rect: RectangleShape2D = RectangleShape2D.new()
				rect.size = Vector2(10.0, 4.0)
				shape.shape = rect
				shape.position = Vector2(5.0, 0)
				step_body.add_child(shape)
	


func _draw() -> void:
	var w: int = Game.CHUNK_TILES
	var biome: String = Game.biome_at(index * Game.CHUNK_TILES)
	var colors: Dictionary = Game.biome_colors(biome)
	var grass: Color = colors.get("grass", Color(0.40, 0.70, 0.35))
	var dirt: Color = colors.get("dirt", Color(0.42, 0.28, 0.16))
	var stone: Color = colors.get("stone", Color(0.38, 0.35, 0.35))
	var accent: Color = colors.get("accent", Color(0.96, 0.64, 0.78))
	var dark: Color = Color(0.18, 0.16, 0.15)
	
	# Multi-level terrain: draw underground layers with caves
	for i in w:
		var x0: int = i * Game.TILE
		var y0: float = heights[i]
		var y1: float = heights[mini(i + 1, w)]
		var top: float = minf(y0, y1)
		
		# Deep underground layer (dark stone)
		draw_rect(Rect2(x0, top, Game.TILE, 1400 - top), dark)
		
		# Mid underground layer (stone with texture)
		draw_rect(Rect2(x0, top + 10, Game.TILE, 200), stone.lerp(dark, 0.3))
		
		# Dirt layer (between grass and stone)
		draw_rect(Rect2(x0, top, Game.TILE, 60), dirt)
		
		# Stone layer (below dirt)
		draw_rect(Rect2(x0, top + 60, Game.TILE, 1400 - top - 60), stone.lerp(dark, 0.4))
		
		# Underground cave system - hollowed out areas
		var cave_seed: int = hash([index, i, "cave"])
		if absi(cave_seed) % 19 == 0:
			var cave_y: float = top + 80 + absi(hash([index, i, "cave_y"])) % 60
			# Cave opening
			draw_rect(Rect2(x0, cave_y, Game.TILE, 20), dark)
			# Cave ceiling stalactite
			draw_rect(Rect2(x0 + 5, cave_y - 8, 3, 8), stone)
			# Cave floor stalagmite
			draw_rect(Rect2(x0 + 8, cave_y + 20, 3, 6), stone)
			# Cave glow (crystals)
			draw_rect(Rect2(x0 + 2, cave_y + 5, 2, 2), Color(0.5, 0.8, 1.0, 0.5))
		
		# Underground mineral veins
		var mineral_seed: int = hash([index, i, "mineral"])
		if absi(mineral_seed) % 14 == 0:
			var mineral_y: float = top + 100 + absi(hash([index, i, "mineral_y"])) % 80
			var mineral_color: Color
			match absi(mineral_seed) % 3:
				0: mineral_color = Color(0.8, 0.8, 0.85)  # Iron
				1: mineral_color = Color(0.9, 0.75, 0.3)  # Gold
				2: mineral_color = Color(0.6, 0.9, 0.6)  # Emerald
			draw_rect(Rect2(x0 + 3, mineral_y, 8, 3), mineral_color)
			draw_rect(Rect2(x0 + 6, mineral_y + 3, 5, 2), mineral_color.lightened(0.1))
		
		# Grass top layer
		draw_rect(Rect2(x0, top, Game.TILE, 10), grass)
		
		# Grass blades detail
		if int(index * w + i) % 3 == 0:
			draw_rect(Rect2(x0 + 2, top - 3, 2, 5), grass.lightened(0.1))
			draw_rect(Rect2(x0 + 10, top - 2, 2, 4), grass.lightened(0.05))
		
		# Sakura petals on ground in sakura_garden
		if biome == "sakura_garden" and int(index * w + i) % 4 == 0:
			draw_rect(Rect2(x0 + 5, top - 1, 3, 2), accent)
			draw_rect(Rect2(x0 + 12, top, 2, 2), accent.lightened(0.1))
		
		# Bamboo valley details
		if biome == "bamboo_valley" and int(index * w + i) % 5 == 0:
			draw_rect(Rect2(x0 + 6, top - 12, 3, 14), Color(0.30, 0.68, 0.25))
		
		# Mountain snow caps
		if biome == "mountain_fuji" and top < 350.0:
			draw_rect(Rect2(x0, top, Game.TILE, 6), Color(0.95, 0.95, 0.98))
		
		# Temple stone path
		if biome == "temple_grounds" and int(index * w + i) % 6 == 0:
			draw_rect(Rect2(x0, top, Game.TILE, 3), Color(0.65, 0.60, 0.55))
		
		# Stone details
		if int(index * w + i) % 7 == 0:
			draw_rect(Rect2(x0 + 4, top + 40, 6, 8), Color(0.55, 0.55, 0.58, 0.7))
		
		# Small flowers in sakura garden
		if biome == "sakura_garden" and int(index * w + i) % 8 == 0:
			draw_rect(Rect2(x0 + 1, top - 2, 2, 3), Color(0.95, 0.85, 0.90))
			draw_rect(Rect2(x0 + 13, top - 1, 2, 2), Color(0.90, 0.80, 0.85))
	
	# === Additional terrain details ===
	
	# Rocks scattered on ground
	for i in w:
		var seed_val: int = hash([index, i, "rock"])
		if absi(seed_val) % 11 == 0:
			var x0: int = i * Game.TILE
			var top: float = heights[i]
			# Small rock
			draw_rect(Rect2(x0 + 3, top - 4, 8, 5), Color(0.45, 0.42, 0.40))
			draw_rect(Rect2(x0 + 5, top - 6, 4, 3), Color(0.50, 0.48, 0.45))
			# Moss on rock
			if biome != "mountain_fuji":
				draw_rect(Rect2(x0 + 4, top - 5, 3, 2), grass.darkened(0.1))
	
	# Japanese stone lanterns (tōrō) in temple_grounds and sakura_garden
	for i in w:
		var seed_val: int = hash([index, i, "lantern"])
		if absi(seed_val) % 17 == 0:
			var x0: int = i * Game.TILE
			var top: float = heights[i]
			# Base
			draw_rect(Rect2(x0 + 5, top - 4, 6, 4), Color(0.55, 0.52, 0.48))
			# Pillar
			draw_rect(Rect2(x0 + 7, top - 16, 2, 12), Color(0.50, 0.48, 0.45))
			# Light box
			draw_rect(Rect2(x0 + 3, top - 22, 10, 6), Color(0.55, 0.52, 0.48))
			# Glow
			draw_rect(Rect2(x0 + 5, top - 20, 6, 2), Color(1.0, 0.90, 0.50, 0.7))
			# Roof
			draw_rect(Rect2(x0 + 1, top - 25, 14, 3), Color(0.45, 0.42, 0.40))
			# Top ornament
			draw_rect(Rect2(x0 + 7, top - 28, 2, 3), Color(0.50, 0.48, 0.45))
	
	# Mushrooms in japanese_forest
	for i in w:
		var seed_val: int = hash([index, i, "mushroom"])
		if absi(seed_val) % 13 == 0:
			var x0: int = i * Game.TILE
			var top: float = heights[i]
			# Stem
			draw_rect(Rect2(x0 + 7, top - 4, 2, 4), Color(0.90, 0.85, 0.75))
			# Cap
			draw_rect(Rect2(x0 + 4, top - 6, 8, 3), Color(0.75, 0.20, 0.15))
			# Dots
			draw_rect(Rect2(x0 + 6, top - 5, 1, 1), Color(0.95, 0.95, 0.90))
			draw_rect(Rect2(x0 + 9, top - 5, 1, 1), Color(0.95, 0.95, 0.90))
	
	# Tall grass tufts
	for i in w:
		var seed_val: int = hash([index, i, "tall_grass"])
		if absi(seed_val) % 9 == 0:
			var x0: int = i * Game.TILE
			var top: float = heights[i]
			var grass_color: Color = grass
			if biome == "bamboo_valley":
				grass_color = Color(0.30, 0.65, 0.25)
			elif biome == "mountain_fuji":
				grass_color = Color(0.55, 0.65, 0.50)
			# Tall grass blades
			draw_rect(Rect2(x0 + 2, top - 8, 1, 9), grass_color)
			draw_rect(Rect2(x0 + 5, top - 10, 1, 11), grass_color.lightened(0.05))
			draw_rect(Rect2(x0 + 8, top - 7, 1, 8), grass_color.darkened(0.05))
			draw_rect(Rect2(x0 + 11, top - 9, 1, 10), grass_color)
	
	# Fallen leaves in japanese_forest
	for i in w:
		var seed_val: int = hash([index, i, "leaves"])
		if absi(seed_val) % 10 == 0:
			var x0: int = i * Game.TILE
			var top: float = heights[i]
			var leaf_color: Color
			match biome:
				"japanese_forest":
					leaf_color = Color(0.60, 0.35, 0.15)
				"sakura_garden":
					leaf_color = accent
				_:
					leaf_color = grass.darkened(0.1)
			draw_rect(Rect2(x0 + 1, top - 1, 4, 2), leaf_color)
			draw_rect(Rect2(x0 + 9, top - 1, 3, 2), leaf_color.lightened(0.1))
	
	# Small ponds in bamboo_valley
	for i in w:
		var seed_val: int = hash([index, i, "pond"])
		if absi(seed_val) % 23 == 0:
			var x0: int = i * Game.TILE
			var top: float = heights[i]
			# Water surface
			draw_rect(Rect2(x0 - 4, top - 2, 24, 4), Color(0.20, 0.45, 0.70, 0.6))
			# Reflection shimmer
			draw_rect(Rect2(x0 + 2, top - 1, 6, 1), Color(0.50, 0.75, 0.95, 0.4))
			draw_rect(Rect2(x0 + 10, top, 4, 1), Color(0.50, 0.75, 0.95, 0.3))
	
	# Moss patches on ground
	for i in w:
		var seed_val: int = hash([index, i, "moss"])
		if absi(seed_val) % 15 == 0:
			var x0: int = i * Game.TILE
			var top: float = heights[i]
			var moss_color: Color = Color(0.25, 0.55, 0.20)
			if biome == "japanese_forest":
				moss_color = Color(0.20, 0.50, 0.18)
			draw_rect(Rect2(x0 + 2, top - 1, 6, 2), moss_color)
			draw_rect(Rect2(x0 + 9, top, 5, 2), moss_color.lightened(0.05))
	
	# Benches (ławki) - Japanese style with backrest
	for i in w:
		var bench_seed: int = hash([index, i, "bench"])
		if absi(bench_seed) % 25 == 0:
			var x0: int = i * Game.TILE
			var top: float = heights[i]
			# Seat
			draw_rect(Rect2(x0, top - 4, 16, 3), Color(0.55, 0.35, 0.18))
			# Legs
			draw_rect(Rect2(x0 + 1, top - 1, 2, 2), Color(0.45, 0.28, 0.12))
			draw_rect(Rect2(x0 + 13, top - 1, 2, 2), Color(0.45, 0.28, 0.12))
			# Backrest
			draw_rect(Rect2(x0, top - 12, 16, 2), Color(0.55, 0.35, 0.18))
			draw_rect(Rect2(x0 + 1, top - 12, 1, 8), Color(0.45, 0.28, 0.12))
			draw_rect(Rect2(x0 + 14, top - 12, 1, 8), Color(0.45, 0.28, 0.12))
	
	# === Floating Islands (visual, multi-level, beautiful) ===
	for i in w:
		var island_seed: int = hash([index, i, "floating_island"])
		if absi(island_seed) % 12 == 0:
			var x0: int = i * Game.TILE
			var top: float = heights[i]
			var island_height: float = 60.0 + float(absi(hash([index, i, "island_h"])) % 40)
			var island_y: float = top - island_height
			var island_width: float = float(Game.TILE) * (3.0 + float(absi(hash([index, i, "island_w"])) % 4))
			var island_center_x: float = x0 + float(Game.TILE) * 0.5
			
			# === Main island body (beautiful layered) ===
			# Shadow underneath
			draw_rect(Rect2(island_center_x - island_width * 0.4, island_y + 2, island_width * 0.8, 14), dirt.darkened(0.15))
			# Main dirt body with gradient
			draw_rect(Rect2(island_center_x - island_width * 0.5, island_y, island_width, 14), dirt)
			draw_rect(Rect2(island_center_x - island_width * 0.45, island_y + 2, island_width * 0.9, 10), dirt.lightened(0.05))
			# Stone bottom (pointed, layered)
			draw_rect(Rect2(island_center_x - island_width * 0.35, island_y + 14, island_width * 0.7, 6), stone)
			draw_rect(Rect2(island_center_x - island_width * 0.25, island_y + 20, island_width * 0.5, 5), stone.darkened(0.05))
			draw_rect(Rect2(island_center_x - island_width * 0.15, island_y + 25, island_width * 0.3, 4), stone.darkened(0.1))
			draw_rect(Rect2(island_center_x - island_width * 0.05, island_y + 29, island_width * 0.1, 3), stone.darkened(0.15))
			# Grass top (lush, layered)
			draw_rect(Rect2(island_center_x - island_width * 0.5, island_y - 5, island_width, 7), grass)
			draw_rect(Rect2(island_center_x - island_width * 0.48, island_y - 4, island_width * 0.96, 4), grass.lightened(0.08))
			# Grass blades (varied)
			for gb in range(int(island_width / 4)):
				var gb_x: float = island_center_x - island_width * 0.45 + float(gb) * 4
				var gb_h: float = 3.0 + float(gb % 3) * 2.0
				draw_rect(Rect2(gb_x, island_y - 5 - gb_h, 2, gb_h), grass.lightened(0.1 + float(gb % 3) * 0.03))
			
			# Beautiful tree on island
			var tree_seed: int = hash([index, i, "island_tree"])
			if absi(tree_seed) % 3 == 0:
				# Trunk with texture
				draw_rect(Rect2(island_center_x - 3, island_y - 24, 6, 20), Color(0.35, 0.22, 0.12))
				draw_rect(Rect2(island_center_x - 1, island_y - 22, 2, 16), Color(0.42, 0.28, 0.15))
				# Canopy (multi-layered, round)
				draw_rect(Rect2(island_center_x - 10, island_y - 38, 20, 16), grass.darkened(0.15))
				draw_rect(Rect2(island_center_x - 8, island_y - 42, 16, 8), grass.darkened(0.1))
				draw_rect(Rect2(island_center_x - 6, island_y - 46, 12, 6), grass.darkened(0.05))
				draw_rect(Rect2(island_center_x - 4, island_y - 48, 8, 4), grass)
				# Leaves highlight
				draw_rect(Rect2(island_center_x - 6, island_y - 40, 4, 3), grass.lightened(0.15))
				draw_rect(Rect2(island_center_x + 2, island_y - 36, 3, 2), grass.lightened(0.1))
				# Small flowers on tree
				draw_rect(Rect2(island_center_x - 8, island_y - 34, 2, 2), Color(1.0, 0.9, 0.4, 0.8))
				draw_rect(Rect2(island_center_x + 4, island_y - 38, 2, 2), Color(1.0, 0.85, 0.5, 0.7))
			else:
				# Beautiful bush cluster
				draw_rect(Rect2(island_center_x - 6, island_y - 10, 12, 8), grass.darkened(0.15))
				draw_rect(Rect2(island_center_x - 4, island_y - 13, 8, 5), grass.darkened(0.1))
				draw_rect(Rect2(island_center_x - 2, island_y - 14, 4, 3), grass)
				# Berries on bush
				draw_rect(Rect2(island_center_x - 5, island_y - 9, 2, 2), Color(0.9, 0.3, 0.3, 0.8))
				draw_rect(Rect2(island_center_x + 2, island_y - 11, 2, 2), Color(0.9, 0.3, 0.3, 0.8))
			
			# Hanging vines (beautiful, varied)
			var vine_seed: int = hash([index, i, "island_vine"])
			if absi(vine_seed) % 2 == 0:
				var vine_len1: float = 10 + float(absi(vine_seed) % 12)
				var vine_len2: float = 8 + float(absi(vine_seed) % 10)
				# Left vine with leaves
				draw_rect(Rect2(island_center_x - island_width * 0.4, island_y + 14, 2, vine_len1), grass.darkened(0.2))
				draw_rect(Rect2(island_center_x - island_width * 0.4 - 1, island_y + 14, 4, 3), grass.darkened(0.15))
				draw_rect(Rect2(island_center_x - island_width * 0.4, island_y + 14 + vine_len1 - 2, 2, 2), grass)
				# Right vine with leaves
				draw_rect(Rect2(island_center_x + island_width * 0.2, island_y + 14, 2, vine_len2), grass.darkened(0.2))
				draw_rect(Rect2(island_center_x + island_width * 0.2 - 1, island_y + 14, 4, 3), grass.darkened(0.15))
				draw_rect(Rect2(island_center_x + island_width * 0.2, island_y + 14 + vine_len2 - 2, 2, 2), grass)
			
			# Magical sparkle/glow under island (animated feel)
			draw_rect(Rect2(island_center_x - 4, island_y + 30, 8, 6), Color(0.4, 0.7, 1.0, 0.2))
			draw_rect(Rect2(island_center_x - 2, island_y + 31, 4, 4), Color(0.6, 0.85, 1.0, 0.4))
			draw_rect(Rect2(island_center_x - 1, island_y + 32, 2, 2), Color(0.9, 0.95, 1.0, 0.6))
			# Side sparkles
			draw_rect(Rect2(island_center_x - island_width * 0.3, island_y + 26, 2, 2), Color(0.5, 0.8, 1.0, 0.3))
			draw_rect(Rect2(island_center_x + island_width * 0.2, island_y + 28, 2, 2), Color(0.5, 0.8, 1.0, 0.3))
			
			# === Upper platform (beautiful) ===
			var multi_seed: int = hash([index, i, "island_multi"])
			if absi(multi_seed) % 2 == 0:
				var upper_y: float = island_y - 30.0 - float(absi(multi_seed) % 15)
				var upper_width: float = island_width * 0.6
				# Platform body
				draw_rect(Rect2(island_center_x - upper_width * 0.5, upper_y, upper_width, 6), dirt)
				draw_rect(Rect2(island_center_x - upper_width * 0.45, upper_y + 1, upper_width * 0.9, 4), dirt.lightened(0.05))
				# Grass top
				draw_rect(Rect2(island_center_x - upper_width * 0.5, upper_y - 3, upper_width, 5), grass)
				draw_rect(Rect2(island_center_x - upper_width * 0.48, upper_y - 2, upper_width * 0.96, 3), grass.lightened(0.08))
				# Small plant on upper platform
				draw_rect(Rect2(island_center_x - 2, upper_y - 8, 4, 6), grass.darkened(0.1))
				draw_rect(Rect2(island_center_x - 1, upper_y - 10, 2, 3), grass)
				# Connecting chain (decorative)
				var chain_len: float = 30 + float(absi(multi_seed) % 15)
				for cl in range(int(chain_len / 4)):
					var cl_y: float = upper_y + float(cl) * 4
					draw_rect(Rect2(island_center_x - 1, cl_y, 2, 2), Color(0.6, 0.5, 0.4))
					draw_rect(Rect2(island_center_x - 1, cl_y + 2, 2, 2), Color(0.5, 0.4, 0.3))
			
			# === Lower platform (beautiful) ===
			var lower_seed: int = hash([index, i, "island_lower"])
			if absi(lower_seed) % 2 == 0:
				var lower_y: float = island_y + 20.0 + float(absi(lower_seed) % 15)
				var lower_width: float = island_width * 0.5
				# Platform body
				draw_rect(Rect2(island_center_x - lower_width * 0.5, lower_y, lower_width, 5), dirt)
				draw_rect(Rect2(island_center_x - lower_width * 0.45, lower_y + 1, lower_width * 0.9, 3), dirt.lightened(0.05))
				# Grass top
				draw_rect(Rect2(island_center_x - lower_width * 0.5, lower_y - 2, lower_width, 4), grass)
				# Small crystal on lower platform
				draw_rect(Rect2(island_center_x - 2, lower_y - 6, 4, 5), Color(0.5, 0.8, 1.0, 0.7))
				draw_rect(Rect2(island_center_x - 1, lower_y - 7, 2, 2), Color(0.8, 0.95, 1.0, 0.8))
				# Connecting rope
				var rope_len: float = lower_y - island_y - 16
				draw_rect(Rect2(island_center_x - 1, island_y + 16, 2, rope_len), Color(0.55, 0.45, 0.35))
			
			# === Side platform (beautiful) ===
			var side_seed: int = hash([index, i, "island_side"])
			if absi(side_seed) % 3 == 0:
				var side_offset: float = island_width * 0.5 + 15.0 + float(absi(side_seed) % 10)
				var side_dir: int = 1 if absi(side_seed) % 2 == 0 else -1
				var side_y: float = island_y + 10.0 + float(absi(side_seed) % 15)
				var side_width: float = 24.0 + float(absi(side_seed) % 16)
				var side_center_x: float = island_center_x + side_dir * side_offset
				# Platform body
				draw_rect(Rect2(side_center_x - side_width * 0.5, side_y, side_width, 5), dirt)
				draw_rect(Rect2(side_center_x - side_width * 0.45, side_y + 1, side_width * 0.9, 3), dirt.lightened(0.05))
				# Grass top
				draw_rect(Rect2(side_center_x - side_width * 0.5, side_y - 2, side_width, 4), grass)
				# Bridge/rope (decorative)
				var bridge_start_x: float = island_center_x + side_dir * island_width * 0.5
				var bridge_end_x: float = side_center_x - side_dir * side_width * 0.5
				if side_dir > 0:
					var bridge_len: float = bridge_end_x - bridge_start_x
					for bl in range(int(bridge_len / 3)):
						var bl_x: float = bridge_start_x + float(bl) * 3
						draw_rect(Rect2(bl_x, side_y - 2, 2, 1), Color(0.6, 0.5, 0.4))
						draw_rect(Rect2(bl_x + 1, side_y - 1, 1, 1), Color(0.5, 0.4, 0.3))
				else:
					var bridge_len: float = bridge_start_x - bridge_end_x
					for bl in range(int(bridge_len / 3)):
						var bl_x: float = bridge_end_x + float(bl) * 3
						draw_rect(Rect2(bl_x, side_y - 2, 2, 1), Color(0.6, 0.5, 0.4))
						draw_rect(Rect2(bl_x + 1, side_y - 1, 1, 1), Color(0.5, 0.4, 0.3))
				# Small plant on side platform
				draw_rect(Rect2(side_center_x - 2, side_y - 6, 4, 5), grass.darkened(0.12))
				draw_rect(Rect2(side_center_x - 1, side_y - 7, 2, 2), grass)
	
	# Stone walls / fences in temple_grounds
	if biome == "temple_grounds":
		for i in w:
			var wall_seed: int = hash([index, i, "wall"])
			if absi(wall_seed) % 20 == 0:
				var x0: int = i * Game.TILE
				var top: float = heights[i]
				# Low stone wall
				draw_rect(Rect2(x0, top - 10, Game.TILE, 10), Color(0.55, 0.50, 0.45))
				draw_rect(Rect2(x0, top - 12, Game.TILE, 3), Color(0.60, 0.55, 0.50))
	
	# Bamboo fences in bamboo_valley
	if biome == "bamboo_valley":
		for i in w:
			var fence_seed: int = hash([index, i, "fence"])
			if absi(fence_seed) % 22 == 0:
				var x0: int = i * Game.TILE
				var top: float = heights[i]
				# Bamboo posts
				draw_rect(Rect2(x0 + 2, top - 18, 2, 18), Color(0.35, 0.65, 0.25))
				draw_rect(Rect2(x0 + 12, top - 18, 2, 18), Color(0.35, 0.65, 0.25))
				# Horizontal bamboo
				draw_rect(Rect2(x0, top - 14, 16, 2), Color(0.30, 0.60, 0.22))
				draw_rect(Rect2(x0, top - 8, 16, 2), Color(0.30, 0.60, 0.22))
	
	# === Multi-level platforms (visible) ===
	for i in w:
		var plat_seed: int = hash([index, i, "platform"])
		if absi(plat_seed) % 12 == 0:
			var x0: int = i * Game.TILE
			var top: float = heights[i]
			var plat_height: float = 40.0 + float(absi(hash([index, i, "plat_h"])) % 60)
			var plat_y: float = top - plat_height
			var plat_width: float = float(Game.TILE) * (2.0 + float(absi(hash([index, i, "plat_w"])) % 3))
			# Platform surface (stone/wood)
			var plat_color: Color = Color(0.50, 0.42, 0.35)
			if biome == "sakura_garden":
				plat_color = Color(0.60, 0.40, 0.25)
			elif biome == "bamboo_valley":
				plat_color = Color(0.40, 0.55, 0.30)
			draw_rect(Rect2(x0, plat_y, plat_width, 4), plat_color)
			# Platform edge
			draw_rect(Rect2(x0, plat_y + 4, plat_width, 2), plat_color.darkened(0.15))
			# Support posts
			draw_rect(Rect2(x0 + 2, plat_y + 4, 2, plat_height - 4), plat_color.darkened(0.2))
			draw_rect(Rect2(x0 + plat_width - 4, plat_y + 4, 2, plat_height - 4), plat_color.darkened(0.2))
			# Rope/railing on top
			draw_rect(Rect2(x0, plat_y - 2, plat_width, 2), Color(0.70, 0.60, 0.45))
	
	# === Stairs visualization at terrain transitions ===
	for i in w - 1:
		var h_diff: float = absf(heights[i] - heights[i + 1])
		if h_diff > 30.0:
			var steps: int = int(h_diff / 12.0)
			var x0: int = i * Game.TILE
			var start_y: float = heights[i]
			var end_y: float = heights[i + 1]
			var step_dir: float = -1.0 if end_y < start_y else 1.0
			for s in steps:
				var step_y: float = start_y + step_dir * float(s + 1) * 12.0
				var step_x: float = x0 + float(s) * 6.0
				# Step surface
				draw_rect(Rect2(step_x, step_y, 10, 4), Color(0.55, 0.48, 0.42))
				# Step front
				draw_rect(Rect2(step_x, step_y + 4, 10, 2), Color(0.48, 0.42, 0.36))
				# Step side
				draw_rect(Rect2(step_x + 8, step_y, 2, 4), Color(0.50, 0.44, 0.38))
	
	
	# Starting flag - Japanese torii gate style (improved)
	if index == 0:
		var top1: float = heights[1]
		# Left pillar
		draw_rect(Rect2(4, top1 - 56, 6, 56), Color(0.9, 0.2, 0.2))
		# Right pillar
		draw_rect(Rect2(30, top1 - 56, 6, 56), Color(0.9, 0.2, 0.2))
		# Top beam (kasagi) - curved
		draw_rect(Rect2(0, top1 - 58, 42, 5), Color(0.85, 0.15, 0.15))
		# Second beam (nuki)
		draw_rect(Rect2(4, top1 - 46, 34, 4), Color(0.88, 0.15, 0.15))
		# Center tablet (shimenawa)
		draw_rect(Rect2(17, top1 - 54, 8, 4), Color(0.95, 0.85, 0.20))
 	# Base stones
		draw_rect(Rect2(2, top1 - 2, 10, 2), Color(0.55, 0.50, 0.45))
		draw_rect(Rect2(28, top1 - 2, 10, 2), Color(0.55, 0.50, 0.45))
	
	# === Biome-specific trees (beautiful, large) ===
	var tree_trunk_color: Color = colors.get("tree_trunk", Color(0.35, 0.22, 0.12))
	var tree_leaves_color: Color = colors.get("tree_leaves", grass)
	for i in w:
		var tree_seed: int = hash([index, i, "big_tree"])
		if absi(tree_seed) % 10 == 0:
			var x0: int = i * Game.TILE
			var top: float = heights[i]
			var tree_h: float = 40.0 + float(absi(tree_seed) % 30)
			match biome:
				"sakura_garden":
					# Beautiful cherry blossom tree
					# Trunk (curved)
					draw_rect(Rect2(x0 + 6, top - int(tree_h), 4, int(tree_h)), tree_trunk_color)
					draw_rect(Rect2(x0 + 5, top - int(tree_h) + 2, 2, int(tree_h) - 4), tree_trunk_color.lightened(0.05))
					# Branches
					draw_rect(Rect2(x0 + 2, top - int(tree_h) + 10, 6, 3), tree_trunk_color)
					draw_rect(Rect2(x0 + 10, top - int(tree_h) + 15, 6, 3), tree_trunk_color)
					# Canopy (round, fluffy, pink)
					var canopy_y: float = top - tree_h - 15
					draw_rect(Rect2(x0 - 6, canopy_y, 28, 20), tree_leaves_color)
					draw_rect(Rect2(x0 - 2, canopy_y - 6, 20, 10), tree_leaves_color.lightened(0.05))
					draw_rect(Rect2(x0 + 2, canopy_y - 10, 12, 8), tree_leaves_color.lightened(0.1))
					# Blossom highlights
					draw_rect(Rect2(x0 + 4, canopy_y - 4, 3, 3), Color(1.0, 0.95, 0.95, 0.7))
					draw_rect(Rect2(x0 + 12, canopy_y + 2, 2, 2), Color(1.0, 0.9, 0.9, 0.6))
					draw_rect(Rect2(x0 - 2, canopy_y + 6, 2, 2), Color(1.0, 0.92, 0.92, 0.5))
				"japanese_forest":
					# Tall pine/cedar tree
					draw_rect(Rect2(x0 + 5, top - int(tree_h), 5, int(tree_h)), tree_trunk_color)
					# Layered triangular canopy
					for layer in range(4):
						var ly: float = top - tree_h + float(layer) * 12
						var lw: float = 24.0 - float(layer) * 5
						draw_rect(Rect2(x0 + 8 - lw * 0.5, ly, lw, 10), tree_leaves_color.darkened(float(layer) * 0.05))
						draw_rect(Rect2(x0 + 8 - lw * 0.45, ly + 2, lw * 0.9, 6), tree_leaves_color.lightened(0.03))
				"temple_grounds":
					# Maple tree with golden leaves
					draw_rect(Rect2(x0 + 6, top - int(tree_h), 4, int(tree_h)), tree_trunk_color)
					# Round canopy with golden accent
					var canopy_y: float = top - tree_h - 10
					draw_rect(Rect2(x0 - 4, canopy_y, 24, 18), tree_leaves_color)
					draw_rect(Rect2(x0, canopy_y - 4, 16, 8), tree_leaves_color.lightened(0.08))
					draw_rect(Rect2(x0 + 4, canopy_y + 2, 4, 3), accent.lightened(0.1))
				"bamboo_valley":
					# Tall bamboo cluster
					for b in range(3):
						var bx: float = x0 + 2 + float(b) * 5
						var bh: float = tree_h + float(b) * 8
						draw_rect(Rect2(bx, top - bh, 3, bh), tree_trunk_color)
						# Bamboo segments
						for seg in range(int(bh / 12)):
							var sy: float = top - float(seg) * 12
							draw_rect(Rect2(bx - 1, sy, 5, 2), tree_trunk_color.lightened(0.1))
						# Leaves at top
						draw_rect(Rect2(bx - 4, top - bh, 10, 4), tree_leaves_color)
						draw_rect(Rect2(bx - 2, top - bh - 4, 6, 3), tree_leaves_color.lightened(0.05))
				"mountain_fuji":
					# Rocky outcrop with sparse vegetation
					draw_rect(Rect2(x0 + 2, top - 15, 12, 15), stone)
					draw_rect(Rect2(x0 + 4, top - 18, 8, 4), stone.lightened(0.05))
					# Small hardy bush
					draw_rect(Rect2(x0 + 4, top - 22, 8, 6), tree_leaves_color.darkened(0.1))
	
	# === Falling sakura petals (atmospheric effect) ===
	if biome == "sakura_garden":
		for i in w:
			var petal_seed: int = hash([index, i, "petal"])
			if absi(petal_seed) % 3 == 0:
				var x0: int = i * Game.TILE
				var top: float = heights[i]
				var petal_y: float = top - 20.0 - float(absi(petal_seed) % 60)
				var petal_x: float = x0 + float(absi(petal_seed) % 16)
				# Petal shape
				draw_rect(Rect2(petal_x, petal_y, 3, 2), accent.lightened(0.1))
				draw_rect(Rect2(petal_x + 1, petal_y - 1, 1, 1), Color(1.0, 0.95, 0.95, 0.8))
	
	# === Forest fog/mist effect ===
	if biome == "japanese_forest":
		for i in w:
			var fog_seed: int = hash([index, i, "fog"])
			if absi(fog_seed) % 7 == 0:
				var x0: int = i * Game.TILE
				var top: float = heights[i]
				var fog_y: float = top - 5.0 - float(absi(fog_seed) % 15)
				# Mist layer
				draw_rect(Rect2(x0, fog_y, 16, 4), Color(0.7, 0.75, 0.8, 0.15))
				draw_rect(Rect2(x0 + 2, fog_y + 2, 12, 3), Color(0.75, 0.8, 0.85, 0.1))
	
	# === Mountain clouds ===
	if biome == "mountain_fuji":
		for i in w:
			var cloud_seed: int = hash([index, i, "cloud"])
			if absi(cloud_seed) % 9 == 0:
				var x0: int = i * Game.TILE
				var top: float = heights[i]
				var cloud_y: float = top - 30.0 - float(absi(cloud_seed) % 40)
				# Cloud puffs
				draw_rect(Rect2(x0 - 4, cloud_y, 24, 8), Color(0.9, 0.92, 0.95, 0.35))
				draw_rect(Rect2(x0, cloud_y - 4, 16, 6), Color(0.95, 0.95, 0.98, 0.3))
				draw_rect(Rect2(x0 + 4, cloud_y - 6, 8, 4), Color(1.0, 1.0, 1.0, 0.25))
	
	# === Fireflies in forest at night feel ===
	if biome == "japanese_forest":
		for i in w:
			var ff_seed: int = hash([index, i, "firefly"])
			if absi(ff_seed) % 11 == 0:
				var x0: int = i * Game.TILE
				var top: float = heights[i]
				var ff_y: float = top - 15.0 - float(absi(ff_seed) % 25)
				var ff_x: float = x0 + float(absi(ff_seed) % 16)
				# Glow
				draw_rect(Rect2(ff_x - 1, ff_y - 1, 4, 4), Color(0.9, 1.0, 0.4, 0.15))
				draw_rect(Rect2(ff_x, ff_y, 2, 2), Color(0.95, 1.0, 0.5, 0.6))
	
	# === Water ripples in bamboo valley ponds ===
	if biome == "bamboo_valley":
		for i in w:
			var ripple_seed: int = hash([index, i, "ripple"])
			if absi(ripple_seed) % 18 == 0:
				var x0: int = i * Game.TILE
				var top: float = heights[i]
				var water_color: Color = colors.get("water", Color(0.20, 0.55, 0.75))
				# Ripple rings
				draw_rect(Rect2(x0 + 4, top - 3, 8, 1), water_color.lightened(0.15))
				draw_rect(Rect2(x0 + 6, top - 5, 4, 1), water_color.lightened(0.2))
	
	# === Temple torii gates scattered in temple_grounds ===
	if biome == "temple_grounds":
		for i in w:
			var torii_seed: int = hash([index, i, "torii"])
			if absi(torii_seed) % 30 == 0:
				var x0: int = i * Game.TILE
				var top: float = heights[i]
				# Left pillar
				draw_rect(Rect2(x0 + 2, top - 40, 4, 40), Color(0.88, 0.18, 0.18))
				# Right pillar
				draw_rect(Rect2(x0 + 10, top - 40, 4, 40), Color(0.88, 0.18, 0.18))
				# Top beam
				draw_rect(Rect2(x0, top - 42, 16, 4), Color(0.85, 0.15, 0.15))
				# Second beam
				draw_rect(Rect2(x0 + 2, top - 32, 12, 3), Color(0.87, 0.15, 0.15))
	
	# === Snow particles on mountain ===
	if biome == "mountain_fuji":
		for i in w:
			var snow_seed: int = hash([index, i, "snow"])
			if absi(snow_seed) % 4 == 0:
				var x0: int = i * Game.TILE
				var top: float = heights[i]
				var snow_y: float = top - 10.0 - float(absi(snow_seed) % 50)
				var snow_x: float = x0 + float(absi(snow_seed) % 16)
				# Snowflake
				draw_rect(Rect2(snow_x, snow_y, 2, 2), Color(1.0, 1.0, 1.0, 0.7))
				draw_rect(Rect2(snow_x + 0.5, snow_y + 0.5, 1, 1), Color(1.0, 1.0, 1.0, 0.9))