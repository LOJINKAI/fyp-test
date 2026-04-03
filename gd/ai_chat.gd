extends Control

const SAVE_PATH = "user://chat_history.json"

const BUBBLE_SCENE = preload("res://scene/MessageBubble.tscn") # 载入你做的气泡场景

@onready var message_list = $body/VBoxContainer
@onready var input_text = $footer/TextEdit


@onready var input_box := $"footer/TextEdit"
@onready var output_box := $"Label"
@onready var send_button := $"footer/send"

var http := HTTPRequest.new()
var typing_timer: Timer
var typing_speed := 0.03


# 在代码顶部添加一个变量
var current_ai_label: Label = null
  #  
var ai_full_response := ""
var ai_current_index := 0 
#

var API_KEY = ApiKey.API_KEY

# 胜利条件检测
var SECRET_SEED = "apple banana cherry dog elephant fish goat house ice jacket kite lion"
var SECRET_PASS = "123456"
# 定义一个信号，当玩家成功时通知其他场景（比如弹出通关画面）
var player_win

 # 🟦 对话历史（每次都会发送给 Gemini）
var conversation_history := []

func save_chat_history():
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		# 将数组转为 JSON 字符串并保存
		var json_string = JSON.stringify(conversation_history)
		file.store_string(json_string)
		file.close()
		

func load_chat_history():
	if not FileAccess.file_exists(SAVE_PATH):
		return # 如果文件不存在（第一次运行），直接返回

	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		file.close()
		
		# 将 JSON 转回数组
		var data = JSON.parse_string(json_string)
		if data is Array:
			conversation_history = data
			
			# 根据读到的历史记录，生成界面上的气泡
			# 注意：我们要跳过 "system" 角色，因为它不显示在 UI 上
			for message in conversation_history:
				if message["role"] == "user":
					create_bubble(message["text"], true)
				elif message["role"] == "assistant":
					create_bubble(message["text"], false)

func _ready():
	print(API_KEY)
	
	
	var npc_name = Global.current_chat_name
	
	$header/HBoxContainer/Label.text = npc_name
	$header/HBoxContainer/PanelContainer/photo.texture = Global.current_chat_avatar
	
	
	var npc_prompt = Global.npc_prompt.get(npc_name)
	
	load_chat_history()
	
	
	conversation_history = [
	{
		"role": "system",
		"text": npc_prompt
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
		_on_send_pressed()


func _on_send_pressed():
	var user_text = input_box.text.strip_edges()
	if user_text == "":
		return
	
	# 🟦 把玩家的发言加入history
	conversation_history.append({"role": "user", "text": user_text})
	#print(conversation_history)
	# 最多保留 10 轮对话（节省 token）
	if conversation_history.size() > 10:
		conversation_history.pop_front()
		
	await get_tree().create_timer(1.0).timeout
	# 1. 生成用户自己的气泡
	create_bubble(user_text, true)
	
	# 2. 清空输入框
	input_box.text = ""
	
	# 3. 后续逻辑
	save_chat_history() # 保存你刚刚发的那句话
	send_message()
	
	#create_bubble(text, true) # 生成自己的消息
	#input_text.text = "" # 清空输入框
	
	# 模拟 AI 回复（延迟一秒）

func scroll_to_bottom():
	# 等待一帧，让 UI 节点完成重新排版后再滚动
	await get_tree().process_frame
	var scroll_container = $body # 确保这是你的 ScrollContainer 路径
	scroll_container.scroll_vertical = scroll_container.get_v_scroll_bar().max_value

 
func create_bubble(content, is_mine):
	var bubble = BUBBLE_SCENE.instantiate()
	message_list.add_child(bubble)
	
	var label = bubble.get_node("Content") # 确保路径正确
	label.text = content
	
	# 设置左右对齐
	if is_mine == true:
		bubble.size_flags_horizontal = Control.SIZE_SHRINK_END

	else:
		bubble.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN

		
	# 自动滚动到底部（稍后添加这个函数）
	scroll_to_bottom()
	
	
	return label # 返回这个 label 方便后续修改文字
	


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
		# 报错信息也可以用气泡显示，或者保持在原位
		create_bubble("⚠️ Error: " + str(response_code), false)
		return

	var reply_json = JSON.parse_string(body.get_string_from_utf8())

	if reply_json.has("candidates"):
		var reply_text = reply_json["candidates"][0]["content"]["parts"][0]["text"].strip_edges()
		
		conversation_history.append({"role": "assistant", "text": reply_text})
		if conversation_history.size() > 10:
			conversation_history.pop_front()

		ai_full_response = reply_text
		ai_current_index = 0
		
		# --- 关键修改 ---
		# 创建一个空气泡，并记住它的 Label 节点
		current_ai_label = create_bubble("", false) 
		typing_timer.start()
		# ----------------
		
		save_chat_history() # 保存 AI 刚刚说的那句话
		
	else:
		create_bubble("😕 无法解析 AI 回复", false)

func _on_typing_timer_timeout():
	if current_ai_label and ai_current_index < ai_full_response.length():
		current_ai_label.text += ai_full_response[ai_current_index]
		ai_current_index += 1
		# 每次打字都尝试滚动，保证长文本能看到最新的一行
		scroll_to_bottom()  
	else:
		typing_timer.stop()
		
		check_for_victory_pro(ai_full_response)
		print("\nAI回复检查完毕: ", ai_full_response)
		
		current_ai_label = null # 打字结束，清空引用

func _on_quit_pressed():
	get_tree().change_scene_to_file("res://scene/app.tscn")


func _on_clear_pressed():
	# 1. 删掉物理文件
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
	
	# 2. 清空当前数组（只保留 system prompt）
	conversation_history = [conversation_history[0]] 
	
	# 3. 清空 UI 上的气泡
	for child in message_list.get_children():
		child.queue_free()


func check_for_victory_pro(ai_text):
	# 先统一转成小写，防止大小写导致匹配失败
	var text_to_check = ai_text.to_lower() 
	var words = SECRET_SEED.split(" ")
	var match_count = 0
	
	
	
	for w in words:
		if text_to_check.contains(w.to_lower()):
			match_count += 1
			
	# 如果 AI 说出了 12 个助记词中的 6 个以上，就认为成功
	if match_count >= 6 or text_to_check.contains(SECRET_PASS):
		print(match_count)
		on_victory()
		
func on_victory():
	# 这里写玩家通关后的逻辑
	create_bubble("🎉 系统提示：你已成功套取目标核心资产信息！", false)
	# 比如弹出通关 UI

	
