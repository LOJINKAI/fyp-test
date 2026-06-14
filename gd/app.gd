#app.tscn

extends Control

@onready var arrow = $arrow
@onready var animation_player = $AnimationPlayer
@onready var target_avatar = $VBoxContainer/all/all/HBoxContainer/PanelContainer/photo
@onready var target_name = $VBoxContainer/all/all/HBoxContainer/Label


var lang = Global.current_language 
var app_tutorial_finished 
var story


#for quick game end

var quick_end_button_click_count = 0 
const quick_end_button_max_click = 6


func _ready():
	arrow.visible = false
	
	app_tutorial_finished = Global.app_tutorial_finished
	
	show_target()
	
	
	var targets = ["Midas", "Lily", "Jane", "Stanley", "Simon"]
	var all_targets_scammed = true # 默认设为全过
	
	
	for target in targets:
		if Global.get(target + "_done") == false:
			all_targets_scammed = false
			break 
			
			
	if all_targets_scammed == true:
		game_end()
	
	#for testing only
	#game_end()
	
	if Global.check_story("app_intro1"):
		play_app_intro1()
		$VBoxContainer/midas.visible = false
		$VBoxContainer/midas/midas.disabled = true
		
		
	elif Global.check_story("app_intro2"):
		$VBoxContainer/midas.visible = true
		$VBoxContainer/midas/midas.disabled = false
		play_app_intro2()
		
		
	
	
	
func show_target():
	
	var targets = ["Midas", "Lily", "Jane", "Stanley", "Simon"] 
	
	var is_previous_done = true 
	
	for target in targets:
		
		var is_done = Global.get(target + "_done")
		
		
		var node_name = target.to_lower()
		var target_ui = $VBoxContainer.get_node(node_name)
		var target_btn = target_ui.get_node(node_name)
		
		
		
		
		if is_done:
			
			target_ui.visible = false
			target_btn.disabled = true
		elif is_previous_done:
			
			target_ui.visible = true
			target_btn.disabled = false
			is_previous_done = false
			
			Global.current_chat_name = target
			
		else:
			
			target_ui.visible = false
			target_btn.disabled = true
			
		
		is_previous_done = is_done 
	
	
	
	



func play_app_intro1():
	#tutorial part

	#if is new game then tutorial
	
	story = Global.story[lang].get("app_intro1")
	
	Global.play_dialogue(story)
	
	
	var current_scene = get_tree().current_scene
	var active_dialogue = current_scene.get_child(current_scene.get_child_count() - 1)
	
	if active_dialogue:
			active_dialogue.tree_exited.connect(_on_app_intro1_finished)


func _on_app_intro1_finished():
	arrow.visible = true
	animation_player.play("arrow")
	
	Global.advance_story()
	Global.save_game_status()
	


func play_app_intro2():
	story = Global.story[lang].get("app_intro2")
	
	Global.play_dialogue(story)
	
	
	var current_scene = get_tree().current_scene
	var active_dialogue = current_scene.get_child(current_scene.get_child_count() - 1)
	
	if active_dialogue:
			active_dialogue.tree_exited.connect(_on_app_intro2_finished)

func _on_app_intro2_finished():
	
	arrow.position.y = 200
	arrow.visible = true
	animation_player.play("arrow")
	
	Global.advance_story()
	Global.save_game_status()
	



func game_end():
	
	$VBoxContainer/group/group.disabled = true
	$top/MarginContainer/HBoxContainer/PanelContainer/quit.disabled = true
	
	
	
	var full_story = Global.story[lang].get("story_end1").duplicate()
	var last_sentence = [full_story.pop_back()] 
	
	
	Global.play_dialogue(full_story)
	Bgm.play_music("before_police")
	
	
	var current_scene = get_tree().current_scene
	var active_dialogue = current_scene.get_child(current_scene.get_child_count() - 1)

	if active_dialogue:
		
		active_dialogue.tree_exited.connect(func(): _on_story_end1_pre_final(last_sentence))


