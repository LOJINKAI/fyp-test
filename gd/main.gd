#main.tscn

extends Control


var current_time = Time.get_datetime_string_from_system(false, true)
@onready var time = $"time"


const SETTING_POPUP_SCENE = preload("res://scene/setting_popup.tscn") 




func _ready():
	
	Bgm.play_music("main")
	
	$black_cover.visible = false
	$black_cover.mouse_filter = MOUSE_FILTER_IGNORE
	
	
	
	

func _on_quit_pressed():
	SoundEffect.play_sound("ui_click")
	get_tree().quit()



func _on_continue_pressed():
	SoundEffect.play_sound("ui_click")
	
	if Global.check_story("chat_intro"):
		

		var current_story = Global.story[Global.current_language].get("chat_intro")
		

		Global.play_dialogue(current_story)
		
		$black_cover.visible = true
		$black_cover.mouse_filter = MOUSE_FILTER_STOP
		

		var current_scene = get_tree().current_scene
		var active_dialogue = current_scene.get_child(current_scene.get_child_count() - 1)
		
		if active_dialogue:
			active_dialogue.tree_exited.connect(_on_intro_finished)
	
	get_tree().change_scene_to_file("res://scene/phone.tscn")
	
	
	

func _on_start_pressed():
	SoundEffect.play_sound("ui_click")
	Bgm.play_music("game")
	
	Global.reset_and_new_game()
	
	
	
	var story = Global.story[Global.current_language].get("story_intro")
	
	Global.play_dialogue(story)
	
	$black_cover.visible = true
	$black_cover.mouse_filter = MOUSE_FILTER_STOP
	

	
	var current_scene = get_tree().current_scene
	var active_dialogue = current_scene.get_child(current_scene.get_child_count() - 1)
	
	if active_dialogue:
		active_dialogue.tree_exited.connect(_on_intro_finished)
	
	

func _on_intro_finished():
	
	Global.advance_story()
	
	await get_tree().create_timer(2.0).timeout
	
	get_tree().change_scene_to_file("res://scene/phone.tscn")
	
	#Global.fade_to_fade("res://scene/phone.tscn", 1.0)
	
	
	#Global.fade_to_scene("res://scene/phone.tscn", 1.0)


func _on_setting_pressed():
	SoundEffect.play_sound("ui_click")
	
	var popup = SETTING_POPUP_SCENE.instantiate()
	
	get_tree().current_scene.add_child(popup)
	

	



