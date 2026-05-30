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
