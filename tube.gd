extends Area2D

var ball_stack = []
const max_capasity = 4
const ball_spacing = 50.0
const bottom_y = 100.0
var slot_positions: Array = []# Bu tüpün sahnedeki konumlarına erişmek için pozisyon listesi üretiyoruz

func _ready() -> void:
	for i in range(max_capasity):
		var slot_y = bottom_y - (i * ball_spacing)
		slot_positions.append(Vector2(0, slot_y))


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func get_next_available_position() -> Vector2:
	var current_size = ball_stack.size()
	if current_size < max_capasity:
		return global_position + slot_positions[current_size]
	return global_position

func _on_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		print(name, " tüpüne tıklandı! İçindeki top sayısı: ", ball_stack.size())
