extends Control


# Called when the node enters the scene tree for the first time.
func _ready():

	
	
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_quit_pressed():
	get_tree().change_scene_to_file("res://scene/phone.tscn")


func _on_boss_pressed():
	get_tree().change_scene_to_file("res://scene/boss_chat.tscn") 




func _on_midas_pressed():
	Global.current_chat_name = $VBoxContainer/midas/midas/HBoxContainer/Label.text
	Global.current_chat_avatar = $VBoxContainer/midas/midas/HBoxContainer/PanelContainer/photo.texture
	
	get_tree().change_scene_to_file("res://scene/bio.tscn") 


func _on_lily_pressed():
	#get_tree().change_scene_to_file("res://scene/chat.tscn")
	Global.current_chat_name = $VBoxContainer/lily/lily/HBoxContainer/Label.text
	Global.current_chat_avatar = $VBoxContainer/lily/lily/HBoxContainer/PanelContainer/photo.texture
	
	get_tree().change_scene_to_file("res://scene/bio.tscn") 
	

func _on_jane_pressed():
	Global.current_chat_name = $VBoxContainer/jane/jane/HBoxContainer/Label.text
	Global.current_chat_avatar =$VBoxContainer/jane/jane/HBoxContainer/PanelContainer/photo.texture
	
	get_tree().change_scene_to_file("res://scene/bio.tscn") 


func _on_stanley_pressed():
	Global.current_chat_name = $VBoxContainer/stanley/stanley/HBoxContainer/Label.text
	Global.current_chat_avatar =$VBoxContainer/stanley/stanley/HBoxContainer/PanelContainer/photo.texture
	
	get_tree().change_scene_to_file("res://scene/bio.tscn") 
