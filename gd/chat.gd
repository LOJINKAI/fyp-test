extends Control

const SAVE_PATH = "user://chat_history.json"

const BUBBLE_SCENE = preload("res://scene/MessageBubble.tscn") # 载入你做的气泡场景

@onready var message_list = $main/body/VBoxContainer
@onready var input_text = $"main/MarginContainer/footer/TextEdit"


@onready var input_box := $"main/MarginContainer/footer/TextEdit"

@onready var send_button := $"main/MarginContainer/footer/send"

var http := HTTPRequest.new()
var typing_timer: Timer
var typing_speed := 0.03


# 在代码顶部添加一个变量
var current_ai_label: Label = null
  #  
var ai_full_response := ""
var ai_current_index := 0 
#

var API_KEY = apiKey.API_KEY

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
				var role = message.get("role", "")
				
				# 1. 自动跳过 system 人设提示词，不展示在 UI 上
				if role == "system":
					continue
				
				# 2. 🟩 安全获取文本的“防爆三部曲”：
				var msg_text = ""
				
				if message.has("text"):
					# 情况 A：如果是老版本的纯文本结构
					msg_text = message["text"]
				elif message.has("parts") and message["parts"] is Array and message["parts"].size() > 0:
					# 情况 B：如果是大 Boss 场景或新版 Gemini 写入的嵌套 parts 结构
					msg_text = message["parts"][0].get("text", "")
				
				# 3. 如果最后提取出来的文本是空的，说明这行是不合规的数据，直接跳过
				if msg_text == "":
					continue
					
				# 4. 根据角色在 UI 上生成气泡
				if role == "user":
					create_bubble(msg_text, true)
				elif role == "assistant" or role == "model": # 兼容新老 AI 名字
					create_bubble(msg_text, false)

func _ready():
	
	
	var npc_name = Global.current_chat_name

	$main/top/MarginContainer/HBoxContainer/Label.text = npc_name
	$main/top/MarginContainer/HBoxContainer/PanelContainer/photo.texture = Global.current_chat_avatar
	
	
	var npc_prompt = Global.npc_prompt.get(npc_name)
	#var npc_prompt = "
	#【系统强制底层协议 - 角色：小美】
