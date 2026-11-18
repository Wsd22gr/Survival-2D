extends Area2D
class_name LootDrop

var item_id: String = "wood"
var count: int = 1


func setup(id: String, n: int) -> void:
	item_id = id
	count = n
	collision_layer = 8
	collision_mask = 2
	monitoring = true
	var cs: CollisionShape2D = CollisionShape2D.new()
	var r: CircleShape2D = CircleShape2D.new()
	r.radius = 10
	cs.shape = r
	add_child(cs)
	var box: ColorRect = ColorRect.new()
	box.size = Vector2(12, 12)
	box.position = Vector2(-6, -6)
	box.color = Game.item_def(id).color
	add_child(box)
	body_entered.connect(_on_body)


func _on_body(body: Node) -> void:
	if body.is_in_group("player"):
		Game.add_item(item_id, count)
		Game.log_message.emit("+ %s x%d" % [Game.item_def(item_id).name, count])
		queue_free()
