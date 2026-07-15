extends Node2D

const TUBE_SCENE = preload("res://Scenes/Tube.tscn")
const BALL_SCENE = preload("res://Scenes/ball.tscn")
const HOVER_HEIGHT = 50

const CAR_COLORS = {
	"Red":preload("res://Assets/RedCar.png") ,
	"Blue": preload("res://Assets/BlueCar.png"),
	"Green": preload("res://Assets/GreenCar.png"),
	"Yellow": preload("res://Assets/YellowCar.png")
}

var selected_tube = null
var current_level: int = 3
var all_levels_data: Dictionary = {} #Json'ın duracağı yer.
var balls_in_transit: Array = []

func _ready():
	load_levels_from_json()
	build_level()

func build_level():
	
	var level_key = str(current_level)
	if not all_levels_data.has(level_key):
		print("HATA: JSON dosyasında Level " + level_key + " bulunamadı!")
		return
	
	var level_data = all_levels_data[level_key]
	var screen_size = get_viewport_rect().size
	var screen_width = screen_size.x
	var screen_height = screen_size.y
	var tube_count = level_data.size()
	var spacing_x = 100.0
	var total_group_width = (tube_count - 1) * spacing_x
	var start_x = (screen_width - total_group_width) / 2.0
	var row_1_y = screen_height * 0.50 # Üst satır ekranın yukarısından %30 aşağıda dursun
	
	for i in range(tube_count):
		var new_tube = TUBE_SCENE.instantiate()
		new_tube.name = "Tube_" + str(i)
		var tube_x = start_x + (i * spacing_x)
		new_tube.global_position = Vector2(tube_x, row_1_y)
		add_child(new_tube)
		new_tube.input_event.connect(_on_tube_clicked.bind(new_tube))#tüpleri ekleyip onları tıklanabilir yapıyoruz.
		
		# Arabaları dizme mantığı 
		var tube_colors = level_data[i]
		for color_name in tube_colors:
			var new_ball = BALL_SCENE.instantiate()
			var target_color = CAR_COLORS[color_name]
			new_ball.set_car_sprite(color_name, target_color)
			
			new_ball.global_position = new_tube.get_next_available_position()
			add_child(new_ball)
			new_ball.z_index = 5
			new_tube.ball_stack.append(new_ball)


func _on_tube_clicked(viewport: Node, event: InputEvent, shape_idx: int, clicked_tube: Area2D):
		
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		
		var from_tube = selected_tube
		var to_tube = clicked_tube
		
		if selected_tube == null:
			if clicked_tube.ball_stack.is_empty():
				return
			var top_ball = clicked_tube.ball_stack.back()
			if top_ball in balls_in_transit:
				return  # bu top hâlâ havada, henüz seçilemez - AMA diğer tüpler serbest
			selected_tube = clicked_tube
			top_ball.global_position.y -= HOVER_HEIGHT
			
		# 2. Aynı tüpe tekrar tıklama 
		elif selected_tube == clicked_tube or to_tube.ball_stack.size() >= to_tube.MAX_CAPACITY:
			var top_ball = selected_tube.ball_stack.back()
			top_ball.global_position.y += HOVER_HEIGHT
			selected_tube = null
			
		# Başka tüpe transfer
		else:
			# Hedef tüp doluysa hamleyi engelle
			if to_tube.ball_stack.size() >= to_tube.MAX_CAPACITY:
				return
			
			var ball_to_move = from_tube.ball_stack.back()
			if not to_tube.ball_stack.is_empty():
				var target_top_ball = to_tube.ball_stack.back()
				var top_ball = selected_tube.ball_stack.back()
				if ball_to_move.ball_color_name != target_top_ball.ball_color_name:
					top_ball.global_position.y += HOVER_HEIGHT
					selected_tube = null
					return
			
			var target_pos = to_tube.get_next_available_position()
			from_tube.ball_stack.pop_back()
			to_tube.ball_stack.append(ball_to_move)  # hemen ekleniyor, stack sırası doğru kalır
			balls_in_transit.append(ball_to_move) 
			
			var tween = create_tween()
			var transit_y = from_tube.global_position.y - 250
			
			tween.tween_property(ball_to_move, "global_position:y", transit_y, 0.4)\
			.set_trans(Tween.TRANS_QUAD)\
			.set_ease(Tween.EASE_OUT)
			
			if target_pos.x > ball_to_move.global_position.x:
				tween.tween_property(ball_to_move, "rotation", deg_to_rad(90), 0.5)\
				.set_trans(Tween.TRANS_CUBIC)\
				.set_ease(Tween.EASE_OUT)
				
			elif target_pos.x < ball_to_move.global_position.x:
				tween.tween_property(ball_to_move, "rotation", deg_to_rad(-90), 0.5)\
				.set_trans(Tween.TRANS_CUBIC)\
				.set_ease(Tween.EASE_OUT)
			
			tween.tween_property(ball_to_move, "global_position:x", target_pos.x, 0.4)\
			.set_trans(Tween.TRANS_QUAD)\
			.set_ease(Tween.EASE_OUT)
			
			tween.tween_property(ball_to_move, "rotation", deg_to_rad(0), 0.5)\
				.set_trans(Tween.TRANS_CUBIC)\
				.set_ease(Tween.EASE_OUT)
			
			tween.tween_property(ball_to_move, "global_position:y", target_pos.y, 0.5)\
			.set_trans(Tween.TRANS_CUBIC)\
			.set_ease(Tween.EASE_OUT)
			
			tween.finished.connect(func():
				balls_in_transit.erase(ball_to_move)
				# Buraya istersen win-check / level tamamlandı kontrolü koyabilirsin
			)
			selected_tube = null
			
func load_levels_from_json():
	var file_path = "res://levels.json"
	if FileAccess.file_exists(file_path):
		var file = FileAccess.open(file_path, FileAccess.READ)
		var json_text = file.get_as_text()
		file.close()
		
		# Metni Godot'nun anlayacağı Dictionary formatına çeviriyoruz
		var json = JSON.new()
		var error = json.parse(json_text)
		
		if error == OK:
			all_levels_data = json.data
			print("Bölümler başarıyla yüklendi! Toplam Bölüm: ", all_levels_data.size())
		else:
			print("JSON ayrıştırma hatası! Satır: ", json.get_error_line())
	else:
		print("HATA: levels.json dosyası bulunamadı!")
		
