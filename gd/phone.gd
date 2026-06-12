#phone.tscn

extends Control




@onready var arrow = $arrow
@onready var animation_player = $AnimationPlayer



var lang = Global.current_language




func _ready():
	arrow.visible = false
	
	Bgm.play_music("game")
	
	
	if Global.check_story("phone_intro"):
		
		var current_story = Global.story[Global.current_language].get("phone_intro")
		
		Global.play_dialogue(current_story)
		
		arrow.visible = true
		animation_player.play("arrow")
		
		Global.advance_story()
		Global.save_game_status()

	
	
	#if Global.phone_tutorial_finished == false:
		#
		#var story = Global.story[lang].get("phone_intro")
		#Global.play_dialogue(story)
		#
		#arrow.visible = true
		#animation_player.play("arrow")
		#
		#Global.phone_tutorial_finished = true
		#Global.save_game_status()





func _process(delta):
	pass 


func _on_chat_pressed():
	SoundEffect.play_sound("ui_click")
	get_tree().change_scene_to_file("res://scene/app.tscn")

	



func _on_texture_button_pressed():
	SoundEffect.play_sound("ui_click")
	get_tree().change_scene_to_file("res://scene/main.tscn")
	
	

