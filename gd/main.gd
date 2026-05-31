#main.tscn

extends Control

# 输出格式示例：2026-05-09 15:30:05
var current_time = Time.get_datetime_string_from_system(false, true)
@onready var time = $"time"

#setting popup
const SETTING_POPUP_SCENE = preload("res://scene/setting_popup.tscn")


# Called when the node enters the scene tree for the first time.
func _ready():
	update_time_display()
	
	Global.language = "ch"
	print("\n\nGlobal.bio_tutorial_finished = ",Global.bio_tutorial_finished)
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
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
	get_tree().quit()
	#close game


func _on_start_pressed():
	get_tree().change_scene_to_file("res://scene/phone.tscn")  


func _on_setting_pressed():
	# 1. 动态实例化这个小窗口
	var popup = SETTING_POPUP_SCENE.instantiate()
	
	# 2. 🟩 核心：直接把它作为子节点加到当前主界面最底层
	# 因为 Godot 的渲染规则是“越靠下的节点，渲染在越表面”
	# 它会自动完美覆盖在你的 time、start、setting、quit 之上！
	get_tree().current_scene.add_child(popup)
	
	print("✨ 成功呼出设置弹窗，主界面已被半透明黑色遮罩锁定！")
	
	
	
	
	
	
	
	
	
	
