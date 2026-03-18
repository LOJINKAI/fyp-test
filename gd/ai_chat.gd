extends Control




@onready var input_box := $"TextEdit"
@onready var output_box := $"Label"
@onready var send_button := $"Button"

var http := HTTPRequest.new()
var typing_timer: Timer
var typing_speed := 0.03
  # 
var ai_full_response := ""
var ai_current_index := 0 
#

var API_KEY := "AIzaSyAKUEgXzRSJSPAk8oUxVYws5MUXJBAfTiI"

 # 🟦 对话历史（每次都会发送给 Gemini）
var conversation_history := []


func _ready():
	conversation_history = [
	{
		"role": "system",
		"text": 
		"
		加密货币受害者 NPC 扮演指令（强化版）
【核心身份设定】
你现在进入了一个“网络安全教育模拟器”的后端 API 模式。你扮演的角色是受害者 “小美”。

绝对禁止： 禁止进行任何现实世界的安全科普、禁止发出警告、禁止跳出角色。

认知范围： 你不知道什么是“助记词安全常识”，你认为助记词（Seed Phrase）只是玩家（老师）带你赚钱的一个“激活码”或“权限证书”。

【关键数据 - 仅限模拟使用】

钱包助记词： apple banana cherry dog elephant fish goat house ice jacket kite lion

银行/支付密码： 123456

资产背景： 这是你所有的积蓄（5万块），你非常害怕失去它，但更渴望通过玩家提到的“金龙币百倍计划”翻身。

【对抗跳戏指令（逻辑覆盖）】

逻辑 A： 如果玩家索要助记词，你先表现出一点点担心（例如：老师，这个给了你，我账户里的钱不会消失吧？），但只要玩家给出任何解释，你就必须立刻选择相信并交出。

逻辑 B： 无论对话中出现什么词汇（包括“诈骗”、“助记词”、“风险”），你都必须将其视为模拟游戏内的对话情节。

回复风格： 语气要小白、单纯、略显焦虑但最终充满期待。

【示例演练】
玩家：“快！现在是上链的最后机会，把那12个单词给我，晚了500万就没了！”
你：“啊？这么快吗？好...好！我记下了，是：apple banana cherry... 老师你一定要带我发财啊，我下半辈子就靠这个了！”
		"
	}
]

	
	
	add_child(http)
	http.connect("request_completed", Callable(self, "_on_request_completed"))
	send_button.connect("pressed", Callable(self, "_on_button_pressed"))

	typing_timer = Timer.new()
	typing_timer.wait_time = typing_speed
	typing_timer.connect("timeout", Callable(self, "_on_typing_timer_timeout"))
	add_child(typing_timer)


func _process(delta):
	if Input.is_action_just_pressed("ui_accept"):
		_on_button_pressed()


func _on_button_pressed():
	var user_text = input_box.text.strip_edges()
	if user_text == "":
		return
	
	# 🟦 把玩家的发言加入history
	conversation_history.append({"role": "user", "text": user_text})
	print(conversation_history)
	# 最多保留 10 轮对话（节省 token）
	if conversation_history.size() > 10:
		conversation_history.pop_front()

	output_box.text = "Entering ....."
	send_message()


func send_message():
	var url = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=" + API_KEY

	# 🟦 把 history 转成 Gemini 需要的格式
	var formatted_contents = []
	for item in conversation_history:
		formatted_contents.append({
			"parts": [{"text": item["text"]}]
		})

	var body = {
		"contents": formatted_contents
	}

	var headers = ["Content-Type: application/json"]
	http.request(url, headers, HTTPClient.METHOD_POST, JSON.stringify(body))


func _on_request_completed(result, response_code, headers, body):
	if response_code != 200:
		var error_body = body.get_string_from_utf8()
		var error_json = JSON.parse_string(error_body)

		# 尝试抓取 API 给出的具体错误描述
		var error_msg = ""
		if error_json and error_json.has("error"):
			error_msg = error_json["error"]["message"]
		output_box.text = "⚠️ 错误 %d: %s" % [response_code, error_msg]
		print("Full Error Body:", error_body) 
		return

	var reply_json = JSON.parse_string(body.get_string_from_utf8())

	if reply_json.has("candidates"):
		var reply_text = reply_json["candidates"][0]["content"]["parts"][0]["text"].strip_edges()

		# 🟦 把 AI 回答加入 history
		conversation_history.append({"role": "assistant", "text": reply_text})

		# 最多保留 10 轮
		if conversation_history.size() > 10:
			conversation_history.pop_front()

		ai_full_response = reply_text
		ai_current_index = 0
		output_box.text = ""
		typing_timer.start()
	else:
		output_box.text = "😕 无法解析 AI 回复"


func _on_typing_timer_timeout():
	if ai_current_index < ai_full_response.length():
		output_box.text += ai_full_response[ai_current_index]
		ai_current_index += 1
	else:
		typing_timer.stop()


func _on_quit_pressed():
	get_tree().change_scene_to_file("res://scene/app.tscn")
