extends Node2D

@onready var victory_layer = $VictoryLayer
@onready var victory_text = $VictoryLayer/VictoryText
@onready var level_label = $CanvasLayer/LevelLabel
@onready var tubes_vbox = $CanvasLayer/TubesVBox

const TUBE_SCENE = preload("res://Scenes/Tube.tscn")
const BALL_SCENE = preload("res://Scenes/ball.tscn")
const HOVER_HEIGHT = 50
const PRAISE_TEXTS = ["GREAT!", "AWESOME!", "FANTASTIC!", "PERFECT!", "AMAZING!", "EXCELLENT!"]
const ROW_SPLIT_Y: float = 960.0 
const TRANSIT_MARGIN: float = 340.0
const TOP_MARGIN: float = 150.0 # üst boşluk
const BOTTOM_MARGIN: float = 80.0 # alt boşluk 
const SIDE_MARGIN: float = 50.0
const MAX_COLUMNS_CAP: int = 6 # bir satırda olabilecek en fazla tüp 
const COL_GAP_RATIO: float = -0.1 # tüpler arası yatay boşluk tüp genişliğinin oranı
const ROW_GAP_RATIO: float = 0.1 # satırlar arası dikey boşluk 
const SIDE_LANE_RATIO: float = 0.6 # her kenarda tüp genişliği kadar araba geçiş şeridi
const MIN_SCALE: float = 0.5
const MAX_SCALE: float = 1.3

const CAR_COLORS = {
	"Red":preload("res://Assets/cars/Red.png"),
	"Blue": preload("res://Assets/cars/Blue.png"),
	"Green": preload("res://Assets/cars/Green.png"),
	"Yellow": preload("res://Assets/cars/Yellow.png"),
	"Orange": preload("res://Assets/cars/Orange.png"),
	"Purple": preload("res://Assets/cars/Purple.png"),
	"White": preload("res://Assets/cars/White.png"),
	"Pink": preload("res://Assets/cars/Pink.png"),
	"Turquoise": preload("res://Assets/cars/Turquoise.png")
}

var current_level : int = 10
var selected_tube = null
var balls_in_transit: Array = []
var move_history: Array = []	
var level_holder : Node2D = null
var current_tubes: Array = []
var tube_base_size: Vector2 = Vector2.ZERO

func _ready():
	setup_vbox_layout()
	LevelManager.load_levels_from_json()
	build_level()
	if is_instance_valid(victory_layer):
		victory_layer.visible = false
		
func build_level() -> void:
	var level_key = str(current_level)
	if not LevelManager.all_levels_data.has(level_key):
		current_level = 1
		level_key = str(current_level)
		if not LevelManager.all_levels_data.has(level_key):
			return
			
	level_label.text = "Level " + str(current_level)
	
	if is_instance_valid(level_holder):
		level_holder.queue_free()
		level_holder = null
	
	level_holder = Node2D.new()
	level_holder.name = "LevelHolder"
	add_child(level_holder)
	
	selected_tube = null
	balls_in_transit.clear()
	move_history.clear()
	
	var level_data = LevelManager.all_levels_data[level_key]
	var tube_count = level_data.size()
	
	var layout = calculate_layout(tube_count)
	var max_columns = layout["max_columns"]
	var current_scale = layout["scale"]
	var slot_size = layout["slot_size"]
	var horizontal_spacing = layout["horizontal_spacing"]
	var vertical_row_gap = layout["vertical_row_gap"]
	
	# Eski slotları temizle
	for child in tubes_vbox.get_children():
		child.queue_free()
	
	tubes_vbox.add_theme_constant_override("separation", vertical_row_gap)
	await get_tree().process_frame	
	
	var created_tubes: Array = []
	var index = 0
	
	while index < tube_count:
		var row_count = min(max_columns, tube_count - index)
		
		var row_center = CenterContainer.new()
		row_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tubes_vbox.add_child(row_center)
		
		var hbox = HBoxContainer.new()
		hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.alignment = BoxContainer.ALIGNMENT_CENTER
		hbox.add_theme_constant_override("separation", horizontal_spacing)
		tubes_vbox.add_child(hbox)
		
		for col in range(row_count):
			var slot = Control.new()
			slot.custom_minimum_size = slot_size
			slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
			hbox.add_child(slot)
			
			var tube = TUBE_SCENE.instantiate()
			tube.name = "Tube_" + str(index)
			tube.position = slot.custom_minimum_size / 2.0
			tube.scale = Vector2(current_scale, current_scale)
			slot.add_child(tube)
			tube.input_event.connect(_on_tube_clicked.bind(tube))
			created_tubes.append(tube)
			index += 1
			
	current_tubes = created_tubes
	await get_tree().process_frame
	await get_tree().process_frame
	
	if not is_instance_valid(level_holder):
		return
	
	for i in range(created_tubes.size()):
		var tube = created_tubes[i]
		var tube_colors = level_data[i]
		for color_name in tube_colors:
			var new_ball = BALL_SCENE.instantiate()
			var target_color = CAR_COLORS[color_name]
			new_ball.set_car_sprite(color_name, target_color)
			new_ball.scale = Vector2(current_scale, current_scale)
			level_holder.add_child(new_ball)
			new_ball.global_position = tube.get_next_available_position()
			new_ball.z_index = 5
			tube.ball_stack.append(new_ball)
			
