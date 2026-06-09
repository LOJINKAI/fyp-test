#chat.tscn

extends Control

const SAVE_PATH = Global.chat_history

const BUBBLE_SCENE = preload("res://scene/MessageBubble.tscn") # 载入你做的气泡场景

const NOTE_POPUP_SCENE = preload("res://scene/note.tscn")

@onready var message_list = $main/body/message_list


@onready var input_box := $main/MarginContainer/footer/MarginContainer/TextEdit
							
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

var response_code

var API_KEY = apiKey.API_KEY

#懂讲现在是总结，不要发信息泡泡
var is_fetching_conclusion = false

# 定义一个信号，当玩家成功时通知其他场景（比如弹出通关画面）
var is_success

var success_id
var reply_language
var fail_message
var entering
var show_image_message

var game_end


 # 🟦 对话历史（每次都会发送给 Gemini）
var conversation_history := []

#load npc info
var npc_name = Global.current_chat_name
var npc_prompt
var lang = Global.current_language


var already_helped = false



var npc_done = npc_name + "_done"


func _ready():
	print("lan = ",Global.current_language)
	print("entering = ",Global.entering)
	print("reply = ",Global.reply_language)
	
	match_language()
	
	
	
	
	#random generate id
	success_id = str(randi_range(1000, 9999))
	print("\n\nsuccess id = ",success_id)
	
	reply_language = reply_language
	print("\n\nlanguage = ",reply_language)
	
	npc_prompt = Global.npc_prompt.get(npc_name).replace("{reply_language}", reply_language).replace("{success_id}", success_id)
	
	
	print("\n\nGlobal.bio_tutorial_finished = ",Global.bio_tutorial_finished)
	$main/top/MarginContainer/HBoxContainer/Label.text = npc_name
	$main/top/MarginContainer/HBoxContainer/PanelContainer/photo.texture = Global.current_chat_avatar
	
	
	
	
	
	add_child(http)
	http.connect("request_completed", Callable(self, "_on_request_completed"))
	send_button.connect("pressed", Callable(self, "_on_send_pressed()"))

	typing_timer = Timer.new()
	typing_timer.wait_time = typing_speed
	typing_timer.connect("timeout", Callable(self, "_on_typing_timer_timeout"))
	add_child(typing_timer)
	
	load_chat_history() 
	
	if conversation_history.size() == 0:
		conversation_history = [
			{
				"role": "system",
				"text": npc_prompt 
			}
		]
	else:
		# 💡 终极防爆：如果第一条是 system，更新它；如果不是，强制插在最前面！
		if conversation_history[0].get("role") == "system":
			conversation_history[0]["text"] = npc_prompt
		else:
			conversation_history.insert(0, {"role": "system", "text": npc_prompt})
	
	var story = Global.story[lang].get("chat_intro")
	if Global.chat_tutorial_finished == false:
		Global.play_dialogue(story)
		
	var current_scene = get_tree().current_scene
	var active_dialogue = current_scene.get_child(current_scene.get_child_count() - 1)
	
	if active_dialogue:
		active_dialogue.tree_exited.connect(_on_intro_finished)



	



func match_language():
	match lang:
		"ch": 
			reply_language = "简体中文 (Simplified Chinese)"
			fail_message = "⚠️ 消息已发出，但被对方拒收了。"
			entering = "对方正在输入中..."
			show_image_message = "对方发送了照片 (照片里显示了支付成功的画面)"
		"en": 
			reply_language = "English"
			fail_message = "⚠️ Message sent but rejected by recipient."
			entering = "Entering..."
			show_image_message = "The recipient sent an image (showing a successful payment confirmation)."
		# 🌟 新增：马来西亚官方语言 - 马来文 
		"bm": 
			reply_language = "Bahasa Melayu (Malaysian)"
			fail_message = "⚠️ Mesej telah dihantar, tetapi disekat oleh penerima."
			entering = "Sedang menaip..."
			show_image_message = "Penerima menghantar sekeping foto (menunjukkan pengesahan pembayaran berjaya)."
		# 🌟 新增：马来西亚印度裔通用语言 - 淡米尔文
		"bt": 
			reply_language = "தமிழ் (Tamil - Malaysian)"
			fail_message = "⚠️ செய்தி அனுப்பப்பட்டது, ஆனால் பெறுநரால் நிராகரிக்கப்பட்டது."
			entering = "தட்டச்சு செய்கிறது..."
			show_image_message = "பெறுநர் ஒரு படத்தை அனுப்பியுள்ளார் (வெற்றிகரமான கட்டண உறுதிப்படுத்தலைக் காட்டுகிறது)."

