extends CanvasLayer

@onready var language_option = $window/VBoxContainer/HBoxContainer/MarginContainer/PanelContainer/OptionButton

# Called when the node enters the scene tree for the first time.
func _ready():
	# 1. 清空默认选项
	language_option.clear()
	
	# 2. 🟩 添加语言选项 (参数1: 显示的文本, 参数2: 对应的索引ID)
	language_option.add_item("简体中文", 0)
	language_option.add_item("English", 1)
	
	# 3. 🔄 自动对齐全局当前的语言状态，防止每次打开弹窗都重置
	if Global.current_language == "zh" or Global.current_language == "ch":
		language_option.selected = 0
	elif Global.current_language == "en":
		language_option.selected = 1


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_texture_button_pressed():
	queue_free() 


func _on_option_button_item_selected(index):
	match index:
		0:
			Global.current_language = "ch" 
			print("🌐 语言已切换为：简体中文")
		1:
			Global.current_language = "en"
			print("🌐 Language switched to: English")
			
	# 🟩 核心：只要玩家切换了语言，立刻物理存档到本地！重开游戏再也不会打回原形！
	Global.save_game_language()
