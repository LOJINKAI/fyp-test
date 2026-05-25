extends Control


# Called when the node enters the scene tree for the first time.
func _ready():

	
	
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_quit_pressed():
	get_tree().change_scene_to_file("res://scene/phone.tscn")


func _on_next_pressed():
	#get_tree().change_scene_to_file("res://scene/chat.tscn")
	Global.current_chat_name = $next/HBoxContainer/Label.text
	Global.current_chat_avatar = $next/HBoxContainer/PanelContainer/photo.texture
	
	get_tree().change_scene_to_file("res://scene/bio.tscn")



func _on_boss_pressed():
	get_tree().change_scene_to_file("res://scene/boss_chat.tscn")
	
