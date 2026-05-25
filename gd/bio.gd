extends Control


# Called when the node enters the scene tree for the first time.
func _ready():
	$HBoxContainer/PanelContainer/photo.texture = Global.current_chat_avatar
	$HBoxContainer/name.text = Global.current_chat_name
	$bio_card/ScrollContainer/MarginContainer/bio_content.text = Global.current_bio.get(Global.current_chat_name)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_quit_pressed():
	get_tree().change_scene_to_file("res://scene/app.tscn")
	Global.current_chat_avatar = null
	Global.current_chat_name = null
	





func _on_chat_button_pressed():
	get_tree().change_scene_to_file("res://scene/chat.tscn")
	Global.current_chat_name = $HBoxContainer/name.text
	Global.current_chat_avatar = $HBoxContainer/PanelContainer/photo.texture