func _on_intro_finished():
	
	Global.chat_tutorial_finished = true
	Global.save_game_status()
	
	
	



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
	
	
	


func _process(delta):
	if Input.is_action_just_pressed("ui_accept"):
		_on_send_pressed()
	
	


func _on_send_pressed():
	var user_text = input_box.text.strip_edges()
	if user_text == "":
		return
		
	input_box.editable = false
	send_button.disabled = true
	
	
	# 🟦 把玩家的发言加入history
	conversation_history.append({"role": "user", "text": user_text}) 
	print("\n\n")
	print(conversation_history)
	# 最多保留 10 轮对话（节省 token）
	# 最多保留 10 轮对话（节省 token）
	if conversation_history.size() > 10:
		conversation_history.remove_at(1) # 🌟 核心修改：保护 index 0 的 system，删除 index 1 的旧对话
		
	# 1. 玩家自己的气泡【立刻】生成，输入框【立刻】清空
	create_bubble(user_text, true)
	input_box.text = ""
	save_chat_history() # 马上保存玩家刚发的那句话
	
	# 2. 🌟 核心调整：在这里强制停顿 1 秒，模拟对方刚看到消息的反应时间
	await get_tree().create_timer(1.0).timeout
	
	# 3. 1秒后，才弹出假装正在输入的 AI 气泡
	current_ai_label = create_bubble(entering, false)
	
	# 4. 最后才正式向大模型发送请求
	send_message()


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
	
	# 🔓 核心新增：只要有回应（不管成功失败），且不是在做通关总结，就解锁输入框
	if is_fetching_conclusion == false:
		input_box.editable = true
		send_button.disabled = false
	
	# 🌟 加强版防卡死机制：不仅查 HTTP 状态，还查 Godot 底层的请求结果（处理超时/断网）
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		var err_msg = "网络开小差了"
		if result == HTTPRequest.RESULT_TIMEOUT:
			err_msg = "AI 思考太久，请求超时了"
			
		if current_ai_label:
			current_ai_label.text = err_msg + " (Error: " + str(response_code) + ")"
			current_ai_label = null # 释放掉，不让打字机接管
			
		is_fetching_conclusion = false # 发生错误时安全重置
		return
	
	
	
	var reply_json = JSON.parse_string(body.get_string_from_utf8())
	if reply_json != null and reply_json.has("candidates"):
		var reply_text = reply_json["candidates"][0]["content"]["parts"][0]["text"].strip_edges()
		
		# 🌟 核心分流：如果是来拿总结的，走 Conny 对话框逻辑
		if is_fetching_conclusion == true && response_code == 200:
			is_fetching_conclusion = false # 马上关掉开关
			
			# 清洗 AI 可能手贱加上的 markdown 代码块标签
			var clean_text = reply_text.replace("```json", "").replace("```", "").strip_edges()
			var dialogue_array = JSON.parse_string(clean_text)
			
			if dialogue_array is Array:
				Global.play_dialogue(dialogue_array)
				
				# 等待 0.1 秒让对话框实例挂载，然后绑定对话结束信号
				await get_tree().create_timer(0.1).timeout
				var current_scene = get_tree().current_scene
				var active_dialogue = current_scene.get_child(current_scene.get_child_count() - 1)
				# 🌟👇 把下面这三行加上 👇🌟
				if active_dialogue and active_dialogue.has_signal("tree_exited"):
					active_dialogue.tree_exited.connect(_on_conclusion_finished, CONNECT_ONE_SHOT)
				else:
					# 万一解析失败，也强行通关防止卡死
					_on_conclusion_finished()
			return # 总结跑完直接 return，绝不能让它变成聊天气泡！
			
		elif is_fetching_conclusion == false && response_code != 200:
			_on_conclusion_finished()
			
			

		# 🟦 下面是原本正常的聊天气泡处理逻辑 🟦
		conversation_history.append({"role": "assistant", "text": reply_text})
		if conversation_history.size() > 10:
			conversation_history.remove_at(1) 

		ai_full_response = reply_text
		ai_current_index = 0
		
		if current_ai_label:
			current_ai_label.text = ""
		else:
			current_ai_label = create_bubble("", false) 
			
		typing_timer.start()
		save_chat_history() 
		
	else:
		if current_ai_label:
			current_ai_label.text = "AI got problem"
			current_ai_label = null
		is_fetching_conclusion = false

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
	get_tree().change_scene_to_file("res://scene/bio.tscn")
	



