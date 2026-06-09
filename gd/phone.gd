#phone.tscn

extends Control




@onready var arrow = $arrow
@onready var animation_player = $AnimationPlayer



var lang = Global.current_language



# Called when the node enters the scene tree for the first time.
func _ready():
	arrow.visible = false
	
	Bgm.play_music("game")
	
	
	
	if Global.phone_tutorial_finished == false:
		
		var story = Global.story[lang].get("phone_intro")
		Global.play_dialogue(story)
		
		arrow.visible = true
		animation_player.play("arrow")
		
		Global.phone_tutorial_finished = true
		Global.save_game_status()





# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass 


func _on_chat_pressed():
	SoundEffect.play_sound("ui_click")
	get_tree().change_scene_to_file("res://scene/app.tscn")

	



func _on_texture_button_pressed():
	SoundEffect.play_sound("ui_click")
	get_tree().change_scene_to_file("res://scene/main.tscn")
	
	

