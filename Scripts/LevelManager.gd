extends Node

const CARS =["Red", "Green", "Blue", "Yellow", "Orange", "Purple", "Pink", "White", "Turquoise"]
const TUBE_CAPACITY = 4

var all_levels_data: Dictionary = {} 

var is_production_mode : bool = false

func _ready() -> void:
	randomize()
	
	if is_production_mode:
		# Önce eski denemeleri/bölümleri tamamen temizle
		reset_json_file()
		#Bölüm üretme sayısı
		generate_full_game_package(5, 3, 2)
		# Üretim bittikten sonra hafızayı son haliyle güncelle
		load_levels_from_json()
	else:
		#Sadece var olan hazır bölümleri dosyadan oku
		load_levels_from_json()

func create_board(filled_tube: int, empty_tube: int) -> Array:
	var board = []
	for i in range(filled_tube):
		var color = CARS[i]
		var new_tube = []
		for j in range(TUBE_CAPACITY):
			new_tube.append(color)
		board.append(new_tube)
		
	for i in range(empty_tube):
		board.append([])
		
	return board
	
func make_random_move(board: Array) -> bool:
	var tube_size = board.size()
	var from_index = randi() % tube_size 
	var to_index = randi() % tube_size
	
	if from_index == to_index:
		return false
	
	var from_tube = board[from_index]
	var to_tube = board[to_index]
	
	if from_tube.size() == 0:
		return false
		
	if to_tube.size() >= TUBE_CAPACITY:
		return false
	
	var moving_car = from_tube.pop_back()
	to_tube.append(moving_car)
	
	return true
	
func is_board_valid(board: Array, expected_full_tubes: int) -> bool:
	var full_tube_count = 0
	
	for tube in board:
		# Eğer tüp tamamen doluysa sayacı artır
		if tube.size() == TUBE_CAPACITY:
			full_tube_count += 1
		# Eğer tüp ne tamamen dolu ne de tamamen boşsa (örn: 1, 2 veya 3 araba varsa) bu tahta geçersizdir!
		elif tube.size() > 0 and tube.size() < TUBE_CAPACITY:
			return false
			
	# Tamamen dolu olan tüp sayısı, oyunun başındaki orijinal dolu tüp sayısına eşit olmalı
	return full_tube_count == expected_full_tubes

func has_too_many_matching_cars(board: Array) -> bool:
	for tube in board:
		if tube.size() >= 3:
			var match_count = 1
			for i in range(1, tube.size()):
				if tube[i] == tube[i - 1]:
					match_count += 1
					if match_count >= 3:
						return true
				else:
					match_count = 1		
	return false	

func generate_level(dificulty: String) -> Array:
	
	var filled_tubes = 5
	var empty_tubes = 2
	var shuffle_moves = 250
	
	if dificulty == "Medium":
		filled_tubes = 7
		shuffle_moves = 350
		
	elif dificulty == "Hard":
		filled_tubes = 9
		shuffle_moves = 400
			
	while true:
		var new_board = create_board(filled_tubes, empty_tubes)
	
		var successful_moves = 0
		while successful_moves < shuffle_moves:
			if make_random_move(new_board):
				successful_moves += 1
			
		if is_board_valid(new_board, filled_tubes) and not has_too_many_matching_cars(new_board):
			return new_board
	return []		

func load_levels_from_json():
	var file_path = "res://levels.json"
	if FileAccess.file_exists(file_path):
		var file = FileAccess.open(file_path, FileAccess.READ)
		var json_text = file.get_as_text()
		file.close()
		
		# Metni godotun anlayacağı Dictionary formatına çeviriyoruz
		var json = JSON.new()
		var error = json.parse(json_text)
		
		if error == OK:
			all_levels_data = json.data
			print("Bölümler başarıyla yüklendi! Toplam Bölüm: ", all_levels_data.size())
		else:
			print("JSON ayrıştırma hatası! Satır: ", json.get_error_line())
	else:
		print("HATA: levels.json dosyası bulunamadı!")
	
func save_level_to_json(new_level_layout: Array	) -> void:
	var file_path = "res://levels.json"
	load_levels_from_json()
	var next_level_number = 1
	if not all_levels_data.is_empty():
		var highest_number = 0
		for key in all_levels_data.keys():
			if key.to_int() > highest_number:
				highest_number = key.to_int()
		next_level_number = highest_number + 1
		
	var new_level_key = str(next_level_number)
	all_levels_data[new_level_key] = new_level_layout
	var updated_json_text = JSON.stringify(all_levels_data, "\t")
	
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	file.store_string(updated_json_text)
	file.close()
	
	print("Success! Level ", new_level_key, " has been generated and saved to JSON.")	
	
func reset_json_file() -> void:
	var file = FileAccess.open("res://levels.json", FileAccess.WRITE)
	file.store_string("{}")
	file.close()
	print("JSON file has been successfully reset for a clean production.")
	
func generate_full_game_package(easy_count: int, medium_count: int, hard_count: int) -> void:
	print("Mega level generation process started...")
	
	# Kolay 
	for i in range(easy_count):
		var layout = generate_level("Easy") # senin daha önce yazdığın karıştırma fonksiyonu
		save_level_to_json(layout)
		
	# Orta
	for i in range(medium_count):
		var layout = generate_level("Medium")
		save_level_to_json(layout)
		
	# Zor
	for i in range(hard_count):
		var layout = generate_level("Hard")
		save_level_to_json(layout)
		
	print("SUCCESS! Total of ", easy_count + medium_count + hard_count, " levels generated and saved!")
	
