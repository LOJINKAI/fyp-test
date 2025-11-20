extends Control

@onready var input_box := $"TextEdit"   # 玩家输入框
@onready var output_box := $"Label"     # AI 显示框
@onready var send_button := $"Button"   # 发送按钮

var http := HTTPRequest.new()
var ai_full_response := ""
var ai_current_index := 0
var typing_speed := 0.03
var typing_timer: Timer

# ✅ 维持整段对话历史
var chat_history := []

# ✅ Gemini API Key
var API_KEY := "AIzaSyDq9O8nqRYwN64S6MALo3TsxTGVnan6jec"


func _ready():
	add_child(http)
	send_button.connect("pressed", Callable(self, "_on_button_pressed"))
	http.connect("request_completed", Callable(self, "_on_request_completed"))

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

	# ✨ 玩家发送内容加入历史
	chat_history.append({"role": "user", "text": user_text})
	print(chat_history)

	# ✨ 限制历史长度（避免 token 爆炸）
	if chat_history.size() > 10:
		chat_history.pop_front()

	output_box.text = "🤖 AI 正在思考中..."
	send_message()

	input_box.text = ""   # 清空输入框


func send_message():
	var url = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-lite:generateContent?key=" + API_KEY

	# ✨ 重新格式化为 Gemini 所需结构
	var parts_array = []
	for msg in chat_history:
		parts_array.append({"text": msg["text"]})

	var body = {
		"contents": [
			{
				"parts": parts_array
			}
		]
	}

	var headers = [
		"Content-Type: application/json"
	]

	http.request(url, headers, HTTPClient.METHOD_POST, JSON.stringify(body))


func _on_request_completed(result, response_code, headers, body):
	if response_code != 200:
		output_box.text = "⚠️ 错误：" + str(response_code)
		print(body.get_string_from_utf8())
		return

	var body_text = body.get_string_from_utf8()
	var json = JSON.parse_string(body_text)

	if typeof(json) == TYPE_DICTIONARY and json.has("candidates"):
		var candidates = json["candidates"]
		if candidates.size() > 0 and candidates[0].has("content"):
			var parts = candidates[0]["content"]["parts"]
			if parts.size() > 0 and parts[0].has("text"):
				var ai_text = parts[0]["text"].strip_edges()

				# ✨ AI 回答加入历史
				chat_history.append({"role": "assistant", "text": ai_text})

				# ✨ 限制历史长度
				if chat_history.size() > 10:
					chat_history.pop_front()

				# ✨ 开启打字效果
				ai_full_response = ai_text
				output_box.text = ""
				ai_current_index = 0
				typing_timer.start()
				return

	output_box.text = "😕 无法解析 AI 回复"


func _on_typing_timer_timeout():
	if ai_current_index < ai_full_response.length():
		output_box.text += ai_full_response[ai_current_index]
		ai_current_index += 1
	else:
		typing_timer.stop()
