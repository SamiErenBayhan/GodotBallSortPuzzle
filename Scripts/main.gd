extends Node2D

const TUBE_SCENE = preload("res://Scenes/Tube.tscn")
const BALL_SCENE = preload("res://Scenes/ball.tscn")
const HOVER_HEIGHT = 50

const CAR_COLORS = {
	"Red":preload("res://Assets/cars/Red.png") ,
	"Blue": preload("res://Assets/cars/Blue.png"),
	"Green": preload("res://Assets/cars/Green.png"),
	"Yellow": preload("res://Assets/cars/Yellow.png"),
	"Orange": preload("res://Assets/cars/Orange.png"),
	"Purple": preload("res://Assets/cars/Purple.png"),
	"White": preload("res://Assets/cars/White.png"),
	"Pink": preload("res://Assets/cars/Pink.png")
}
var current_level : int = 1
var selected_tube = null
var balls_in_transit: Array = []
var move_history: Array = []
var level_holder : Node2D = null

func _ready():
	LevelManager.load_levels_from_json()
	build_level()

func build_level():
	var level_key = str(current_level)
	if not LevelManager.all_levels_data.has(level_key):
		current_level = 1
		return
	
	# Level Holder var mı kontrol ediyoruz, varsa temizliyoruz
	if level_holder != null and is_instance_valid(level_holder):
		level_holder.free()
		level_holder = null
	
	# Yeni bir Level Holder oluşturuyoruz, child olarak tanıtıp adlandırıyoruz.
	level_holder = Node2D.new()
	level_holder.name = "LevelHolder"
	add_child(level_holder)
	
	selected_tube = null
	balls_in_transit.clear()
	move_history.clear()
	
	var level_data = LevelManager.all_levels_data[level_key]
	var screen_size = get_viewport_rect().size
	var screen_width = screen_size.x
	var screen_height = screen_size.y
	var tube_count = level_data.size()
	
	var spacing_x = 75.0
	var total_group_width = (tube_count - 1) * spacing_x
	var start_x = (screen_width - total_group_width) / 2.0
	var row_1_y = screen_height * 0.50 
	
	for i in range(tube_count):
		var new_tube = TUBE_SCENE.instantiate()
		new_tube.name = "Tube_" + str(i)
		
		var tube_x = start_x + (i * spacing_x)
		new_tube.global_position = Vector2(tube_x, row_1_y)
		
		level_holder.add_child(new_tube) #LevelHolder ın içine yerleştiriyoruz.
		new_tube.input_event.connect(_on_tube_clicked.bind(new_tube))#tüpleri ekleyip onları tıklanabilir yapıyoruz.
		
		# Arabaları dizme mantığı 
		var tube_colors = level_data[i]
		for color_name in tube_colors:
			var new_ball = BALL_SCENE.instantiate()
			var target_color = CAR_COLORS[color_name]
			new_ball.set_car_sprite(color_name, target_color)
			
			new_ball.global_position = new_tube.get_next_available_position()
			level_holder.add_child(new_ball)#LevelHolder ın içine yerleştiriyoruz.
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
				return  
			selected_tube = clicked_tube
			top_ball.global_position.y -= HOVER_HEIGHT
			$CarTouchSound.play()
		
		# Aynı tüpe tekrar tıklama 
		elif selected_tube == clicked_tube or to_tube.ball_stack.size() >= to_tube.MAX_CAPACITY:
			var top_ball = selected_tube.ball_stack.back()
			top_ball.global_position.y += HOVER_HEIGHT
			selected_tube = null
			$CarTouchSound.play()
			
		# Başka tüpe transfer
		else:
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
			
			# Hareket eden topları arraye kaydetme
			var target_pos = to_tube.get_next_available_position()
			move_history.append({
				"from_tube": from_tube,
				"to_tube": to_tube,
				"ball": ball_to_move
			})
			from_tube.ball_stack.pop_back()
			to_tube.ball_stack.append(ball_to_move) 
			balls_in_transit.append(ball_to_move) 
			
			# Animasyon
			var tween = create_tween().set_parallel(false)
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
				if is_instance_valid(to_tube):
					to_tube.check_if_completed(balls_in_transit)
				
				if balls_in_transit.is_empty():
					if check_all_tubes():
						level_up()
			)
			selected_tube = null
			
func check_all_tubes() -> bool:
	if not balls_in_transit.is_empty():
		return false	
	for child in level_holder.get_children():#kaç tüp olduğunu kontrol ediyoruz. Her levelda sayı aynı olmadığı için her seferinde tek tek kontrol ediyoruz.
		if child is Tube or "ball_stack" in child:
			var stack = child.ball_stack#bütün topların bir listesini çıkarıyoruz
			if stack.is_empty():
				continue
			
			if stack.size() < child.MAX_CAPACITY:
				return false
				
			var first_color = stack[0].ball_color_name
			for ball in stack:
				if ball.ball_color_name != first_color:
					return false
	return true
	
func level_up():
	current_level += 1	
	build_level()
	$NextLevel.play()
	
func restart_level():
	if not balls_in_transit.is_empty():
		return
	level_holder.free()
	build_level()
	
func undo_move():
	if move_history.is_empty():
		print("Geri alınacak hamle yok")
		return
	# Eğer oyuncu bir tüpe tıklayıp arabayı havaya kaldırdıysa iptal et ve indir
	if selected_tube != null:
		var hovered_ball = selected_tube.ball_stack.back()
		hovered_ball.global_position.y += HOVER_HEIGHT
		selected_tube = null
	if not balls_in_transit.is_empty():
		return
	
	var last_move = move_history.pop_back()
	var original_tube = last_move["from_tube"]
	var current_tube = last_move["to_tube"]
	var ball = last_move["ball"]
	
	current_tube.ball_stack.pop_back()
	if current_tube.has_method("reset_completion"):
		current_tube.reset_completion()
	var target_pos = original_tube.get_next_available_position()
	ball.global_position = target_pos
	ball.rotation = 0.0
	original_tube.ball_stack.append(ball)
	
	

	
	
	
		
