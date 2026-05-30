#phone.tscn

extends Control




@onready var arrow = $arrow
@onready var animation_player = $AnimationPlayer


# Called when the node enters the scene tree for the first time.
func _ready():
	
	var new_game = Global.new_game
	var finish_tutorial = Global.finish_tutorial
	var lang = Global.current_language
	var story = Global.story[lang].get("intro")
	
	
	
	if new_game == true:
		Global.play_dialogue(story)
		
		# 🟩 暴力抓取法：既然刚加进当前 scene，那它一定是当前 scene 的最后一个子节点！
		var current_scene = get_tree().current_scene
		var active_dialogue = current_scene.get_child(current_scene.get_child_count() - 1)
		
		if active_dialogue:
			active_dialogue.tree_exited.connect(_on_intro_finished)
			print("🎯 成功捕捉到剧情节点：", active_dialogue.name)
	else:
		arrow.visible = false
		
		
	if new_game == false && finish_tutorial == false:
		arrow.visible = true
		animation_player.play("arrow")


func _on_intro_finished():
	# 1. 让带动画的箭头亮亮堂堂地蹦出来！指引玩家
	
	print("finish")
	
	arrow.visible = true
	animation_player.play("arrow")
	
	# 2. 随手关闭新游戏开关，并同步硬盘
	Global.new_game = false
	Global.save_game_status()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass 


func _on_chat_pressed():
	get_tree().change_scene_to_file("res://scene/app.tscn")
	



func _on_texture_button_pressed():
	get_tree().change_scene_to_file("res://scene/main.tscn")
	
	