func check_for_victory_pro(ai_text): 
	# 1. 统一剥离前后的空格和换行  
	var text_to_check = ai_text.strip_edges() 
	
	# 2. 🟩 核心判断：精准拦截小美的上钩标志性句子
	# 这里加了两个模糊兼容（带叹号和不带叹号），防止 AI 漏掉标点符号导致不触发
	if text_to_check.contains(success_id):
		on_victory()
		
		
	# 2. 🟥 判定失败：是否包含了连续三个感叹号 "!!!"
	if text_to_check.contains("!!!"):
		on_failure() # 呼叫失败处理函数
	
	
# 2. 🟥 🌟【防误判终极正则拦截】：判定失败
	var regex = RegEx.new()
	
	# 表达式微调解读：
	# [!！] 匹配第一个感叹号
	# \\s* 允许有任意空格
	# [!！] 匹配第二个感叹号
	# \\s* 允许有任意空格
	# [!！] 匹配第三个感叹号
	# 🎯 核心原理：中间去掉了允许文字的通配符，它只会在“感叹号全连在一起”时才触发！
	regex.compile("[!！]\\s*[!！]\\s*[!！]")
	
	var result = regex.search(text_to_check)
	
	if result:
		print("💀 成功拦截受害者愤然离场信号（3连感叹号）：", result.get_string())
		on_failure()


# 🟥 新增的失败处理函数
func on_failure():
	
	is_success = false
	
	# 这里写玩家失败后的逻辑，比如锁定输入框，弹出失败通知
	input_box.editable = false
	send_button.disabled = true
	input_box.visible = false
	send_button.visible = false
	
	
	# 给玩家一个气泡提示，比如 "对方已开启朋友验证，您还不是他的好友..."
	create_bubble(fail_message, false)
	
	
	await get_tree().create_timer(1.0).timeout
	
	
	# 2. 唤醒我们在场景里搭好的 SuccessLayer，并把初始透明度设为 0 (完全透明)
	$fail_layer.visible = true
	$fail_layer/ColorRect/again.disabled = false
	
	$fail_sound.play()
	
	



func on_victory():
	# 1. 生成照片气泡
	create_bubble(show_image_message, false)
	
	
	is_success = true
	
	# 2. 🚨 锁死输入框，防止玩家在 Conny 总结时乱发消息
	input_box.editable = false
	send_button.disabled = true
	input_box.visible = false
	send_button.visible = false
	
	#这里加一个定时器，过了1秒才执行以下代码
	await get_tree().create_timer(1.0).timeout
	
	# 2. 唤醒我们在场景里搭好的 SuccessLayer，并把初始透明度设为 0 (完全透明)
	$success_layer.visible = true
	$success_sound.play()
	
	Global.set(npc_done,true)
	
	Global.save_victim_states()
	
	if Global.Lily_done == true && Global.Midas_done == true && Global.Jane_done == true && Global.Stanley_done == true && Global.Simon_done == true:
		Global.game_end = true
	
	
	## 3. 🎬 电影级缓动动画：用 1.2 秒的时间，让这层画面缓慢变得完全不透明
	#var tween = create_tween()
	#tween.tween_property($success_layer, "modulate", Color(1, 1, 1, 1), 1.2)
	#
	## 4. 强制等待这段 1.2 秒的动画播完
	#await tween.finished
	
	# 5. 画面完全浮现，气氛烘托到位后，正式呼叫后台让 Conny 老师入场！
	conclusion()
	
	
	

func conclusion():
	
	
	# 打开分流开关，告诉系统下一条 API 回复是用来播放剧情的
	is_fetching_conclusion = true
	
	# 1. 提取真正的聊天记录，拼成纯文本
	var logs_string = ""
	for msg in conversation_history:
		if msg.get("role") == "system":
			continue
		var role_name = "骗子(玩家)" if msg.get("role") == "user" else "受害者(" + npc_name + ")"
		logs_string += role_name + ": " + msg.get("text", "") + "\n"
		

	# 3. 🌟 核心修改：双重替换！把聊天记录和语言占位符全部替换成真实数据
	var prompt = Global.conclude_prompt.replace("{CHAT_LOGS}", logs_string).replace("{reply_language}", reply_language)
	
	# 4. 构造给大模型的请求体
	var body = {
		"contents": [
			{
				"role": "user",
				"parts": [{"text": prompt}]
			}
		]
	}

	var url = "https://generativelanguage.googleapis.com/v1/models/gemini-3.1-flash-lite:generateContent?key=" + API_KEY
	var headers = ["Content-Type: application/json"]
	http.request(url, headers, HTTPClient.METHOD_POST, JSON.stringify(body))
	