func _on_tube_clicked(viewport: Node, event: InputEvent, shape_idx: int, clicked_tube: Area2D):
	
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var from_tube = selected_tube
		var to_tube = clicked_tube
		
		# Tüpe tıklama
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
		elif selected_tube == clicked_tube:
			var from_top_ball = selected_tube.ball_stack.back()
			from_top_ball.global_position.y += HOVER_HEIGHT
			selected_tube = null
			$CarTouchSound.play()
		
		# Dolu olan başka tüpe tıklama
		elif to_tube.ball_stack.size() >= to_tube.MAX_CAPACITY:
			var from_top_ball = selected_tube.ball_stack.back()
			from_top_ball.global_position.y += HOVER_HEIGHT
			var to_top_ball = to_tube.ball_stack.back()
			to_top_ball.global_position.y -= HOVER_HEIGHT
			selected_tube = to_tube
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
					target_top_ball.global_position.y -= HOVER_HEIGHT
					$CarTouchSound.play()
					selected_tube = to_tube
					return
			
			# Hareket eden topları arraye kaydetme. Geri alma işlemi için.
			move_history.append({
				"from_tube": from_tube,
				"to_tube": to_tube,
				"ball": ball_to_move
			})
			var target_pos = to_tube.get_next_available_position()
			from_tube.ball_stack.pop_back()
			to_tube.ball_stack.append(ball_to_move) 
			balls_in_transit.append(ball_to_move) 
			move_car_to_tube(ball_to_move, from_tube, to_tube, target_pos)
			selected_tube = null
		
func check_all_tubes() -> bool:
	if not balls_in_transit.is_empty():
		return false	
		
	for tube in current_tubes:  
		if not (tube is Tube):
			continue
		var stack = tube.ball_stack
		if stack.is_empty():
			continue
		if stack.size() < tube.MAX_CAPACITY:
			return false
		var first_color = stack[0].ball_color_name
		for ball in stack:
			if ball.ball_color_name != first_color:
				return false
	return true
	
func level_up():
	current_level += 1	
	build_level()
	
func restart_level():
	if not balls_in_transit.is_empty():
		return
	if is_instance_valid(level_holder):
		level_holder.queue_free()
		level_holder = null
	build_level()
	
func undo_move():
	if move_history.is_empty():
		return
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
	
