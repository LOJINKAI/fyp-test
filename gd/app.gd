#app.tscn

extends Control

@onready var arrow = $arrow
@onready var animation_player = $AnimationPlayer

# Called when the node enters the scene tree for the first time.
func _ready():
	
	if Global.Midas_done == true:
		$VBoxContainer/lily.visible = true
		$VBoxContainer/lily/lily.disabled = false
	if Global.Lily_done == true:
		$VBoxContainer/jane.visible = true
		$VBoxContainer/jane/jane.disabled = false
	 
	if Global.Jane_done == true:
		$VBoxContainer/stanley.visible = true
		$VBoxContainer/stanley/stanley.disabled = false
		
		
	if Global.Stanley_done == true:
		pass
	
	
	#tutorial part
	
	var new_game = Global.new_game
	var lang = Global.current_language
	var story = Global.story[lang].get("app_intro")
	
	
	#if is new game then tutorial
	if Global.app_tutorial_finished == false:
		Global.play_dialogue(story)
		
		# 🟩 暴力抓取法：既然刚加进当前 scene，那它一定是当前 scene 的最后一个子节点！
		var current_scene = get_tree().current_scene
		var active_dialogue = current_scene.get_child(current_scene.get_child_count() - 1)
		
		
		
		
	if Global.app_tutorial_finished == false:
		arrow.visible = true
		animation_player.play("arrow")
		$top/MarginContainer/HBoxContainer/quit.disabled = true
		$VBoxContainer/boss/boss.disabled = true

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
	Global.app_tutorial_finished = true
	Global.save_game_status()


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
