extends Control


var lang = Global.current_language
var npc = Global.current_chat_name
var npc_done = npc + "_done"





# Called when the node enters the scene tree for the first time.
func _ready():
	$HBoxContainer/PanelContainer/photo.texture = Global.current_chat_avatar
	$HBoxContainer/name.text = Global.current_chat_name
	
	$bio_card/ScrollContainer/MarginContainer/bio_content.text = Global.current_bio[lang].get(npc)
	
	var story = Global.story[lang].get("bio_intro")
	
	
	#if is new game then tutorial
	if Global.bio_tutorial_finished == false:
		Global.play_dialogue(story)
		Global.bio_tutorial_finished = true
		Global.save_game_status()
	




# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
		
	



func _on_quit_pressed():
	SoundEffect.play_sound("ui_click")
	get_tree().change_scene_to_file("res://scene/app.tscn")
	
	#Global.current_chat_avatar = null
	#Global.current_chat_name = null
	





func _on_chat_button_pressed():
	SoundEffect.play_sound("ui_click")
	get_tree().change_scene_to_file("res://scene/chat.tscn")
	Global.current_chat_name = $HBoxContainer/name.text
	Global.current_chat_avatar = $HBoxContainer/PanelContainer/photo.texture
	
	Global.bio_tutorial_finished = true
	Global.save_game_status()


