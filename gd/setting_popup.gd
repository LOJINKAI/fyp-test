extends CanvasLayer

@onready var language_option = $window/VBoxContainer/HBoxContainer/MarginContainer/PanelContainer/OptionButton

@onready var bgm_slider = $window/VBoxContainer/BGM_Slider
@onready var sfx_slider = $window/VBoxContainer/SFX_Slider 


# Called when the node enters the scene tree for the first time.
func _ready():
	# 1. 清空默认选项
	language_option.clear()
	
	# ==========================================
	# 🌟 新增：强行修改下拉菜单 (PopupMenu) 的外观！
	# ==========================================
	var popup = language_option.get_popup()
	
	# 1. 把弹窗列表的【字体大小】强行改大（这里暂定 35，你可以自己微调）
	popup.add_theme_font_size_override("font_size", 25)
	
	# 2. 增加选项之间的【上下间距】，不然字变大后会全部挤在一起
	popup.add_theme_constant_override("v_separation", 20)
	
	# 3. 增加选项左右的【留白边缘】，让整个黑框显得更大气
	popup.add_theme_constant_override("item_start_padding", 20)
	popup.add_theme_constant_override("item_end_padding", 20)
	# ==========================================
	
	# 2. 添加四语语言选项
	language_option.add_item("简体中文", 0)
	language_option.add_item("English", 1)
	language_option.add_item("Bahasa Melayu", 2)
	language_option.add_item("தமிழ் (Tamil)", 3)
	
	# 3. 自动对齐全局当前的语言状态
	match Global.current_language:
		"zh", "ch":
			language_option.selected = 0
		"en":
			language_option.selected = 1
		"bm":
			language_option.selected = 2
		"bt":
			language_option.selected = 3
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
