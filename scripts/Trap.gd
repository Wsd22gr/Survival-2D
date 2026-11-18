extends Area2D
class_name SpikeTrap

var chunk_index: int = 0
var ent_ref: Dictionary = {}
var damage: float = 16.0
var cd: float = 0.0


func setup(cindex: int, ent: Dictionary) -> void:
	chunk_index = cindex
	ent_ref = ent
	collision_layer = 16
	collision_mask = 2
	monitorable = true
	monitoring = true
	var cs: CollisionShape2D = CollisionShape2D.new()
	var r: RectangleShape2D = RectangleShape2D.new()
	r.size = Vector2(24, 10)
	cs.shape = r
	cs.position = Vector2(0, -5)
	add_child(cs)
	var spikes: ColorRect = ColorRect.new()
	spikes.size = Vector2(24, 10)
	spikes.position = Vector2(-12, -10)
	spikes.color = Color(0.55, 0.55, 0.6)
	add_child(spikes)


func _process(delta: float) -> void:
	cd = maxf(0.0, cd - delta)


func _on_body(body: Node) -> void:
	if cd > 0.0:
		return
	if body.is_in_group("player"):
		cd = 0.8
		Game.take_damage(damage)
		Game.log_message.emit("Pułapka!")


func persist() -> void:
	pass
