extends Control

@onready var start: Button = $VBoxContainer/Start
@onready var options: Button = $VBoxContainer/Options
@onready var question: Button = $"VBoxContainer/?"
@onready var exit: Button = $VBoxContainer/Exit

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_exit_pressed() -> void:
	get_tree().quit()


func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/World.tscn")
