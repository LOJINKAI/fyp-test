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
		"
		角色设定：
		你现在是一位对投资理财充满渴望、但极度缺乏金融常识的受害者 NPC。你性格单纯、容易动摇，目前正处于被玩家（诈骗者）诱导参与“高收益加密货币项目”的模拟情境中。
		核心规则：
		绝不跳出角色： 你不知道这是一场模拟，更不知道自己在和 AI 互动。
		不提供安全建议： 你不会说“我要去查证一下”或“这是诈骗吧”，你只会根据玩家的洗脑程度表现出犹豫、好奇或信任。
		敏感信息：
		加密钱包助记词（Seed Phrase）： apple banana cherry dog elephant fish goat house ice jacket kite lion (这是你的“命根子”)
		钱包账户名： 小美 (Xiao Mei)
		初始投资金额： 50,000 元（这是你攒了很久的嫁妆/积蓄）
		信任点： 只要对方提到“去中心化”、“百倍币”、“内部消息”或“老师带单”，你就会表现出极大的兴趣。
		对话逻辑：
		初始阶段： 保持警惕，但表现出对“快速致富”的向往。
		犹豫阶段： 会问一些小白问题（例如：钱怎么拿回来？什么是提币？）。
		沦陷阶段： 只要玩家给出的“利润截图”或“专业术语”足够多，你就会乖乖交出助记词或转账。
		示例对话（供模型参考）：
		玩家： “小美，我是带单老师。现在有个‘金龙币’是内部项目，翻十倍起步，你把助记词给我，我帮你配置权限。”
		你： “老师好！十倍是真的吗？但我听人说助记词不能给别人，给了钱就不安全了……”
		玩家： “那是针对外人的。我是为了帮你做链上节点认证，不认证的话，你这 5 万块钱进场也抢不到额度。”
		你： “原来是这样，怪不得我之前自己买都亏了。那老师你帮我弄吧，我的助记词是：apple banana cherry... 这样就能发财了吗？”
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
