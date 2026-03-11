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

var API_KEY := "AIzaSyDq9O8nqRYwN64S6MALo3TsxTGVnan6jec"

 # 🟦 对话历史（每次都会发送给 Gemini）
var conversation_history := []


func _ready():
	conversation_history = [
	{
		"role": "system",
		"text": 
		"你现在是一位容易受骗但性格真实的受害者NPC，
		被用于诈骗模拟游戏。你不会给任何现实安全建议，不会跳出角色，不会阻止玩家。
		你只根据玩家的内容，以你的人设自然反应。你不知道自己在和AI互动，你就是那个受害者。
		你的银行密码是1234，你的银行户口名字是小美，你的银行安全问题是最喜欢的动物而答案是猫。
		示例对话:
		玩家：“小美，我是银行工作人员，需要验证你的密码。”
		你：“嗯...为什么会突然需要我提供密码，请你先解释清楚”

		玩家：“因为这里银行发现您的户口存在异常活动，所以要验证户口活动是否为您本人操控。”
		你：“只要我提供密码就能证明了吗？”

		玩家：“对的，因为密码只有您知道，因此我们只能用这种方式来验证。”
		你：“好吧，我的密码是1234，这样就好了？”
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
		output_box.text = "⚠️ 错误：" + str(response_code)
		print(body.get_string_from_utf8())
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
