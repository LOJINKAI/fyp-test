#app.tscn

extends Control

@onready var arrow = $arrow
@onready var animation_player = $AnimationPlayer
@onready var target_avatar = $VBoxContainer/all/all/HBoxContainer/PanelContainer/photo
@onready var target_name = $VBoxContainer/all/all/HBoxContainer/Label



# Called when the node enters the scene tree for the first time.
func _ready():
	
	# ========================================================
	# 🌟 核心重构：数据驱动名单 (以后加新受害者，只需要在这个数组里加名字！)
	# ========================================================
	var targets = ["Midas", "Lily", "Jane", "Stanley","Simon"] 
	
	var is_previous_done = true # 第一把钥匙默认是给的（第一个人默认解锁）
	
	for target in targets:
		# 1. 动态获取全局变量 (比如循环到 "Midas" 时，就自动读取 Global.Midas_done)
		var is_done = Global.get(target + "_done")
		
		# 2. 动态抓取 UI 节点 (把名字转小写，比如 "Midas" 变成 "midas")
		var node_name = target.to_lower()
		var target_ui = $VBoxContainer.get_node(node_name)
		var target_btn = target_ui.get_node(node_name)
		
		
		
		# 3. 核心判定逻辑 (自动隐藏旧的，显示新的)
		if is_done:
			# 情况 A：已经骗成功了 -> 隐藏掉
			target_ui.visible = false
			target_btn.disabled = true
		elif is_previous_done:
			# 情况 B：前一个人骗完了，但这个人还没骗 -> 🌟 这就是当前正在进行的活跃目标！
			target_ui.visible = true
			target_btn.disabled = false
			is_previous_done = false # 把钥匙没收，后面的目标不准解锁！
		else:
			# 情况 C：前面的还没骗完 -> 后面的统统锁定/隐藏
			target_ui.visible = false
			target_btn.disabled = true
			
		# 把当前人的状态传给下一次循环，作为下一个人能否解锁的凭证
		is_previous_done = is_done
	
	
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
		
		arrow.visible = true
		animation_player.play("arrow")


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


func _on_simon_pressed():
	Global.current_chat_name = $VBoxContainer/simon/simon/HBoxContainer/Label.text
	Global.current_chat_avatar = $VBoxContainer/simon/simon/HBoxContainer/PanelContainer/photo.texture
	
	
	get_tree().change_scene_to_file("res://scene/bio.tscn") 
