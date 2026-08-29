extends Node2D
class_name Car

var ball_color_name: String = ""

func set_car_sprite(color_name: String, texture_file: Texture2D):
	ball_color_name = color_name
	$Sprite2D.texture = texture_file # Sahnenin içindeki Sprite2D düğümüne ulaşıp resmini güncelliyoruz
	$Sprite2D.scale = Vector2(1.65, 1.65)
