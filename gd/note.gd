extends CanvasLayer


@onready var content_image = $window/VBoxContainer/PanelContainer/TextureRect
@onready var content_label = $window/VBoxContainer/content
@onready var left_button = $window/VBoxContainer/HBoxContainer/left_button/left_button
@onready var right_button =$window/VBoxContainer/HBoxContainer/right_button/right_button

var lang = Global.current_language




var help_pages = {
	"ch": [
		{
			"image": "res://image/help/role.png",
			"text": "你现在是加密货币群的一个秘书。"
		},
		{
			"image": "res://image/help/task.png",
			"text": "任务是诱骗目标透过群里的链接来买我们的”发财币“。"
		},
		{
			"image": "res://image/help/think.png",
			"text": "仔细思考目标的个人简介来判断如何抓住他的心理弱点来成功诱骗目标。"
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
			"text": "可以点击按钮来寻求提示。"
		},
		{
			"image": "res://image/help/delete.png",
			"text": "可以点击按钮来重新开始游戏。"
		}
	],
	"en": [
		{
			"image": "res://image/help/role.png",
			"text": "You are now a secretary in a cryptocurrency group chat."
		},
		{
			"image": "res://image/help/task.png",
			"text": "Your task is to trick the target into buying our 'Richcoin' via the link in the group."
		},
		{
			"image": "res://image/help/think.png",
			"text": "Analyze the target's bio carefully to figure out their psychological weakness and manipulate them successfully."
		},
		{
			"image": "res://image/help/link.png",
			"text": "If the target asks how to buy, simply tell them that the link is provided right here in the group."
		},
		{
			"image": "res://image/help/help.png",
			"text": "You can click this button to review this help guide at any time."
		},
		{
			"image": "res://image/help/bell.png",
			"text": "You can click this button to look for insider tips."
		},
		{
			"image": "res://image/help/delete.png",
			"text": "You can click this button to restart the game."
		}
	],
	"bm": [
		{
			"image": "res://image/help/role.png",
			"text": "Anda kini bertindak sebagai setiausaha dalam group sembang mata wang kripto."
		},
		{
			"image": "res://image/help/task.png",
			"text": "Tugas anda adalah untuk memperdayakan sasaran supaya membeli 'Richcoin' kita melalui pautan dalam group."
		},
		{
			"image": "res://image/help/think.png",
			"text": "Kaji bio sasaran dengan teliti untuk menentukan cara memanipulasi kelemahan psikologi mereka demi menjayakan penipuan ini."
		},
		{
			"image": "res://image/help/link.png",
			"text": "Jika sasaran bertanya cara untuk membeli, beritahu sahaja dengan terus-terang bahawa pautan ada disediakan dalam group."
		},
		{
			"image": "res://image/help/help.png",
			"text": "Anda boleh klik butang ini untuk melihat semula panduan bantuan."
		},
		{
			"image": "res://image/help/bell.png",
			"text": "Anda boleh klik butang ini untuk mendapatkan pembayang atau petunjuk."
		},
		{
			"image": "res://image/help/delete.png",
			"text": "Anda boleh klik butang ini untuk memulakan semula permainan."
		}
	],
	"bt": [
		{
			"image": "res://image/help/role.png",
			"text": "நீங்கள் இப்போது ஒரு கிரிப்டோகரன்சி குழுவின் (Cryptocurrency group) செயலாளராக இருக்கிறீர்கள்."
		},
		{
			"image": "res://image/help/task.png",
			"text": "குழுவில் உள்ள லிங்க் (Link) மூலம் இலக்கை ஏமாற்றி நமது 'ஃபார்ட்டூன் காயினை' (Richcoin) வாங்க வைப்பதே உங்கள் வேலை."
		},
		{
			"image": "res://image/help/think.png",
			"text": "இலக்கின் பயோவை (Bio) கவனமாகப் படித்து, அவர்களின் உளவியல் பலவீனத்தைப் பயன்படுத்தி அவர்களை எவ்வாறு வெற்றிகரமாக ஏமாற்றுவது என்று முடிவு செய்யுங்கள்."
		},
		{
			"image": "res://image/help/link.png",
			"text": "எவ்வாறு வாங்குவது என்று இலக்கு கேட்டால், குழுவிலேயே லிங்க் உள்ளது என்று நேரடியாகக் கூறுங்கள்."
		},
		{
			"image": "res://image/help/help.png",
			"text": "உதவிப் பக்கத்தை மீண்டும் பார்க்க இந்த பட்டனை கிளிக் செய்யலாம்."
		},
		{
			"image": "res://image/help/bell.png",
			"text": "குறிப்புகளைப் பெற (Hints) இந்த பட்டனை கிளிக் செய்யலாம்."
		},
		{
			"image": "res://image/help/delete.png",
			"text": "விளையாட்டை மீண்டும் முதலிலிருந்து தொடங்க இந்த பட்டனை கிளிக் செய்யலாம்."
		}
	]
}


var current_page_index = 0

func _ready():
	update_page_display()

func update_page_display():
	
	var current_lang_list = help_pages.get(Global.current_language, help_pages["en"])
	
	
	var current_data = current_lang_list[current_page_index]
	
	
	content_label.text = current_data["text"]
	content_image.texture = load(current_data["image"])
	
	
	left_button.visible = current_page_index > 0
	right_button.visible = current_page_index < current_lang_list.size() - 1


func _on_right_button_pressed():
	SoundEffect.play_sound("ui_click")
	var current_lang_list = help_pages.get(Global.current_language, help_pages["en"])
	
	
	if current_page_index < current_lang_list.size() - 1:
		current_page_index += 1
		update_page_display()


func _on_left_button_pressed():
	SoundEffect.play_sound("ui_click")
	if current_page_index > 0:
		current_page_index -= 1
		update_page_display()


func _on_close_pressed():
	SoundEffect.play_sound("ui_click")
	queue_free() 