# 🟩 新增：当 Conny 总结对话框被点完关闭后，自动执行这个函数
func _on_conclusion_finished():
	
	
	$success_layer/ColorRect/next_target.visible = true
	$success_layer/ColorRect/next_target.disabled = false



func _on_navigate_pressed():
	# 1. 删掉物理文件
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
	
	# 2. 清空当前数组（只保留 system prompt）
	conversation_history = [conversation_history[0]] 
	
	# 3. 清空 UI 上的气泡
	for child in message_list.get_children():
		child.queue_free()
		
	
	
	get_tree().change_scene_to_file("res://scene/app.tscn")
	


func _on_delete_pressed():
	
	delete_conversation()
	
	


func delete_conversation():
	# 1. 删掉物理文件
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
	
	# 2. 清空当前数组（只保留 system prompt）
	conversation_history = [conversation_history[0]] 
	
	# 3. 清空 UI 上的气泡
	for child in message_list.get_children():
		child.queue_free()


# chat.gd 里的 Help 按钮修复段

func _on_help_pressed():
	# 🟩 1. 安全防错：如果当前正在放别的新手教程对话，先不允许点求助
	var current_scene = get_tree().current_scene
	var last_child = current_scene.get_child(current_scene.get_child_count() - 1)
	if last_child and last_child.name.contains("dialogue"):
		print("⚠️ [Chat Help] 正在播放其他剧情，请点完后再求助")
		return

	var help_data = null
	
	# 🟩 2. 动态拼接 NPC 名字（比如 "Midas_chat_help"、"Lily_chat_help"）
	var help_key = npc_name + "_chat_help"
	
	# 🟩 3. 核心层级修正：最外层是 Global.help，接着是 [lang]，再跟着子字典名
	if already_helped == false:
		var first_help_dict = Global.help[lang].get("first_help")
		if first_help_dict:
			help_data = first_help_dict.get(help_key)
	else:
		var second_help_dict = Global.help[lang].get("second_help")
		if second_help_dict:
			help_data = second_help_dict.get(help_key)
			
	# 🟩 4. 安全启动判定，防止数据不存在导致系统崩溃
	if help_data and help_data is Array:
		Global.play_dialogue(help_data)
		
		# 延迟一小帧，确保对话框已经实例进树，然后安全挂载死灭信号
		await get_tree().create_timer(0.02).timeout
		var active_dialogue = current_scene.get_child(current_scene.get_child_count() - 1)
		
		# 注意：用可信赖的单次性匿名函数绑定，能完美避开跟 ready 里的旧逻辑信号撞车
		if active_dialogue and active_dialogue.has_signal("tree_exited"):
			active_dialogue.tree_exited.connect(_on_help_finished, CONNECT_ONE_SHOT)
			print("🎯 [Chat Help] Conny 提示小助手启动成功，已安全绑定单次销毁信号。")
	else:
		print("⚠️ [Chat Help] 警告：在 Global 字典中找不到对应的提示键名: ", help_key)

# 🟩 当 Conny 喷完并教完话术、对话框物理粉碎时自动执行
func _on_help_finished():
	already_helped = true
	print("✨ [Chat Help] 玩家已阅读第一轮提示，下次点击将自动升级为第二轮严厉吐槽模式。")




func _on_again_pressed():
	
	delete_conversation()
	Global.conversation_history = conversation_history
	
	
	get_tree().change_scene_to_file("res://scene/bio.tscn") 


func _on_next_target_pressed():
	delete_conversation()
	Global.conversation_history = conversation_history
	
	Global.current_chat_avatar = null
	Global.current_chat_name = null
	
	get_tree().change_scene_to_file("res://scene/app.tscn")


func _on_note_pressed():
	var popup = NOTE_POPUP_SCENE.instantiate()
	
	# 2. 🟩 核心：直接把它作为子节点加到当前主界面最底层
	# 因为 Godot 的渲染规则是“越靠下的节点，渲染在越表面”
	# 它会自动完美覆盖在你的 time、start、setting、quit 之上！
	get_tree().current_scene.add_child(popup)
