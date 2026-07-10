extends Node2D

const TUBE_SCENE = preload("res://Tube.tscn")
const BALL_SCENE = preload("res://Ball.tscn")

const HOVER_HEIGHT = 60

const GAME_COLORS = {
	"Kırmızı": Color.RED,
	"Mavi": Color.BLUE,
	"Yeşil": Color.GREEN,
	"Sarı": Color.YELLOW
}

var selected_tube = null

func _ready():
	var test_level = [
		["Kırmızı", "Mavi", "Yeşil", "Sarı"],
		["Sarı", "Yeşil", "Mavi", "Kırmızı"],
		["Mavi", "Kırmızı", "Sarı", "Yeşil"],
		["Yeşil", "Sarı", "Kırmızı", "Mavi"],
		[], # Boş tüp 1
		[]  # Boş tüp 2
	]
	build_level(test_level)

func build_level(level_data: Array):
	# Ekrana elinle milimetrik grid çiziyoruz:
	var screen_size = get_viewport_rect().size
	var screen_width = screen_size.x
	var screen_height = screen_size.y
	
	var spacing_x = screen_width * 0.25 # Ekran genişliğinin %15'i kadar yan yana boşluk
	var spacing_y = screen_height * 0.45 # Ekran yüksekliğinin %35'i kadar altlı üstlü boşluk
	
	var start_x = (screen_width - (2 * spacing_x)) / 2.0
	var row_1_y = screen_height * 0.30 # Üst satır ekranın yukarısından %30 aşağıda dursun
	
	for i in range(level_data.size()):
		var new_tube = TUBE_SCENE.instantiate()
		new_tube.name = "Tube_" + str(i)
		
		# 💡 ALTLI ÜSTLÜ SİHİR: 
		# İlk 3 tüp (0,1,2) üst satıra, kalanlar (3,4,5) alt satıra dizilir!
		if i < 3:
			new_tube.global_position = Vector2(start_x + (i * spacing_x), row_1_y)
		else:
			new_tube.global_position = Vector2(start_x + ((i - 3) * spacing_x), row_1_y + spacing_y)
			
		add_child(new_tube)
		
		# Godot'nun en sağlam, orijinal tıklama bağlantısı:
		new_tube.input_event.connect(_on_tube_clicked.bind(new_tube))
		
		# Topları dizme mantığı (Dünya koordinatıyla pürüzsüz çalışır)
		var tube_colors = level_data[i]
		for color_name in tube_colors:
			var new_ball = BALL_SCENE.instantiate()
			var target_color = GAME_COLORS[color_name]
			new_ball.set_ball_color(color_name, target_color)
			
			new_ball.global_position = new_tube.get_next_available_position()
			add_child(new_ball)
			new_tube.ball_stack.append(new_ball)

# Boş tüpleri de, renk uyumunu da %100 kusursuz yöneten ana motor:
func _on_tube_clicked(viewport: Node, event: InputEvent, shape_idx: int, clicked_tube: Area2D):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var from_tube = selected_tube
		var to_tube = clicked_tube
		
		if selected_tube == null:
			if clicked_tube.ball_stack.is_empty():
				return # Boş tüpe tıklanırsa hiçbir şey yapma
			selected_tube = clicked_tube
			var top_ball = selected_tube.ball_stack.back()
			top_ball.global_position.y -= HOVER_HEIGHT
			
		# 2. DURUM: Aynı tüpe tekrar tıklama (İptal)
		elif selected_tube == clicked_tube or to_tube.ball_stack.size() >= to_tube.MAX_CAPACITY:
			var top_ball = selected_tube.ball_stack.back()
			top_ball.global_position.y += HOVER_HEIGHT
			selected_tube = null
			
		# 3. DURUM: Başka tüpe transfer
		else:
			# Hedef tüp doluysa hamleyi engelle
			if to_tube.ball_stack.size() >= to_tube.MAX_CAPACITY:
				return
			
			var ball_to_move = from_tube.ball_stack.back()
			
			# 💡 BOŞ TÜP KONTROLÜ: Hedef tüp boşsa renk ne olursa olsun transferi KABUL ET!
			if not to_tube.ball_stack.is_empty():
				var target_top_ball = to_tube.ball_stack.back()
				var top_ball = selected_tube.ball_stack.back()
				if ball_to_move.ball_color_name != target_top_ball.ball_color_name:
					top_ball.global_position.y += HOVER_HEIGHT
					selected_tube = null
					return
			
			from_tube.ball_stack.pop_back()
			var tween = create_tween()
			var target_pos = to_tube.get_next_available_position()
			var transit_y = from_tube.global_position.y - 120
			# AŞAMA A - YUKARI ÇIK: Araba önce park yerinden dikey olarak yukarı, koridora fırlar
			tween.tween_property(ball_to_move, "global_position:y", transit_y, 0.15)\
			.set_trans(Tween.TRANS_QUAD)\
			.set_ease(Tween.EASE_OUT)
			
			# AŞAMA B - YATAYDA İLERLE: Araba havada süzülerek hedef tüpün tam kapağının üstüne gelir
			tween.tween_property(ball_to_move, "global_position:x", target_pos.x, 0.25)\
			.set_trans(Tween.TRANS_QUAD)
			
			# AŞAMA C - İÇERİ GİR: Tam ağzına hizalanınca, yukarıdan aşağıya doğru park yerine süzülür
			tween.tween_property(ball_to_move, "global_position:y", target_pos.y, 0.20)\
			.set_trans(Tween.TRANS_CUBIC)\
			.set_ease(Tween.EASE_OUT)
		
			# 3. Yeni park yerinin hafızasına arabayı ekle
			to_tube.ball_stack.append(ball_to_move)		
			selected_tube = null