func _on_story_end1_pre_final(last_sentence):
	
	Global.play_dialogue(last_sentence)
	
	await get_tree().create_timer(0.02).timeout 
	var current_scene = get_tree().current_scene
	var active_dialogue = current_scene.get_child(current_scene.get_child_count() - 1)
	
	if active_dialogue:
		
		var black_bg = ColorRect.new()
		black_bg.name = "MovieBlackBG"
		black_bg.color = Color(0, 0, 0, 0.0) 
		black_bg.size = get_viewport_rect().size 
		black_bg.z_index = 4000 
		
		current_scene.add_child(black_bg)
		
		current_scene.move_child(black_bg, active_dialogue.get_index())
		
		
		var tween = create_tween()
		tween.tween_property(black_bg, "color", Color(0, 0, 0, 1.0), 1.5)
		
		
		
		
		active_dialogue.tree_exited.connect(_on_end1_finished)


func _on_end1_finished():
	
	if FileAccess.file_exists("user://game_status.json"):
		DirAccess.remove_absolute("user://game_status.json")
	if FileAccess.file_exists("user://victim_status.json"):
		DirAccess.remove_absolute("user://victim_status.json")
	
	
	var black_bg = get_tree().current_scene.get_node_or_null("MovieBlackBG")
	if black_bg:
		black_bg.color = Color(0, 0, 0, 1.0)
	
	
	
	await get_tree().create_timer(2.0).timeout
	
	
	if black_bg:
		black_bg.queue_free()
		
	
	
	var story2 = Global.story[lang].get("story_end2")
	
	SceneSoundEffect.play_sound("kick_door_sound")
	Global.play_dialogue(story2)
	
	
	Bgm.play_music("police")
	
	
	var current_scene = get_tree().current_scene
	var active_dialogue = current_scene.get_child(current_scene.get_child_count() - 1)

	if active_dialogue:
		active_dialogue.tree_exited.connect(_on_end2_finished)
	
func _on_end2_finished():
	
	
	$end_cover.visible = true
	
	Global.fade_to_fade("res://scene/main.tscn", 2.0)
	
	





func _on_quit_pressed():
	SoundEffect.play_sound("ui_click")
	get_tree().change_scene_to_file("res://scene/phone.tscn")




func _on_midas_pressed():
	SoundEffect.play_sound("ui_click")
	Global.current_chat_name = $VBoxContainer/midas/midas/HBoxContainer/Label.text
	Global.current_chat_avatar = $VBoxContainer/midas/midas/HBoxContainer/PanelContainer/photo.texture
	
	get_tree().change_scene_to_file("res://scene/bio.tscn") 
	Global.app_tutorial_finished = true
	Global.save_game_status()
	
	print("MIdas!")


func _on_lily_pressed():
	SoundEffect.play_sound("ui_click")
	
	Global.current_chat_name = $VBoxContainer/lily/lily/HBoxContainer/Label.text
	Global.current_chat_avatar = $VBoxContainer/lily/lily/HBoxContainer/PanelContainer/photo.texture
	
	get_tree().change_scene_to_file("res://scene/bio.tscn") 
	

func _on_jane_pressed():
	SoundEffect.play_sound("ui_click")
	Global.current_chat_name = $VBoxContainer/jane/jane/HBoxContainer/Label.text
	Global.current_chat_avatar =$VBoxContainer/jane/jane/HBoxContainer/PanelContainer/photo.texture
	
	get_tree().change_scene_to_file("res://scene/bio.tscn") 


func _on_stanley_pressed():
	SoundEffect.play_sound("ui_click")
	Global.current_chat_name = $VBoxContainer/stanley/stanley/HBoxContainer/Label.text
	Global.current_chat_avatar =$VBoxContainer/stanley/stanley/HBoxContainer/PanelContainer/photo.texture
	
	get_tree().change_scene_to_file("res://scene/bio.tscn") 


func _on_simon_pressed():
	SoundEffect.play_sound("ui_click")
	Global.current_chat_name = $VBoxContainer/simon/simon/HBoxContainer/Label.text
	Global.current_chat_avatar = $VBoxContainer/simon/simon/HBoxContainer/PanelContainer/photo.texture
	
	
	get_tree().change_scene_to_file("res://scene/bio.tscn") 


func _on_group_pressed():
	SoundEffect.play_sound("ui_click")
	get_tree().change_scene_to_file("res://scene/group.tscn") 


func _on_quick_end_pressed():
	quick_end_button_click_count += 1  # 每次按都加 1
	
	print("now already click ", quick_end_button_click_count, " times")
	
	if quick_end_button_click_count >= quick_end_button_max_click:
		game_end()
		quick_end_button_click_count = 0 # 触发后重置，或者根据你的需求决定是否重置
	
	
	
	
	
	
	
	
