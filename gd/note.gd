extends CanvasLayer

# 绑定 UI 节点
@onready var content_image = $window/VBoxContainer/PanelContainer/TextureRect
@onready var content_label = $window/VBoxContainer/Label
@onready var left_button = $window/VBoxContainer/HBoxContainer/left_button/left_button
@onready var right_button =$window/VBoxContainer/HBoxContainer/right_button/right_button

# 1. 核心定义：把每一页要显示的数据存进数组
var help_pages = [
	{
		"image": "res://image/help/role.png", # 换成你对应的提示图标路径
		"text": "你现在是加密货币群的一个秘书。"
	},
	{
		"image": "res://image/help/task.png",
		"text": "任务是诱骗目标透过群里的链接来买我们的”发财币“。"
	},
	{
		"image": "res://image/help/think.png",
		"text": "仔细思考目标的bio来判断如何抓住他的心理弱点来成功诱骗目标。"
	},
	{
		"image": "res://image/help/link.png",
		"text": "要是目标问如何购买，就直接告诉他群里有链接。"
	},
	{
		"image": "res://image/help/help.png",
		"text": "可以点击按钮来看回帮助。"
	},
	{
		"image": "res://image/help/bell.png",
		"text": "可以点击来寻求提示。"
	},
	{
		"image": "res://image/help/delete.png",
		"text": "可以点击按钮来重新开始游戏。"
	}
]

# 当前显示到第几页 (从 0 开始算第一页)
var current_page_index = 0

func _ready():
	# 游戏一打开，先显示第一页
	update_page_display()

# 核心功能：刷新当前页面的外观
func update_page_display():
	var current_data = help_pages[current_page_index]
	
	# 1. 更新文字和图片
	content_label.text = current_data["text"]
	content_image.texture = load(current_data["image"])
	
	# 2. 🟩 智能控制箭头的显示与隐藏（防呆机制）
	# 如果是第一页，左边箭头藏起来
	left_button.visible = current_page_index > 0
	# 如果是最后一页，右边箭头藏起来
	right_button.visible = current_page_index < help_pages.size() - 1

# 点击右箭头（下一页）
func _on_right_button_pressed():
	SoundEffect.play_sound("ui_click")
	if current_page_index < help_pages.size() - 1:
		current_page_index += 1
		update_page_display()

# 点击左箭头（上一页）
func _on_left_button_pressed():
	SoundEffect.play_sound("ui_click")
	if current_page_index > 0:
		current_page_index -= 1
		update_page_display()


func _on_close_pressed():
	SoundEffect.play_sound("ui_click")
	queue_free() 
