extends Node2D

# Arabanın rengini hafızada tutmak için (Transfer kontrolü yaparken bu string lazım bize)
var ball_color_name: String = ""

# 🚀 RESMİ DEĞİŞTİREN SİHİRLİ FONKSİYON
func set_car_sprite(color_name: String, texture_file: Texture2D):
	ball_color_name = color_name
	# Sahnenin içindeki Sprite2D düğümüne ulaşıp resmini (texture) güncelliyoruz
	$Sprite2D.texture = texture_file
	
