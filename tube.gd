extends Area2D
class_name Tube

const MAX_CAPACITY = 4
var ball_stack: Array = []
var slot_positions: Array = []

func get_next_available_position() -> Vector2:
	var sprite_height = $Sprite2D.texture.get_height()
	var slot_height = sprite_height / MAX_CAPACITY
	var current_slot = ball_stack.size()
	var target_y = (sprite_height / 2.0) - (current_slot * slot_height) - (slot_height / 2)
	return global_position + Vector2(0, target_y)
	
