extends Node3D

var character: CharacterBody3D

func _ready() -> void:
	character = get_parent().get_child(2) #Hopefully is the character ndoe

func _process(delta: float) -> void:
	pass