func play_victory_transition():
	if not is_instance_valid(victory_layer) or not is_instance_valid(victory_text):
		level_up()
		return
	
	victory_text.text = PRAISE_TEXTS.pick_random()
	victory_layer.visible = true
	victory_text.pivot_offset = victory_text.size / 2.0
	victory_text.scale = Vector2.ZERO
	victory_text.modulate.a = 0.0 
	$NextLevel.play()
	
	var tween = create_tween()
	
	tween.set_parallel(true)
	tween.tween_property(victory_text, "modulate:a", 1.0, 0.2)
	tween.tween_property(victory_text, "scale", Vector2(1.15, 1.15), 1.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	tween.chain().tween_property(victory_text, "scale", Vector2(1.0, 1.0), 0.1)
	tween.tween_interval(0.4)
	
	tween.chain().set_parallel(true)
	tween.tween_property(victory_text, "modulate:a", 0.0, 0.25)
	tween.tween_property(victory_text, "scale", Vector2(1.3, 1.3), 0.25)
	
	tween.chain().tween_callback(func():
		victory_layer.visible = false
		level_up() 
	)	
	
func get_safe_transit_y(from_tube, to_tube) -> float:
	var top_row_min_y = INF
	var bottom_row_min_y = INF
	
	for tube in current_tubes:
		var tube_top_y = tube.global_position.y - (tube.size.y / 2.0 if "size" in tube else 0.0)
		
		if tube.global_position.y < ROW_SPLIT_Y:
			if tube_top_y < top_row_min_y:
				top_row_min_y = tube_top_y
		else:
			if tube_top_y < bottom_row_min_y:
				bottom_row_min_y = tube_top_y
	var is_from_bottom = from_tube.global_position.y > ROW_SPLIT_Y
	var is_to_bottom = to_tube.global_position.y > ROW_SPLIT_Y
	
	if is_from_bottom and is_to_bottom:
		return bottom_row_min_y - TRANSIT_MARGIN
		
	return top_row_min_y - TRANSIT_MARGIN
	
func move_car_to_tube(car: Node2D, from_tube: Node2D, to_tube: Node2D, target_pos: Vector2):
	var is_from_bottom = from_tube.global_position.y > ROW_SPLIT_Y
	var is_to_bottom = to_tube.global_position.y > ROW_SPLIT_Y
	var is_from_top = not is_from_bottom
	var is_to_top = not is_to_bottom
	var tween = create_tween().set_parallel(false)
	var car_rot_speed = 0.15
	var car_speed = 0.35
	
	if is_from_bottom and is_to_top:
		# En yakın kenarı seç
		var top_transit_y = get_safe_transit_y(from_tube, to_tube)
		var side_x = get_dynamic_side_x(from_tube)
		var is_left = side_x < from_tube.global_position.x
		var mid_transit_y = from_tube.global_position.y - 330.0
		car.rotation = 0.0
		tween.tween_property(car, "global_position:y", mid_transit_y, car_speed)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		
		if is_left: # Soldan yukarı
			
			# Sola dön ve sol kenara git
			tween.tween_property(car, "rotation", deg_to_rad(-90), car_rot_speed)\
				.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
			tween.tween_property(car, "global_position:x", side_x, car_speed)\
				.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
			
			# Yukarı dön ve tavana kadar tırman
			tween.tween_property(car, "rotation", deg_to_rad(0), car_rot_speed)\
				.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tween.tween_property(car, "global_position:y", top_transit_y, car_speed)\
				.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			
			# Sağa tüplere doğru dön ve hedef tüpün X hizasına git
			tween.tween_property(car, "rotation", deg_to_rad(90), car_rot_speed)\
				.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
			tween.tween_property(car, "global_position:x", target_pos.x, car_speed)\
				.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
			
			# Dikleş
			tween.tween_property(car, "rotation", deg_to_rad(0), car_rot_speed)\
				.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
				
		else: # Sağdan yukarı
			# Sağa dön ve sağ kenara git
			tween.tween_property(car, "rotation", deg_to_rad(90), car_rot_speed)\
				.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
			tween.tween_property(car, "global_position:x", side_x, car_speed)\
				.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
			
			# Yukarı dön ve tavana kadar git
			tween.tween_property(car, "rotation", deg_to_rad(0), car_rot_speed)\
				.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tween.tween_property(car, "global_position:y", top_transit_y, car_speed)\
				.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			
			# Sola tüplere doğru dön ve hedef tüpün X hizasına git
			tween.tween_property(car, "rotation", deg_to_rad(-90), car_rot_speed)\
				.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
			tween.tween_property(car, "global_position:x", target_pos.x, car_speed)\
				.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
			
			# Dikleş 
			tween.tween_property(car, "rotation", deg_to_rad(0), car_rot_speed)\
				.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
		
		# Üst tüpün içine iniş ve açıyı sıfırlama
		tween.tween_property(car, "global_position:y", target_pos.y, car_speed)\
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.tween_callback(func(): car.rotation = 0.0)
	
	elif is_from_top and is_to_bottom:
		# En yakın kenarı seç
		var side_x = get_dynamic_side_x(from_tube)
		var is_left = side_x < from_tube.global_position.x
		var top_transit_y = get_safe_transit_y(from_tube, to_tube) # En üst tavan
		var bottom_entry_y = to_tube.global_position.y - 330.0    # Alt tüpün hemen üst hizası
		
		# Tüpten çık
		tween.tween_property(car, "global_position:y", top_transit_y, car_speed)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			
		if is_left: # Soldan aşağı iniş
			# Sola dön ve kenara git
			tween.tween_property(car, "rotation", deg_to_rad(-90), car_rot_speed)\
				.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
			tween.tween_property(car, "global_position:x", side_x, car_speed)\
				.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
			
			# Aşağı dön ve in
			tween.tween_property(car, "rotation", deg_to_rad(-180), car_rot_speed)\
				.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tween.tween_property(car, "global_position:y", bottom_entry_y, car_speed)\
				.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			
			# Sağa tüplere doğru dön ve hizaya gir
			tween.tween_property(car, "rotation", deg_to_rad(-270), car_rot_speed)\
				.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
			tween.tween_property(car, "global_position:x", target_pos.x, car_speed)\
				.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
			
			# Dikleş 
			tween.tween_property(car, "rotation", deg_to_rad(-360), car_rot_speed)\
				.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
				
		else: #Sağdan aşağı iniş
			
			# Sağa dön ve kenara git
			tween.tween_property(car, "rotation", deg_to_rad(90), car_rot_speed)\
				.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
			tween.tween_property(car, "global_position:x", side_x, car_speed)\
				.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
			
			# Aşağı dön ve in
			tween.tween_property(car, "rotation", deg_to_rad(180), car_rot_speed)\
				.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tween.tween_property(car, "global_position:y", bottom_entry_y, car_speed)\
				.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			
			# Sola tüplere doğru dön ve hizaya gir
			tween.tween_property(car, "rotation", deg_to_rad(270), car_rot_speed)\
				.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
			tween.tween_property(car, "global_position:x", target_pos.x, car_speed)\
				.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
			
			# Dikleş
			tween.tween_property(car, "rotation", deg_to_rad(360), car_rot_speed)\
				.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
		
		# Tüpün içine iniş ve açıyı sıfırlama
		tween.tween_property(car, "global_position:y", target_pos.y, car_speed)\
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.tween_callback(func(): car.rotation = 0.0)
		
	else: # Aynı katta ise
		var transit_y = get_safe_transit_y(from_tube, to_tube)
		
		# Kendi tüpünden tavana çık
		tween.tween_property(car, "global_position:y", transit_y, car_speed)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		
		# Sağa / Sola dön
		if target_pos.x > car.global_position.x:
			tween.tween_property(car, "rotation", deg_to_rad(90), car_rot_speed)
		elif target_pos.x < car.global_position.x:
			tween.tween_property(car, "rotation", deg_to_rad(-90), car_rot_speed)
		
		# Hedef X e git
		tween.tween_property(car, "global_position:x", target_pos.x, car_speed)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		
		# Dikleş
		tween.tween_property(car, "rotation", deg_to_rad(0), car_rot_speed)
		
		# Tüpe in
		tween.tween_property(car, "global_position:y", target_pos.y, car_speed)\
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		
	#Animasyonu bitir.
	tween.finished.connect(func():
		balls_in_transit.erase(car)
		if is_instance_valid(to_tube):
			to_tube.check_if_completed(balls_in_transit)
		
		if balls_in_transit.is_empty():
			if check_all_tubes():
				get_tree().create_timer(0.25).timeout.connect(play_victory_transition)
	)	
				
func get_dynamic_side_x(from_tube) -> float:
	var min_x = INF
	var max_x = -INF
	var tube_width = 120.0
	
	for tube in current_tubes:
		if tube.global_position.x < min_x:
			min_x = tube.global_position.x
		if tube.global_position.x > max_x:
			max_x = tube.global_position.x
		if tube.has_node("Sprite2D"):
			var spr = tube.get_node("Sprite2D")
			tube_width = spr.texture.get_width() * spr.global_scale.x
			
	var half_w = tube_width / 2.0
	var left_lane_x = min_x - half_w - SIDE_MARGIN
	var right_lane_x = max_x + half_w + SIDE_MARGIN
	var center_x = (min_x + max_x) / 2.0
	if from_tube.global_position.x < center_x:
		return	left_lane_x
	else:
		return right_lane_x 

func get_tube_base_size() -> Vector2:
	if tube_base_size != Vector2.ZERO:
		return tube_base_size
	var temp_tube = TUBE_SCENE.instantiate()
	add_child(temp_tube)
	var spr: Sprite2D = temp_tube.get_node("Sprite2D")
	tube_base_size = spr.texture.get_size() * spr.scale
	temp_tube.queue_free()
	return tube_base_size
	
func calculate_layout(tube_count: int) -> Dictionary:
	var base_size = get_tube_base_size()
	var max_columns: int
	if tube_count >= 11:
		max_columns = 6
	elif tube_count >= 9:
		max_columns = 5
	else:
		max_columns = 4
	
	var num_rows = ceili(float(tube_count) / max_columns)
	
	var col_gap = base_size.x * COL_GAP_RATIO
	var row_gap = base_size.y * ROW_GAP_RATIO
	var side_lane_width = base_size.x * SIDE_LANE_RATIO
	
	var viewport_size = get_viewport_rect().size
	var usable_width = viewport_size.x - (SIDE_MARGIN * 2)
	var usable_height = viewport_size.y - TOP_MARGIN - BOTTOM_MARGIN
	
	var needed_width = max_columns * base_size.x + (max_columns - 1) * col_gap + 2 * side_lane_width
	var needed_height = num_rows * base_size.y + (num_rows - 1) * row_gap
	
	var scale_x = usable_width / needed_width
	var scale_y = usable_height / needed_height
	var current_scale = clamp(min(scale_x, scale_y), MIN_SCALE, MAX_SCALE)
	
	return {
		"max_columns": max_columns,
		"scale": current_scale,
		"slot_size": base_size * current_scale,
		"horizontal_spacing": int(col_gap * current_scale),
		"vertical_row_gap": int(row_gap * current_scale)
	}
func setup_vbox_layout():
	tubes_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	tubes_vbox.offset_top = TOP_MARGIN
	tubes_vbox.offset_bottom = -BOTTOM_MARGIN
	tubes_vbox.offset_left = 0.0
	tubes_vbox.offset_right = 0.0
	tubes_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
