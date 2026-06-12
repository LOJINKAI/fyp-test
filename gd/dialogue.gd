# dialogue.gd

extends CanvasLayer

@onready var left_name = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/left
@onready var right_name = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/right
@onready var text_content = $PanelContainer/MarginContainer/VBoxContainer/RichTextLabel


@onready var player_avatar = $player
@onready var boss_avatar = $Boss
@onready var police_avatar = $police
@onready var scammer_avatar = $scammer
@onready var player_laugh_avatar = $player_laugh
@onready var player_sad_avatar = $player_sad

@onready var dark = $dark


# 存储当前正在播放的对话数据列表
var current_dialogue_list = []
var current_index = 0


@onready var avatar_map := {
	"player": player_avatar,
	"boss": boss_avatar,
	"scammer": scammer_avatar,
	"police": police_avatar,
	"player_laugh": player_laugh_avatar,
	"player_sad": player_sad_avatar
}



func start_story(dialogue_data: Array):
	current_dialogue_list = dialogue_data
	current_index = 0
	show_line()

func show_line():
	if current_index >= current_dialogue_list.size():
		
		queue_free()
		return
		
	var data = current_dialogue_list[current_index]
	var speaker_type = data.get("speaker", "")
	var current_speaker_name = data.get("name", "")
	
	

	if data.get("scene_black", false) == true:
		dark.color = Color(0, 0, 0, 1.0) 
	else:
		dark.color = Color(0, 0, 0, 0.5)
		
		
	player_avatar.visible = false
	boss_avatar.visible = false
	police_avatar.visible = false
	scammer_avatar.visible = false
	player_laugh_avatar.visible = false
	player_sad_avatar.visible = false
	

	left_name.text = ""
	right_name.text = ""
	
	
	
	if avatar_map.has(speaker_type):
		var active_avatar = avatar_map[speaker_type]
		active_avatar.visible = true
		
		
		if speaker_type == "player":
			left_name.text = current_speaker_name
		elif speaker_type == "player_laugh":
			left_name.text = current_speaker_name
		elif speaker_type == "player_sad":
			left_name.text = current_speaker_name
		elif speaker_type == "scammer":
			left_name.text = current_speaker_name
		else:
			right_name.text = current_speaker_name
	elif speaker_type == "player_feeling":
		
		pass
			
	
	text_content.text = data["text"]




func _input(event):
	if event.is_action_pressed("ui_accept") or (event is InputEventMouseButton and event.pressed):
		current_index += 1
		show_line()
