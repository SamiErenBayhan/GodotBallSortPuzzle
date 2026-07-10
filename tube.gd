extends Area2D
class_name Tube

const MAX_CAPACITY = 4
var ball_stack: Array = []
var slot_positions: Array = []

func _ready() -> void:
	# Saf Node2D dünyasındayız, ofsetler eksi (yukarı doğru) çalışır:
	slot_positions = [
		Vector2(0, 80),   # 1. kat (En dip)
		Vector2(0, 25),   # 2. kat
		Vector2(0, -30),  # 3. kat
		Vector2(0, -80)   # 4. kat (En üst)
	]

func get_next_available_position() -> Vector2:
	var current_size = ball_stack.size()
	if current_size < MAX_CAPACITY:
		return global_position + slot_positions[current_size]
	return global_position
