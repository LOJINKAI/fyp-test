extends Control


var lang = Global.current_language
var npc = Global.current_chat_name
var npc_done = npc + "_done"
var npc_block = npc + "_current_block"


#block button
@onready var block_button := $top/MarginContainer/HBoxContainer/block

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
	
	if Global.get(npc_done) == false:
		block_button.disabled = true
		
	
	if Global.get(npc_block) == true:
		# 2. 🎮 游戏性包装：给玩家一个视觉反馈，比如让 Chat 按钮直接失效或变灰
		# 提示玩家这个人已经被屏蔽了，符合真实社交软件的逻辑
		$chat_button.disabled = true
		$chat_button.text = "已屏蔽 (Blocked)"
	





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
	
	Global.bio_tutorial_finished = true
	Global.save_game_status()

func _on_block_pressed():
	# 1. 🟥 核心：一键调用全局粉碎函数，把上一个人的 json 记录直接物理抹去！
	Global.reset_victim_chat_history()
	Global.set(npc_block,true)
	Global.save_victim_states()
	
	$chat_button.disabled = true
	$chat_button.text = "已屏蔽 (Blocked)"
	
	
	# 3. （可选项）你可以打印一行提示，或者播一个音效

