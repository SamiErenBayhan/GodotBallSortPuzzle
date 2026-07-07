extends Sprite2D

var ball_color_name: String = ""

func set_ball_color(color_name: String, target_color: Color) -> void:
	ball_color_name = color_name
	modulate = target_color # Beyaz resmi verdiğimiz renge boyar
