extends Control

const SAVE_PATH = "user://boss_chat_history.json"
const BUBBLE_SCENE = preload("res://scene/MessageBubble.tscn")

@onready var message_list = $main/body/VBoxContainer
@onready var input_box := $main/MarginContainer/footer/TextEdit
@onready var send_button := $"main/MarginContainer/footer/send"

var http := HTTPRequest.new()
var typing_timer: Timer
var typing_speed := 0.03

# 📥 读取全局的玩家与小美的对话历史（临时评估用）
var conversation_history = Global.conversation_history

var current_ai_label: Label = null
var ai_full_response := ""
var ai_current_index := 0 

# 从你的本地加密/安全单例获取 API_KEY
var API_KEY = apiKey.API_KEY

# 🛠️ 专门用来存放 Boss 自身历史信息（总结记录）的数组，会通过本地文件存取
var boss_conversation_contents := []
var final_boss_prompt := ""



func _ready():
	
	
	
	add_child(http)
	
	# 连接信号
	http.request_completed.connect(_on_request_completed)
	send_button.pressed.connect(_on_button_pressed)

	typing_timer = Timer.new()
	typing_timer.wait_time = typing_speed
	typing_timer.timeout.connect(_on_typing_timer_timeout)
	add_child(typing_timer)
	
	# 1. 🟥 首先载入以前所有的老板总结记录（保证历史信息不被删除）
	load_boss_history()
	
	# 2. 🤖 然后去看看有没有从小美那里拿到的新战绩需要总结
	start_boss_evaluation()

# 💾 新增：保存老板的总结历史到本地
func save_boss_history():
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		var json_string = JSON.stringify(boss_conversation_contents)
		file.store_string(json_string)
		file.close()

# 📂 新增：读取老板以前的总结历史并渲染到屏幕上
func load_boss_history():
	if not FileAccess.file_exists(SAVE_PATH):
		return
		
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		file.close()
		
		var data = JSON.parse_string(json_string)
		if data is Array:
			boss_conversation_contents = data
			# 把之前老板存下的每一条发言，重新在 UI 里生成气泡
			for item in boss_conversation_contents:
				if item.has("role") and item.has("parts") and item["parts"].size() > 0:
					var text = item["parts"][0].get("text", "")
					if item["role"] == "user":
						create_bubble(text, true)
					elif item["role"] == "model":
						create_bubble(text, false)

func start_boss_evaluation():
	# 🔒 安全检查：如果全局变量没数据，或者已经被清空过，说明没有新战绩需要总结
	if conversation_history == null or conversation_history.size() <= 1:
		print("ℹ️ 没有新的小美聊天记录需要总结，仅展示历史记录。")
		return
		
	print("🔥 发现新战绩！开始提取聊天记录...")
	var chat_logs = ""
	
	# 🟩 步骤 1：安全的提取纯文本
	for msg in conversation_history:
		var role = msg.get("role", "")
		var text = msg.get("text", "")
		if role == "system":
			continue
		if role == "user":
			chat_logs += "【新人骗子(玩家)】: " + text + "\n"
		elif role == "assistant":
			chat_logs += "【受害者小美】: " + text + "\n"
	
	# 🗑️ 步骤 2：【核心修复移到这里！】提取完纯文本后，立刻洗掉全局变量
	# 这样在后面任何地方，原本跟小美聊天的气泡都绝对不可能被画到 Boss 场景的 UI 上！
	Global.conversation_history = [ Global.conversation_history[0] ]
	conversation_history = Global.conversation_history # 同步切断局部引用
	
	# 3. 构建大 Boss 的终极人设与任务 Prompt
	
	#cant put in Global file, as it include chat_log 
	final_boss_prompt = "【系统强制底层协议 - 角色：诈骗集团幕后大Boss】

	你现在是跨国诈骗集团的头目、幕后大老板。你正在审阅一个新人骗子（玩家）对受害者‘小美’的诈骗聊天记录。



	【你的性格与说话语气】

	- 极度贪婪、狡诈、江湖气十足、高高在上。

	- 称呼玩家为：‘小子’、‘新人’、‘你这菜鸟’、‘好苗子’。

	- 说话绝对不能带有任何正义感、科普感或说教，你要完全站在黑暗反派的视角。



	【你的核心任务】

	请仔细阅读以下【聊天记录】，并用大老板赞赏、得意的语气完成以下三个任务：

	1. 赞赏与总结策略：狠狠夸奖这个新人，用黑产黑话精准总结玩家用了什么诈骗策略（例如：‘精準钓鱼’、‘一键同步洗脑’、‘利用人性的暴富心理’等）。

	2. 指出预防漏洞：用嘲讽受害者的语气，指出如果小美当初懂什么防范方法（例如：‘要是那蠢女人死守助记词’、‘只要她当时去官方验证一下’），你的这套策略就会泡汤。

	3. 纯文字口语化：不要输出任何括号动作（如(大笑)），保持聊天软件短句输出。



	【聊天记录如下】

	" + chat_logs + "



	【开始你的总结】

	现在，请以大老板的身份对新人的表现发表点评："

	# 4. 🟩 【关键隔绝】：确保老板的对话历史里，只写入“提交报告”这一句话！
	var report_text = "老板，这是我刚刚开单的聊天记录，请您过目，指点一下！"
	
	# 判断一下：如果老板的历史记录里已经有东西了，说明不是第一次进，就不要重复刷“请过目”
	if boss_conversation_contents.size() == 0:
		create_bubble(report_text, true)
		boss_conversation_contents.append({
			"role": "user",
			"parts": [{"text": report_text}]
		})
		save_boss_history() # 仅仅保存这一句话
	
	# 5. 发送请求
	send_message()

