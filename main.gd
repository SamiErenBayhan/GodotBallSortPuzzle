extends Node2D

const BALL_SCENE = preload("res://ball.tscn")
const TUBE_SCENE = preload("res://Tube.tscn")

var color_dict = {
	"Kırmızı": Color.RED,
	"Mavi": Color.BLUE,
	"Yeşil": Color.GREEN,
	"Sarı": Color.YELLOW
}
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	generate_level()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func generate_level():
	var level_data = [
		["Kırmızı", "Mavi", "Kırmızı", "Mavi"],  # 0. Tüpün renkleri
		["Mavi", "Kırmızı", "Mavi", "Kırmızı"],  # 1. Tüpün renkleri
		[]                                       # 2. Tüp (Boş tüp)
	]
	for i in range(level_data.size()):
		var new_tube = TUBE_SCENE.instantiate()
		new_tube.global_position = Vector2(150 + (i * 200), 400)
		new_tube.name = "Tube_" + str(i)
		add_child(new_tube)
		new_tube.input_event.connect(_on_tube_clicked.bind(new_tube))

		var tube_colors = level_data[i]
		for color_name in tube_colors:
			var new_ball = BALL_SCENE.instantiate()
			var target_color = color_dict[color_name]
			new_ball.set_ball_color(color_name, target_color)
			new_ball.global_position = new_tube.get_next_available_position()
			add_child(new_ball)
			new_tube.ball_stack.append(new_ball)
			
func _on_tube_clicked(viewport: Node, event: InputEvent, shape_idx: int, clicked_tube: Area2D):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		print("Main Script Algıladı -> Tıklanan Tüp: ", clicked_tube.name)
	
