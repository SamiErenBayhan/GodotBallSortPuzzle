extends Area2D
class_name Tube

const MAX_CAPACITY = 4
var ball_stack: Array = []
var slot_positions: Array = []
var is_completed: bool = false

# Arabalar tüpün dibine çok yakın veya uzak kalırsa bu sayıyla oyna
const BOTTOM_OFFSET = -5

func get_next_available_position() -> Vector2:
	var real_height = $Sprite2D.texture.get_height() * $Sprite2D.scale.y * global_scale.y
	
	var slot_height = real_height / MAX_CAPACITY
	var current_slot = ball_stack.size()
	
	# En alttan yukarıya doğru slot merkezini hesaplama
	var target_y = (real_height / 2.0) - (slot_height / 2.0) - (current_slot * slot_height) + BOTTOM_OFFSET
	
	return global_position + Vector2(0, target_y)

func check_if_completed(balls_in_transit: Array) -> bool:
	if is_completed:
		return false
	
	if ball_stack.size() < MAX_CAPACITY:
		return false
	
	for ball in ball_stack:
		if balls_in_transit.has(ball):
			return false
		
	var first_color = ball_stack[0].ball_color_name # En alttaki arabanın rengi
	for ball in ball_stack:
		if ball.ball_color_name != first_color:
			return false
	
	if has_node("FireworkParticles"):
		$FireworkParticles.restart() # Efekti baştan başlatır
		$FireworkParticles.emitting = true
		
	is_completed = true
	$TubeSound.play()
	print("tüp tamamlandı")
	return true

func reset_completion():
	is_completed = false
