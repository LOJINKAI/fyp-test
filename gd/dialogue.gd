# dialogue.gd

extends CanvasLayer

@onready var left_name = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/left
@onready var right_name = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/right
@onready var text_content = $PanelContainer/MarginContainer/VBoxContainer/RichTextLabel

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
	
	# -----------------------------------------------------------------
	# 🟩 核心修改：动态设置名字 (已升级)
	# -----------------------------------------------------------------
	
	# 从数据中获取当前这一句角色的显示名字 (比如 "我 (秘书)" 或 "Lily")
	var current_speaker_name = data["name"]
	
	# 1. 🟥 判断身份，决定名字显示在左边还是右边
	
	if data["speaker"] == "player":
		# 如果是主角说话：
		left_name.text = current_speaker_name # 左边显示主角的名字
		right_name.text = ""                  # 右边名字清空
		
		# 🎨 UI设计师加分（可选）：让左边名字高亮，右边名字变灰（这里只做名字切换逻辑）
		# left_name.add_theme_color_override("font_color", Color.WHITE)
		
	elif data["speaker"] == "npc":
		# 如果是 NPC 或系统说话：
		left_name.text = ""                   # 左边名字清空
		right_name.text = current_speaker_name # 右边显示该 NPC 的名字
		
		# 🎨 UI设计师加分（可选）：让右边名字高亮
		# right_name.add_theme_color_override("font_color", Color.WHITE)
	
	# -----------------------------------------------------------------
	# 🟩 动态设置名字结束
	# -----------------------------------------------------------------
		
	# 播放对话文本 (这一步保持不变)
	text_content.text = data["text"]

# 玩家点击屏幕（或者按空格、回车）时切换下一句
func _input(event):
	if event.is_action_pressed("ui_accept") or (event is InputEventMouseButton and event.pressed):
		current_index += 1
		show_line()
