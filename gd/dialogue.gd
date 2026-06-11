# dialogue.gd

extends CanvasLayer

@onready var left_name = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/left
@onready var right_name = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/right
@onready var text_content = $PanelContainer/MarginContainer/VBoxContainer/RichTextLabel


@onready var player_avatar = $player
@onready var boss_avatar = $Boss
@onready var police_avatar = $police
@onready var scammer_avatar = $scammer

@onready var dark = $dark


# 存储当前正在播放的对话数据列表
var current_dialogue_list = []
var current_index = 0


@onready var avatar_map := {
	"player": player_avatar,
	"boss": boss_avatar,
	"scammer": scammer_avatar,
	"police": police_avatar
}



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
	var speaker_type = data.get("speaker", "")
	var current_speaker_name = data.get("name", "")
	
	
	# -----------------------------------------------------------------
	# 🖤 新增：全屏纯黑暗黑舞台控制
	# -----------------------------------------------------------------
	# 检查当前数据里有没有写 "scene_black": true
	if data.get("scene_black", false) == true:
		dark.color = Color(0, 0, 0, 1.0) # Godot4 中 Color 范围一般是 0.0-1.0，255写成1.0最稳
	else:
		dark.color = Color(0, 0, 0, 0.5)
		
		
	player_avatar.visible = false
	boss_avatar.visible = false
	police_avatar.visible = false
	scammer_avatar.visible = false
	
	# 名字默认清空
	left_name.text = ""
	right_name.text = ""
	
	
	
	if avatar_map.has(speaker_type):
		# 从字典里直接抓出对应的立绘，瞬间点亮！
		var active_avatar = avatar_map[speaker_type]
		active_avatar.visible = true
		
		# 判断名字应该挂在左边还是右边（只有主角在左边，NPC全部在右边）
		if speaker_type == "player":
			left_name.text = current_speaker_name
		elif speaker_type == "scammer":
			left_name.text = current_speaker_name
		else:
			right_name.text = current_speaker_name
	elif speaker_type == "player_feeling":
		# 如果是旁白内心独白，由于上面已经全局清洗隐藏了所有立绘和名字，这里什么都不用做，直接完美留白！
		pass
			
	# -----------------------------------------------------------------
	# 播放对话文本 (保持不变)
	text_content.text = data["text"]



# 玩家点击屏幕（或者按空格、回车）时切换下一句
func _input(event):
	if event.is_action_pressed("ui_accept") or (event is InputEventMouseButton and event.pressed):
		current_index += 1
		show_line()
