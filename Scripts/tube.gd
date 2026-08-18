extends Area2D
class_name Tube

const MAX_CAPACITY = 4
var ball_stack: Array = []
var slot_positions: Array = []

# Arabalar tüpün dibine çok yakın veya uzak kalırsa bu sayıyla oyna
const BOTTOM_OFFSET = -5

func get_next_available_position() -> Vector2:
	var real_height = $Sprite2D.texture.get_height() * $Sprite2D.scale.y * global_scale.y
	
	var slot_height = real_height / MAX_CAPACITY
	var current_slot = ball_stack.size()
	
	# En alttan yukarıya doğru slot merkezini hesaplama
	var target_y = (real_height / 2.0) - (slot_height / 2.0) - (current_slot * slot_height) + BOTTOM_OFFSET
	
	return global_position + Vector2(0, target_y)
