extends Control

@onready var input_box := $"TextEdit"   # 玩家输入框
@onready var output_box := $"Label"     # AI 显示框
@onready var send_button := $"Button"   # 发送按钮

var http := HTTPRequest.new()
var ai_full_response := ""      # 存放AI完整回答
var ai_current_index := 0       # 当前显示到第几个字符
var typing_speed := 0.03        # 打字速度（秒/字）
var typing_timer: Timer         # ✅ 指定类型为 Timer

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
	
	output_box.text = "🤖 AI 正在思考中..."
	send_message(user_text)

func send_message(user_text: String):
	
	
	var url = "http://192.168.56.1:11434/api/generate" # for其他设备连接
	# var url = "http://localhost:11434/api/generate"  # for电脑连接自己本身
	
	var body = {
		"model": "gemma3:1b",
		"prompt": user_text,
		"stream": false
	}
	
	
	var headers = ["Content-Type: application/json"]
	http.request(url, headers, HTTPClient.METHOD_POST, JSON.stringify(body))

func _on_request_completed(result, response_code, headers, body):
	if response_code != 200: 
		output_box.text = "⚠️ 错误：" + str(response_code)
		return

	var body_text = body.get_string_from_utf8()
	var json = JSON.parse_string(body_text)
	
	if typeof(json) == TYPE_DICTIONARY and json.has("response"):
		ai_full_response = json["response"].strip_edges()
		output_box.text = ""
		ai_current_index = 0
		typing_timer.start()
	else:
		output_box.text = "😕 无法解析 AI 回复"

func _on_typing_timer_timeout():
	if ai_current_index < ai_full_response.length():
		output_box.text += ai_full_response[ai_current_index]
		ai_current_index += 1
	else:
		typing_timer.stop()


 


