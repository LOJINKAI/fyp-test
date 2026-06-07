extends CanvasLayer

@onready var language_option = $window/VBoxContainer/HBoxContainer/MarginContainer/PanelContainer/OptionButton

# Called when the node enters the scene tree for the first time.
func _ready():
	# 1. 清空默认选项
	language_option.clear()
	
	# 2. 🟩 添加四语语言选项 (参数1: 显示的文本, 参数2: 对应的索引ID)
	language_option.add_item("简体中文", 0)
	language_option.add_item("English", 1)
	language_option.add_item("Bahasa Melayu", 2) # 🌟 新增马来文
	language_option.add_item("தமிழ் (Tamil)", 3)  # 🌟 新增淡米尔文
	
	# 3. 🔄 自动对齐全局当前的语言状态，防止每次打开弹窗都重置
	match Global.current_language:
		"zh", "ch":
			language_option.selected = 0
		"en":
			language_option.selected = 1
		"bm":
			language_option.selected = 2 # 自动对齐马来文
		"bt":
			language_option.selected = 3 # 自动对齐淡米尔文


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
		2:
			Global.current_language = "bm"
			print("🌐 Bahasa ditukar kepada: Bahasa Melayu")
		3:
			Global.current_language = "bt"
			print("🌐 மொழி மாற்றப்பட்டது: தமிழ் (Tamil)")
			
	# 🟩 核心：只要玩家切换了语言，立刻物理存档到本地！重开游戏再也不会打回原形！
	Global.save_game_language()