func send_message():
	# 使用官方最稳定的 v1beta 路径
	var url = "https://generativelanguage.googleapis.com/v1beta/models/gemini-3.1-flash-lite:generateContent?key=" + API_KEY
	
	
	# 🟩 【新加的滑动窗口裁剪逻辑】
	# 检查数组大小。如果超过 6 条（即 3 轮完美的汇报与总结对答），
	# 就用 while 循环不停地从最前面（头部）删掉最老的旧纪录，直到只剩下 6 条为止。
	while boss_conversation_contents.size() > 6:
		boss_conversation_contents.pop_front()
		print("✂️ 战绩墙已满，已自动清理一条最老的老板总结")
	
	# 终极防爆处理：把 Boss 的人设和聊天记录，用最原始的纯文本拼在一起
	var prompt_builder = ""
	prompt_builder += final_boss_prompt + "\n\n"
	
	# 追加以前和现在的所有发言进行上下文联想
	for item in boss_conversation_contents:
		if item.has("parts") and item["parts"].size() > 0:
			prompt_builder += item["parts"][0].get("text", "") + "\n"

	var body = {
		"contents": [
			{
				"role": "user",
				"parts": [{"text": prompt_builder}]
			}
		]
	}

	var headers = ["Content-Type: application/json"]
	http.request(url, headers, HTTPClient.METHOD_POST, JSON.stringify(body))

func _on_request_completed(result, response_code, headers, body):
	if response_code != 200:
		print("🚨 Google 拒绝的真正原始原因: ", body.get_string_from_utf8())
		create_bubble("⚠️ Boss 正在抽烟，请稍后再试 (Error: " + str(response_code) + ")", false)
		return

	var reply_json = JSON.parse_string(body.get_string_from_utf8())

	if reply_json.has("candidates"):
		var reply_text = reply_json["candidates"][0]["content"]["parts"][0]["text"].strip_edges()
		
		# 🌟 把 Boss 现在的回复，永久追加存入老板的历史数据中
		boss_conversation_contents.append({
			"role": "model",
			"parts": [{"text": reply_text}]
		})
		
		# 💾 存储到物理文件，下次打开软件还在！
		save_boss_history()
		
		ai_full_response = reply_text
		ai_current_index = 0
		
		current_ai_label = create_bubble("", false) 
		typing_timer.start()
	else:
		create_bubble("😕 老板看了看，对你摇了摇头...", false)

func _on_send_pressed():
	var user_text = input_box.text.strip_edges()
	if user_text == "":
		return
	
	create_bubble(user_text, true)
	
	boss_conversation_contents.append({
		"role": "user",
		"parts": [{"text": user_text}]
	})
	
	save_boss_history() # 随时保存你对老板说的话
	input_box.text = ""
	send_message()

# --- 以下 UI 控制保持不变 ---
func _on_button_pressed():
	_on_send_pressed()

func _on_typing_timer_timeout():
	if current_ai_label and ai_current_index < ai_full_response.length():
		current_ai_label.text += ai_full_response[ai_current_index]
		ai_current_index += 1
		scroll_to_bottom()
	else:
		typing_timer.stop()
		current_ai_label = null

func create_bubble(content: String, is_mine: bool) -> Label:
	var bubble = BUBBLE_SCENE.instantiate()
	message_list.add_child(bubble)
	var label = bubble.get_node("Content")
	label.text = content
	if is_mine:
		bubble.size_flags_horizontal = Control.SIZE_SHRINK_END
	else:
		bubble.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	scroll_to_bottom()
	return label

func scroll_to_bottom():
	await get_tree().process_frame
	var scroll_container = $main/body
	if scroll_container:
		scroll_container.scroll_vertical = scroll_container.get_v_scroll_bar().max_value

func _on_quit_pressed():
	get_tree().change_scene_to_file("res://scene/app.tscn")


func _on_delete_pressed():
# 1. 安全删掉本地的物理文件
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
		print("🗑️ 已物理删除大 Boss 的本地存档文件")
	
	# 2. 🟩 安全清空：直接降维打击变为空数组，绝对不会报 Out of bounds！
	boss_conversation_contents = []
	
	# 3. 停止可能正在打字的计时器，防止残余数据乱跳
	if typing_timer:
		typing_timer.stop()
	current_ai_label = null
	
	# 4. 清空界面上的所有聊天气泡
	for child in message_list.get_children():
		child.queue_free()
		
	print("✨ 大 Boss 场景的聊天历史与 UI 已彻底重置干净！")
