extends CharacterBody2D

var speed = 300.0
var gravity = 1000.0
var jump_force = -500.0

func _physics_process(delta):

	if not is_on_floor():
		velocity.y += gravity * delta

	# TEST A
	if Input.is_key_pressed(KEY_A):
		velocity.x = -speed

	# TEST D
	elif Input.is_key_pressed(KEY_D):
		velocity.x = speed

	# Nic nie wciskamy
	else:
		velocity.x = 0

	# SKOK
	if Input.is_key_pressed(KEY_SPACE) and is_on_floor():
		velocity.y = jump_force

	move_and_slide()
