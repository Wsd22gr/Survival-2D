extends Node2D
class_name TreeProp

var petal_timer := 0.0
var tree_type := "sakura"


func _ready() -> void:
	# Determine tree type based on biome
	var biome := Game.biome_at(int(global_position.x / Game.TILE))
	match biome:
		"sakura_garden":
			tree_type = "sakura"
		"japanese_forest":
			tree_type = "pine"
		"bamboo_valley":
			tree_type = "bamboo"
		_:
			tree_type = "sakura"
	
	_build_tree()


func _build_tree() -> void:
	match tree_type:
		"sakura":
			_build_sakura()
		"pine":
			_build_pine()
		"bamboo":
			_build_bamboo()


func _build_sakura() -> void:
	# Trunk - curved, dark brown
	var trunk := ColorRect.new()
	trunk.size = Vector2(10, 40)
	trunk.position = Vector2(-5, -40)
	trunk.color = Color(0.35, 0.20, 0.10)
	add_child(trunk)
	
	# Branches
	var branch1 := ColorRect.new()
	branch1.size = Vector2(16, 5)
	branch1.position = Vector2(-18, -48)
	branch1.color = Color(0.35, 0.20, 0.10)
	add_child(branch1)
	
	var branch2 := ColorRect.new()
	branch2.size = Vector2(14, 5)
	branch2.position = Vector2(6, -44)
	branch2.color = Color(0.35, 0.20, 0.10)
	add_child(branch2)
	
	# Main canopy - large pink
	var canopy1 := ColorRect.new()
	canopy1.size = Vector2(44, 30)
	canopy1.position = Vector2(-22, -72)
	canopy1.color = Color(0.96, 0.64, 0.78)
	add_child(canopy1)
	
	# Upper canopy - lighter pink
	var canopy2 := ColorRect.new()
	canopy2.size = Vector2(34, 22)
	canopy2.position = Vector2(-17, -86)
	canopy2.color = Color(0.97, 0.75, 0.85)
	add_child(canopy2)
	
	# Top canopy - very light pink
	var canopy3 := ColorRect.new()
	canopy3.size = Vector2(22, 16)
	canopy3.position = Vector2(-11, -96)
	canopy3.color = Color(0.98, 0.85, 0.92)
	add_child(canopy3)
	
	# Darker pink accents
	var accent1 := ColorRect.new()
	accent1.size = Vector2(12, 10)
	accent1.position = Vector2(-20, -68)
	accent1.color = Color(0.92, 0.50, 0.65)
	add_child(accent1)
	
	var accent2 := ColorRect.new()
	accent2.size = Vector2(10, 8)
	accent2.position = Vector2(8, -74)
	accent2.color = Color(0.93, 0.52, 0.68)
	add_child(accent2)
	
	# White highlights
	var highlight := ColorRect.new()
	highlight.size = Vector2(8, 6)
	highlight.position = Vector2(-5, -82)
	highlight.color = Color(1.0, 0.92, 0.95)
	add_child(highlight)


func _build_pine() -> void:
	# Trunk
	var trunk := ColorRect.new()
	trunk.size = Vector2(8, 50)
	trunk.position = Vector2(-4, -50)
	trunk.color = Color(0.30, 0.18, 0.08)
	add_child(trunk)
	
	# Pine layers - triangular look
	var layer1 := ColorRect.new()
	layer1.size = Vector2(40, 14)
	layer1.position = Vector2(-20, -56)
	layer1.color = Color(0.12, 0.42, 0.18)
	add_child(layer1)
	
	var layer2 := ColorRect.new()
	layer2.size = Vector2(32, 12)
	layer2.position = Vector2(-16, -66)
	layer2.color = Color(0.15, 0.48, 0.22)
	add_child(layer2)
	
	var layer3 := ColorRect.new()
	layer3.size = Vector2(24, 12)
	layer3.position = Vector2(-12, -76)
	layer3.color = Color(0.18, 0.52, 0.25)
	add_child(layer3)
	
	var layer4 := ColorRect.new()
	layer4.size = Vector2(14, 10)
	layer4.position = Vector2(-7, -84)
	layer4.color = Color(0.20, 0.55, 0.28)
	add_child(layer4)


func _build_bamboo() -> void:
	# Multiple bamboo stalks
	for i in 3:
		var offset = (i - 1) * 10
		var height = 50 + i * 10
		
		var stalk := ColorRect.new()
		stalk.size = Vector2(4, height)
		stalk.position = Vector2(offset - 2, -height)
		stalk.color = Color(0.28, 0.62, 0.22)
		add_child(stalk)
		
		# Bamboo nodes
		for j in range(2, int(height) / 14):
			var node := ColorRect.new()
			node.size = Vector2(6, 3)
			node.position = Vector2(offset - 3, -j * 14)
			node.color = Color(0.22, 0.48, 0.18)
			add_child(node)
		
		# Leaves at top
		var leaves := ColorRect.new()
		leaves.size = Vector2(16, 8)
		leaves.position = Vector2(offset - 8, -height - 4)
		leaves.color = Color(0.30, 0.70, 0.28)
		add_child(leaves)


func _process(delta: float) -> void:
	if tree_type != "sakura":
		return
	petal_timer += delta
	if petal_timer > 0.3:
		petal_timer = 0.0
		_spawn_petal()


func _spawn_petal() -> void:
	var petal := ColorRect.new()
	petal.size = Vector2(3, 2)
	var rand_x = randf_range(-20, 20)
	petal.position = Vector2(rand_x, -70 + randf_range(0, 20))
	petal.color = Color(0.96 + randf() * 0.04, 0.60 + randf() * 0.15, 0.72 + randf() * 0.10, 0.8)
	add_child(petal)
	
	# Animate petal falling
	var tween := create_tween()
	tween.tween_property(petal, "position:y", 10, 2.0 + randf())
	tween.tween_property(petal, "position:x", petal.position.x + randf_range(-15, 15), 2.0 + randf())
	tween.tween_property(petal, "modulate:a", 0.0, 0.5)
	tween.tween_callback(petal.queue_free)


func persist() -> void:
	# Tree state is regenerated from biome, no persistence needed
	pass