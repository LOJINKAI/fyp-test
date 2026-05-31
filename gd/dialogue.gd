# dialogue.gd

extends CanvasLayer

@onready var left_name = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/left
@onready var right_name = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/right
@onready var text_content = $PanelContainer/MarginContainer/VBoxContainer/RichTextLabel
@onready var left_avatar = $left_avatar
@onready var right_avatar = $right_avatar
@onready var dark = $dark


# 存储当前正在播放的对话数据列表
var current_dialogue_list = []
var current_index = 0

func start_story(dialogue_data: Array):
	current_dialogue_list = dialogue_data
	current_index = 0
	show_line()

func show_line():
	if current_index >= current_dialogue_list.size():
		# 🎭 剧情讲完了，物理粉碎自己，把控制权还给当前 Scene
		queue_free()
		return
		
	var data = current_dialogue_list[current_index]
	var current_speaker_name = data["name"]
	
	# -----------------------------------------------------------------
	# 🖤 新增：全屏纯黑暗黑舞台控制
	# -----------------------------------------------------------------
	# 检查当前数据里有没有写 "scene_black": true
	if data.get("scene_black", false) == true:
		# 1. 把背景色强行拉到纯黑（完全不透明），遮死后面的手机场景
		dark.color = Color(0, 0, 0, 255) 
		
		# 4. 🟥 恢复你原本的正常立绘与名字判断逻辑
		if data["speaker"] == "player":
			left_name.text = current_speaker_name
			right_name.text = ""
			left_avatar.visible = true
			right_avatar.visible = false
			
		elif data["speaker"] == "npc":
			left_name.text = ""
			right_name.text = current_speaker_name
			right_avatar.visible = true
			left_avatar.visible = false
		
	else:
		# 🟩 正常剧情状态：恢复为你原本喜欢的半透明黑底
		# 这里的 0.5 代表半透明度，你可以根据你原本的视觉微调它
		dark.color = Color(0, 0, 0, 0.5) 
		
		# 4. 🟥 恢复你原本的正常立绘与名字判断逻辑
		if data["speaker"] == "player":
			left_name.text = current_speaker_name
			right_name.text = ""
			left_avatar.visible = true
			right_avatar.visible = false
			
		elif data["speaker"] == "npc":
			left_name.text = ""
			right_name.text = current_speaker_name
			right_avatar.visible = true
			left_avatar.visible = false
			
	# -----------------------------------------------------------------
	# 播放对话文本 (保持不变)
	text_content.text = data["text"]



# 玩家点击屏幕（或者按空格、回车）时切换下一句
func _input(event):
	if event.is_action_pressed("ui_accept") or (event is InputEventMouseButton and event.pressed):
		current_index += 1
		show_line()
