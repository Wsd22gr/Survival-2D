extends Area2D
class_name Arrow

var dir: int = 1
var dmg: int = 10
var powr: int = 10
var life: float = 1.6


func setup(facing: int, damage: int, attacker_power: int) -> void:
	dir = facing
	dmg = damage
	powr = attacker_power
	collision_layer = 0
	collision_mask = 4
	monitoring = true
	var cs: CollisionShape2D = CollisionShape2D.new()
	var r: RectangleShape2D = RectangleShape2D.new()
	r.size = Vector2(14, 4)
	cs.shape = r
	add_child(cs)
	var vis: ColorRect = ColorRect.new()
	vis.size = Vector2(14, 4)
	vis.position = Vector2(-7, -2)
	vis.color = Color(0.75, 0.55, 0.2)
	add_child(vis)
	body_entered.connect(_on_body)
	area_entered.connect(_on_area)


func _process(delta: float) -> void:
	position.x += dir * 420.0 * delta
	life -= delta
	if life <= 0.0:
		queue_free()


func _on_body(body: Node) -> void:
	if body is Enemy:
		body.hit(dmg, powr)
		queue_free()


func _on_area(area: Area2D) -> void:
	var p: Node = area.get_parent()
	if p is Enemy:
		p.hit(dmg, powr)
		queue_free()
