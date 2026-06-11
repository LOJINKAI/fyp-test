#main.tscn

extends Control

# 输出格式示例：2026-05-09 15:30:05
var current_time = Time.get_datetime_string_from_system(false, true)
@onready var time = $"time"

#setting popup
const SETTING_POPUP_SCENE = preload("res://scene/setting_popup.tscn")



# Called when the node enters the scene tree for the first time.
func _ready():
	
	$black_cover.visible = false
	$black_cover.mouse_filter = MOUSE_FILTER_IGNORE
	update_time_display()
	

	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	update_time_display()

func update_time_display():
	# 获取时间字典，包含 hour, minute, second
	var t = Time.get_time_dict_from_system()
	
	# 格式化字符串：
	# %02d 代表：如果数字只有一位，前面自动补 0（比如 9:05 会显示成 09:05）
	# 如果你不需要补 0（比如 9:05 显示成 9:05），把 02 去掉，改成 %d 即可
	var display_time = "%02d:%02d" % [t.hour, t.minute]
	
	time.text = display_time


#quit button
func _on_quit_pressed():
	SoundEffect.play_sound("ui_click")
	get_tree().quit()
	#close game


func _on_continue_pressed():
	SoundEffect.play_sound("ui_click")
	
	if Global.check_story("chat_intro"):
		
		# 2. 🟩 拿到属于当前语言的这段剧情文本数据
		var current_story = Global.story[Global.current_language].get("chat_intro")
		
		# 3. 🟩 本地亲自调用播放，这样你就能直接在这里掌控它的生命周期！
		Global.play_dialogue(current_story)
		
		$black_cover.visible = true
		$black_cover.mouse_filter = MOUSE_FILTER_STOP
		
		# 4. 🟩 重点：动态绑定当前这个对话框的销毁信号到你指定的本地善后函数！
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
	

	
	# 🟩 暴力抓取法：既然刚加进当前 scene，那它一定是当前 scene 的最后一个子节点！
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
	# 1. 动态实例化这个小窗口
	var popup = SETTING_POPUP_SCENE.instantiate()
	
	# 2. 🟩 核心：直接把它作为子节点加到当前主界面最底层
	# 因为 Godot 的渲染规则是“越靠下的节点，渲染在越表面”
	# 它会自动完美覆盖在你的 time、start、setting、quit 之上！
	get_tree().current_scene.add_child(popup)
	

	



