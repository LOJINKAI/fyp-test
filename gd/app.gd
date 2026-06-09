#app.tscn

extends Control

@onready var arrow = $arrow
@onready var animation_player = $AnimationPlayer
@onready var target_avatar = $VBoxContainer/all/all/HBoxContainer/PanelContainer/photo
@onready var target_name = $VBoxContainer/all/all/HBoxContainer/Label

var new_game = Global.new_game
var lang = Global.current_language
var app_tutorial_finished 
var story


# Called when the node enters the scene tree for the first time.
func _ready():
	app_tutorial_finished = Global.app_tutorial_finished
	
	
	print("new game = ",new_game)
	print("app_tutorial_finished = ",app_tutorial_finished)
	print("game end = ",Global.game_end)

	if app_tutorial_finished == false:
		tutorial()
		app_tutorial_finished = true
		Global.save_game_status()
	
	show_target()
	
	#game_end()
	
	
	if Global.game_end == true:
		game_end()
		Global.game_end = false
	
func show_target():
	# ========================================================
	# 🌟 核心重构：数据驱动名单 (以后加新受害者，只需要在这个数组里加名字！)
	# ========================================================
	var targets = ["Midas", "Lily", "Jane", "Simon", "Stanley"] 
	
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
	
	
	
	



func tutorial():
	#tutorial part

	#if is new game then tutorial
	
	story = Global.story[lang].get("app_intro")
	
	Global.play_dialogue(story)
	
	# 🟩 暴力抓取法：既然刚加进当前 scene，那它一定是当前 scene 的最后一个子节点！
	var current_scene = get_tree().current_scene
	var active_dialogue = current_scene.get_child(current_scene.get_child_count() - 1)
	
	arrow.visible = true
	animation_player.play("arrow")
		
		


func game_end():
	# 1. 🌟 把 story_end1 拆开，剥离最后一句
	var full_story = Global.story[lang].get("story_end1").duplicate()
	var last_sentence = [full_story.pop_back()] 
	
	# 2. 先播放前面几句普通自白
	Global.play_dialogue(full_story)
	Bgm.play_music("before_police")
	
	
	var current_scene = get_tree().current_scene
	var active_dialogue = current_scene.get_child(current_scene.get_child_count() - 1)

	if active_dialogue:
		# 当这前面几句点完后，立刻无缝接上最后一句
		active_dialogue.tree_exited.connect(func(): _on_story_end1_pre_final(last_sentence))


func _on_story_end1_pre_final(last_sentence: Array):
	# 1. 弹出最后一句绝望的独白
	Global.play_dialogue(last_sentence)
	
	await get_tree().create_timer(0.02).timeout # 稍微等一微秒让对话框节点挂载
	var current_scene = get_tree().current_scene
	var active_dialogue = current_scene.get_child(current_scene.get_child_count() - 1)
	
	if active_dialogue:
		# ========================================================
		# 🌟 绝杀技：在对话框的背后，偷偷铺上一张“铺满全屏的黑布”
		# ========================================================
		var black_bg = ColorRect.new()
		black_bg.name = "MovieBlackBG"
		black_bg.color = Color(0, 0, 0, 0.0) # 初始是完全透明的
		black_bg.size = get_viewport_rect().size # 强制铺满整个手机/电脑屏幕
		black_bg.z_index = 4000 # 极高的层级，确保能盖死底下 app 的所有按钮
		
		# 加进当前场景
		current_scene.add_child(black_bg)
		
		# 🌟 核心：把这块黑布的节点层级，强行移动到对话框的前面！
		# （在 Godot 里，节点越靠后越在顶层，这样就保证了对话框压在黑幕上面！）
		current_scene.move_child(black_bg, active_dialogue.get_index())
		
		# 🎬 伴随着最后一句独白，黑布立刻开始缓慢变黑（耗时 1.5 秒）
		# 这时玩家正在看着字，而背景已经开始沉入黑暗！
		var tween = create_tween()
		tween.tween_property(black_bg, "color", Color(0, 0, 0, 1.0), 1.5)
		
		# 只有当玩家最后点掉这句对话时，才去触发真正的 _on_end1_finished 收尾
		active_dialogue.tree_exited.connect(_on_end1_finished)


func _on_end1_finished():
	# 1. 物理删除垃圾记录
	if FileAccess.file_exists("user://game_status.json"):
		DirAccess.remove_absolute("user://game_status.json")
	if FileAccess.file_exists("user://victim_status.json"):
		DirAccess.remove_absolute("user://victim_status.json")
	
	# ========================================================
	# 此时对话框刚被玩家点掉。由于我们刚才在它背后加了黑布，
	# 现在的屏幕上只会剩下一块纯黑的布！底下的 app 已经被完美遮住了！
	# ========================================================
	
	# 🛡️ 防手贱机制：如果玩家读得太快（1.5秒内就点掉了对话框），我们强制让黑布瞬间变全黑
	var black_bg = get_tree().current_scene.get_node_or_null("MovieBlackBG")
	if black_bg:
		black_bg.color = Color(0, 0, 0, 1.0)
	
	print("⏳ 此时屏幕已完全漆黑，毫无破绽...")
	
	# 2. ⏳ 让空气在黑暗中凝固 0.5 秒，把窒息和绝望感拉满
	await get_tree().create_timer(2.0).timeout
	
	# 3. 💥 撕开黑暗！直接把那块黑布删掉，重见光明！
	if black_bg:
		black_bg.queue_free()
		
	print("✨ 啪！黑布瞬间消失，警察的对话框轰然砸脸！")
	
	# 4. 画面亮起的同一微秒，警察踹门对话框强势弹出！
	var story2 = Global.story[lang].get("story_end2")
	Global.play_dialogue(story2)
	Bgm.play_music("police")
	
	
	var current_scene = get_tree().current_scene
	var active_dialogue = current_scene.get_child(current_scene.get_child_count() - 1)

	if active_dialogue:
		active_dialogue.tree_exited.connect(_on_end2_finished)
	
func _on_end2_finished():
	
	get_tree().change_scene_to_file("res://scene/main.tscn")
	


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
	
	print("MIdas!")


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