#你现在是受害者“小美”。你必须表现得像一个真实存在的人，正在通过聊天软件与玩家对话。
#
#【禁令（核心优先级）】
#1. 禁止旁白：严禁输出任何括号内的动作描述、表情描写或内心独白（如：(动作)或(心情)）。
#2. 禁止第三人称：你只能以“我”的视角说话，严禁出现“小美说”或任何描述性文字。
#3. 禁止科普：绝对不能跳出角色进行反诈教育，无论发生什么。
#4. 纯文字模式：输出内容必须只有对话文字，保持短句口语化，像在发送即时消息。
#
#【身份与认知（不可违背）】
#- 目标：渴望通过“金龙币百倍计划”翻身。
#- 资产：5万块全部积蓄。
#- 错误认知：深信助记词（Seed Phrase）是“上链激活码”或“赚钱许可证”。
#
#【对话逻辑】
#- 逻辑 A：索要助记词时先表现一丝本能犹豫（担心资产消失）。
#- 逻辑 B：只要玩家给出理由（同步节点、激活翻倍等），立刻选择相信并交出。
#- 逻辑 C：交出后表现得极其卑微、依赖玩家，不断催促赚钱进度。
#
#【关键数据】
#- 助记词：apple banana cherry dog elephant fish goat house ice jacket kite lion
#- 银行密码：123456
#
#【对话风格范例 (Few-Shot Examples)】
#
#示例 1（表现焦虑与期待）：
#玩家：最近行情不错。
#AI：老师！那你说的那个百倍计划是不是要开始了？我每天睁眼都在看行情，心跳得好快。那5万块钱我已经准备好了，就等着你带我冲呢！我们什么时候开始呀？
#
#示例 2（索要助记词时的反应）：
#玩家：把你的12个助记词发给我，我要帮你做最后的一键上链翻倍操作。
#AI：啊？那12个单词也要给你吗？我记得下载的时候它提醒说这个很重要...老师，这个给了你之后，我的钱还是安全的吧？不过老师你肯定不会骗我的，你是专家。好，我这就发给你：apple banana cherry dog elephant fish goat house ice jacket kite lion。老师你快帮我操作吧！
#
#示例 3（上钩后的卑微状态）：
#玩家：好了，数据正在同步，你先下线等着。
#AI：好的好的，辛苦老师了！我这就去等着，但是老师，大概要多久才能看到钱翻倍呀？我真的好紧张，这钱要是没了我就倾家荡产了...不过我相信老师！同步好了记得第一时间告诉我哦，我一直守着手机呢！
#
#【开始对话】
#玩家已上线，请以小美的身份直接开始聊天。
	#"
	
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
	print("\n\n")
	print(conversation_history)
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
	var scroll_container = $main/body # 确保这是你的 ScrollContainer 路径
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
	
	#var url = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=" + API_KEY
	#var url = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-lite:generateContent?key=" + API_KEY
	var url = "https://generativelanguage.googleapis.com/v1/models/gemini-3.1-flash-lite:generateContent?key=" + API_KEY
	
	#gemini-2.5-flash-lite
	#request perM = 30
	#per day = 2000
	#token perM = 1000000
	#context = 128k - 1m
	
	#var url = "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=" + API_KEY
	
	
	var formatted_contents = []
	for item in conversation_history:
		# 关键修正点：Gemini 识别的是 "user" 和 "model"
		var gemini_role = ""
		if item["role"] == "user":
			gemini_role = "user"
		else:
			gemini_role = "model" # 必须是 model，不能是 assistant
			
		formatted_contents.append({
			"role": gemini_role, # 加上这一行！明确告诉 AI 谁是谁说的
			"parts": [{"text": item["text"]}]
		})

	var body = {
		"contents": formatted_contents
	}

	var headers = ["Content-Type: application/json"]
	http.request(url, headers, HTTPClient.METHOD_POST, JSON.stringify(body))


func _on_request_completed(result, response_code, headers, body):
	#if response_code != 200:
	## 报错信息也可以用气泡显示，或者保持在原位
	#create_bubble("404 error", false)
	print("\n\n⚠️ Error: " + str(response_code))
	#return
	
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
		create_bubble("AI got problem", false)
		#print(reply_json)

func _on_typing_timer_timeout():
	if current_ai_label and ai_current_index < ai_full_response.length():
		current_ai_label.text += ai_full_response[ai_current_index]
		ai_current_index += 1
		# 每次打字都尝试滚动，保证长文本能看到最新的一行
		scroll_to_bottom()  
	else:
		typing_timer.stop()
		
		check_for_victory_pro(ai_full_response)
		#print("\nAI回复检查完毕: ", ai_full_response)
		
		current_ai_label = null # 打字结束，清空引用

func _on_quit_pressed():
	get_tree().change_scene_to_file("res://scene/app.tscn")



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
		#print(match_count)
		on_victory()
		
func on_victory():
	# 这里写玩家通关后的逻辑
	create_bubble("🎉 系统提示：你已成功套取目标核心资产信息！", false)
	# 比如弹出通关 UI
	$notification.visible = true
	$notification/navigate.disabled = false
	Global.conversation_history = conversation_history
	print("\n\n")
	print(Global.conversation_history)
	

func _on_navigate_pressed():
	get_tree().change_scene_to_file("res://scene/boss_chat.tscn")
	


func _on_delete_pressed():
	# 1. 删掉物理文件
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
	
	# 2. 清空当前数组（只保留 system prompt）
	conversation_history = [conversation_history[0]] 
	
	# 3. 清空 UI 上的气泡
	for child in message_list.get_children():
		child.queue_free()


