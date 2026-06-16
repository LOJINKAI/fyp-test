#chat.tscn

extends Control

const SAVE_PATH = Global.chat_history

const BUBBLE_SCENE = preload("res://scene/MessageBubble.tscn") 

const NOTE_POPUP_SCENE = preload("res://scene/note.tscn")

@onready var message_list = $main/body/message_list


@onready var input_box := $main/MarginContainer/footer/MarginContainer/InputScroll/TextEdit
@onready var input_scroll := $main/MarginContainer/footer/MarginContainer/InputScroll


@onready var send_button := $"main/MarginContainer/footer/send"

var http := HTTPRequest.new()
var typing_timer: Timer
var typing_speed := 0.03

var drag_velocity := 0.0
var is_dragging := false



var current_ai_label: Label = null
  
var ai_full_response := ""
var ai_current_index := 0 


var response_code

var API_KEY = apiKey.API_KEY


var is_fetching_conclusion = false


var is_success

var success_id
var reply_language
var fail_message
var entering
var show_image_message

var game_end



var conversation_history := []


var npc_name = Global.current_chat_name
var npc_prompt
var lang = Global.current_language


var already_helped = false


var time_out_msg
var error_msg


var npc_done = npc_name + "_done"


func _ready():
	
	
	
	
	
	match_language()
	
	
	
	
	#random generate id
	success_id = str(randi_range(1000, 9999))
	print("\n\nsuccess id = ",success_id)
	
	reply_language = reply_language
	print("\n\nlanguage = ",reply_language)
	
	npc_prompt = Global.npc_prompt.get(npc_name).replace("{reply_language}", reply_language).replace("{success_id}", success_id)
	
	
	$main/top/MarginContainer/HBoxContainer/Label.text = npc_name
	$main/top/MarginContainer/HBoxContainer/PanelContainer/photo.texture = Global.current_chat_avatar
	
	
	if input_box:
		
		input_box.scroll_fit_content_height = true 
		
		
		
		var v_scroll = input_scroll.get_v_scroll_bar()
		v_scroll.modulate = Color(1, 1, 1, 0)
		v_scroll.scale.x = 0
	
	
	
	add_child(http)
	http.connect("request_completed", Callable(self, "_on_request_completed"))
	send_button.connect("pressed", Callable(self, "_on_send_pressed()"))
	
	input_box.text_changed.connect(_on_text_edit_text_changed)
	
	typing_timer = Timer.new()
	typing_timer.wait_time = typing_speed
	typing_timer.connect("timeout", Callable(self, "_on_typing_timer_timeout"))
	add_child(typing_timer)
	
	ProjectSettings.set_setting("display/window/handheld/page_focus_mode", 0)
	
	input_box.gui_input.connect(_on_input_box_gui_input)
	
	load_chat_history() 
	
	if conversation_history.size() == 0:
		conversation_history = [
			{
				"role": "system",
				"text": npc_prompt 
			}
		]
	else:
		
		if conversation_history[0].get("role") == "system":
			conversation_history[0]["text"] = npc_prompt
		else:
			conversation_history.insert(0, {"role": "system", "text": npc_prompt})
	
	
	
	
	
	if Global.check_story("chat_intro"):
		var story = Global.story[lang].get("chat_intro")
		Global.play_dialogue(story)
		
		var current_scene = get_tree().current_scene
		var active_dialogue = current_scene.get_child(current_scene.get_child_count() - 1)
		
		if active_dialogue:
			active_dialogue.tree_exited.connect(_on_intro_finished)


func _on_input_box_gui_input(event):
	
	if input_scroll.size.y >= 180:
		
		
		if event is InputEventScreenDrag or (event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)):
			is_dragging = true
			
			
			input_scroll.scroll_vertical -= event.relative.y
			drag_velocity = event.relative.y
			
			
			input_box.accept_event()
			
		
		elif event is InputEventScreenTouch or event is InputEventMouseButton:
			if not event.pressed:
				is_dragging = false


func _process(delta):
	var keyboard_height = DisplayServer.virtual_keyboard_get_height()
	var main_container = $main 
	if main_container:
		var target_bottom = -keyboard_height
		if main_container.offset_bottom != target_bottom:
			main_container.offset_bottom = target_bottom
			if keyboard_height > 0:
				scroll_to_bottom()
	
	if input_scroll and not is_dragging and abs(drag_velocity) > 0.1:
		input_scroll.scroll_vertical -= drag_velocity
		
		
		drag_velocity = lerp(drag_velocity, 0.0, 15.0 * delta)
	




func match_language():
	match lang:
		"ch": 
			reply_language = "简体中文 (Simplified Chinese)"
			fail_message = "⚠️ 消息已发出，但被对方拒收了。"
			entering = "对方正在输入中..."
			show_image_message = "对方发送了照片 (支付成功截图)"
			error_msg = "⚠️ 信号有点差，请检查网络再试。"
			time_out_msg = "⚠️ 对方好像没收到，请再发送信息。"
			
		"en": 
			reply_language = "English"
			fail_message = "⚠️ Message sent but rejected by recipient."
			entering = "Typing..."
			show_image_message = "The recipient sent an image (showing a successful payment confirmation)."
			error_msg = "⚠️ Poor signal, please check your network and try again."
			time_out_msg = "⚠️ Connection timed out. Please try sending again."
		
		"bm": 
			reply_language = "Bahasa Melayu (Malaysian)"
			fail_message = "⚠️ Mesej telah dihantar, tetapi disekat oleh penerima."
			entering = "Sedang menaip..."
			show_image_message = "Penerima menghantar sekeping foto (menunjukkan pengesahan pembayaran berjaya)."
			error_msg = "⚠️ Isyarat lemah, sila semak rangkaian anda dan cuba lagi."
			time_out_msg = "⚠️ Sambungan tamat masa. Sila hantar semula."
		
		"bt": 
			reply_language = "தமிழ் (Tamil - Malaysian)"
			fail_message = "⚠️ செய்தி அனுப்பப்பட்டது, ஆனால் பெறுநரால் நிராகரிக்கப்பட்டது."
			entering = "தட்டச்சு செய்கிறது..."
			show_image_message = "பெறுநர் ஒரு படத்தை அனுப்பியுள்ளார் (வெற்றிகரமான கட்டண உறுதிப்படுத்தலைக் காட்டுகிறது)."
			error_msg = "⚠️ சிக்னல் சரியாக இல்லை, உங்கள் இணையத்தை சரிபார்த்து மீண்டும் முயற்சிக்கவும்."
			time_out_msg = "⚠️ இணைப்பு நேரம் முடிந்தது. மீண்டும் அனுப்பவும்."


func _on_intro_finished():
	
	Global.advance_story()
	Global.save_game_status()
	
	
	var popup = NOTE_POPUP_SCENE.instantiate()
	
	get_tree().current_scene.add_child(popup)
	
	



func save_chat_history():
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		
		var json_string = JSON.stringify(conversation_history)
		file.store_string(json_string)
		file.close()
		

func load_chat_history():
	if not FileAccess.file_exists(SAVE_PATH):
		return 

	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		file.close()
		
		
		var data = JSON.parse_string(json_string)
		if data is Array:
			conversation_history = data
			
			
			for message in conversation_history:
				var role = message.get("role", "")
				
				
				if role == "system":
					continue
				
				
				var msg_text = ""
				
				if message.has("text"):
					
					msg_text = message["text"]
				elif message.has("parts") and message["parts"] is Array and message["parts"].size() > 0:
					
					msg_text = message["parts"][0].get("text", "")
				
				
				if msg_text == "":
					continue
					
				
				if role == "user":
					create_bubble(msg_text, true)
				elif role == "assistant" or role == "model":
					create_bubble(msg_text, false)
	
	
	


func _on_send_pressed():
	var user_text = input_box.text.strip_edges()
	if user_text == "":
		return
		
	input_box.editable = false
	send_button.disabled = true
	
	
	
	conversation_history.append({"role": "user", "text": user_text}) 
	print("\n\n")
	print(conversation_history)
	
	if conversation_history.size() > 10:
		conversation_history.remove_at(1) 
		
	
	create_bubble(user_text, true)
	
	
	
	input_box.text = ""
	input_scroll.custom_minimum_size.y = 90
	input_scroll.size.y = 90
	
	
	
	
	
	save_chat_history()
	
	
	await get_tree().create_timer(1.0).timeout
	
	
	current_ai_label = create_bubble(entering, false)
	
	
	send_message()


func scroll_to_bottom():
	
	await get_tree().process_frame
	var scroll_container = $main/body 
	scroll_container.scroll_vertical = scroll_container.get_v_scroll_bar().max_value

 
func create_bubble(content, is_mine):
	var bubble = BUBBLE_SCENE.instantiate()
	message_list.add_child(bubble)
	
	var label = bubble.get_node("Content") 
	
	label.text = content 
	
	
	
	var font = label.get_theme_font("font")
	var font_size = label.get_theme_font_size("font_size")
	var text_width = font.get_string_size(content, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	
	if text_width > 350:
		
		label.custom_minimum_size.x = 350
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	else:
		
		label.custom_minimum_size.x = 0
		label.autowrap_mode = TextServer.AUTOWRAP_OFF
	
	
	
	
	
	if is_mine == true:
		
		bubble.size_flags_horizontal = Control.SIZE_SHRINK_END
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		
		
		bubble.modulate = Color(0.2, 0.6, 1.0, 1.0)
		

	else:
		
		bubble.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		
		
		bubble.modulate = Color(0.88, 0.88, 0.88, 1.0)
		
		
	
	
	
	label.update_minimum_size()
	if bubble.has_method("update_minimum_size"):
		bubble.update_minimum_size()
	
	
	message_list.queue_sort()
	
	
	
	
	scroll_to_bottom()
	
	
	return label
	


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
		
		var gemini_role = ""
		if item["role"] == "user":
			gemini_role = "user"
		else:
			gemini_role = "model"
			
		formatted_contents.append({
			"role": gemini_role,
			"parts": [{"text": item["text"]}]
		})

	var body = {
		"contents": formatted_contents
	}

	var headers = ["Content-Type: application/json"]
	http.request(url, headers, HTTPClient.METHOD_POST, JSON.stringify(body))


func _on_request_completed(result, response_code, headers, body):
	
	
	if is_fetching_conclusion == false:
		input_box.editable = true
		send_button.disabled = false
	
	
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		
		var show_player_error_message = error_msg
		
		if result == HTTPRequest.RESULT_TIMEOUT:
			show_player_error_message = time_out_msg
			
		if current_ai_label:
			current_ai_label.text = show_player_error_message
			
			
			var font = current_ai_label.get_theme_font("font")
			var font_size = current_ai_label.get_theme_font_size("font_size")
			var text_width = font.get_string_size(current_ai_label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
			
			if text_width > 350:
				current_ai_label.custom_minimum_size.x = 350
				current_ai_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			else:
				current_ai_label.custom_minimum_size.x = 0
				current_ai_label.autowrap_mode = TextServer.AUTOWRAP_OFF
				
			current_ai_label.update_minimum_size()
			message_list.queue_sort()
			scroll_to_bottom()
			
			
			
			current_ai_label = null
			
		is_fetching_conclusion = false
		return
	
	
	
	var reply_json = JSON.parse_string(body.get_string_from_utf8())
	if reply_json != null and reply_json.has("candidates"):
		var reply_text = reply_json["candidates"][0]["content"]["parts"][0]["text"].strip_edges()
		
		
		if is_fetching_conclusion == true && response_code == 200:
			is_fetching_conclusion = false 
			
			
			var clean_text = reply_text.replace("```json", "").replace("```", "").strip_edges()
			var dialogue_array = JSON.parse_string(clean_text)
			
			if dialogue_array is Array:
				Global.play_dialogue(dialogue_array)
				
				
				await get_tree().create_timer(0.1).timeout
				var current_scene = get_tree().current_scene
				var active_dialogue = current_scene.get_child(current_scene.get_child_count() - 1)
				
				if active_dialogue and active_dialogue.has_signal("tree_exited"):
					active_dialogue.tree_exited.connect(_on_conclusion_finished, CONNECT_ONE_SHOT)
				else:
					
					_on_conclusion_finished()
			return 
			
		elif is_fetching_conclusion == false && response_code != 200:
			_on_conclusion_finished()
			
			

		
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
		
		var font = current_ai_label.get_theme_font("font")
		var font_size = current_ai_label.get_theme_font_size("font_size")
		var text_width = font.get_string_size(current_ai_label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		var total_width = text_width + 40
		
		if total_width > 350:
			
			current_ai_label.custom_minimum_size.x = 350
			current_ai_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		else:
			
			current_ai_label.custom_minimum_size.x = total_width
			current_ai_label.autowrap_mode = TextServer.AUTOWRAP_OFF
			
		
		current_ai_label.update_minimum_size()
		message_list.queue_sort()
		
		
		scroll_to_bottom()  
	else:
		typing_timer.stop()
		
		check_for_victory_pro(ai_full_response)
		
		
		current_ai_label = null 

func _on_quit_pressed():
	SoundEffect.play_sound("ui_click")
	get_tree().change_scene_to_file("res://scene/bio.tscn")
	



func check_for_victory_pro(ai_text): 
	
	var text_to_check = ai_text.strip_edges() 
	
	
	if text_to_check.contains(success_id):
		on_victory()
		
		
	
	if text_to_check.contains("!!!"):
		on_failure()  
	
	
	var regex = RegEx.new()
	
	
	regex.compile("[!！]\\s*[!！]\\s*[!！]")
	
	var result = regex.search(text_to_check)
	
	if result:
		
		on_failure()


func on_failure():
	
	is_success = false
	
	
	input_box.editable = false
	send_button.disabled = true
	input_box.visible = false
	send_button.visible = false
	
	
	
	create_bubble(fail_message, false)
	
	
	await get_tree().create_timer(1.0).timeout
	
	
	
	$fail_layer.visible = true
	$fail_layer/ColorRect/again.disabled = false
	
	SceneSoundEffect.play_sound("fail_sound")
	delete_conversation_history_only()
	



func on_victory():
	
	create_bubble(show_image_message, false)
	
	
	is_success = true
	
	
	input_box.editable = false
	send_button.disabled = true
	input_box.visible = false
	send_button.visible = false
	
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
	
	
	await get_tree().create_timer(1.0).timeout
	
	
	$success_layer.visible = true
	SceneSoundEffect.play_sound("success_sound")
	
	Global.set(npc_done,true)
	
	Global.save_game_status()
	
	if Global.Lily_done == true && Global.Midas_done == true && Global.Jane_done == true && Global.Stanley_done == true && Global.Simon_done == true:
		Global.game_end = true
	
	

	
	
	conclusion()
	
	

func conclusion():
	
	
	is_fetching_conclusion = true
	
	var logs_string = ""
	for msg in conversation_history:
		if msg.get("role") == "system":
			continue
		var role_name = "骗子(玩家)" if msg.get("role") == "user" else "受害者(" + npc_name + ")"
		logs_string += role_name + ": " + msg.get("text", "") + "\n"
		
		
	var current_language_boss_name
	match lang:
		"ch": 
			current_language_boss_name = "诈骗头目"
		"en": 
			current_language_boss_name = "Scam Boss"
		
		"bm": 
			current_language_boss_name = "Boss Scam"
		"bt": 
			current_language_boss_name = "மோசடி தலைவன்"
			
		
	#
	var prompt = Global.conclude_prompt.replace("{CHAT_LOGS}", logs_string).replace("{reply_language}", reply_language).replace("{current_language_boss_name}",current_language_boss_name)
	
	
	
	
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
	
	
	conversation_history = [conversation_history[0]]
	


func _on_conclusion_finished():
	
	
	$success_layer/ColorRect/next_target.visible = true
	$success_layer/ColorRect/next_target.disabled = false




func _on_delete_pressed():
	SoundEffect.play_sound("ui_click")
	
	delete_conversation()
	
	


func delete_conversation():
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
	
	
	conversation_history = [conversation_history[0]] 
	
	
	for child in message_list.get_children():
		child.queue_free()



func delete_conversation_history_only():
	
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
	
	
	conversation_history = [conversation_history[0]]



func _on_help_pressed():
	SoundEffect.play_sound("ui_click")
	
	var current_scene = get_tree().current_scene
	var last_child = current_scene.get_child(current_scene.get_child_count() - 1)
	if last_child and last_child.name.contains("dialogue"):
		
		return

	var help_data = null
	
	
	var help_key = npc_name + "_chat_help"
	
	
	if already_helped == false:
		var first_help_dict = Global.help[lang].get("first_help")
		if first_help_dict:
			help_data = first_help_dict.get(help_key)
	else:
		var second_help_dict = Global.help[lang].get("second_help")
		if second_help_dict:
			help_data = second_help_dict.get(help_key)
			
	
	if help_data and help_data is Array:
		Global.play_dialogue(help_data)
		
		
		await get_tree().create_timer(0.02).timeout
		var active_dialogue = current_scene.get_child(current_scene.get_child_count() - 1)
		
		
		if active_dialogue and active_dialogue.has_signal("tree_exited"):
			active_dialogue.tree_exited.connect(_on_help_finished, CONNECT_ONE_SHOT)



func _on_help_finished():
	already_helped = true




func _on_again_pressed():
	SoundEffect.play_sound("ui_click")
	delete_conversation()
	Global.conversation_history = conversation_history
	
	
	get_tree().change_scene_to_file("res://scene/bio.tscn") 


func _on_next_target_pressed():
	SoundEffect.play_sound("ui_click")
	delete_conversation()
	Global.conversation_history = conversation_history
	
	Global.current_chat_avatar = null
	Global.current_chat_name = null
	
	get_tree().change_scene_to_file("res://scene/app.tscn")


func _on_note_pressed():
	SoundEffect.play_sound("ui_click")
	var popup = NOTE_POPUP_SCENE.instantiate()
	

	get_tree().current_scene.add_child(popup)





func _on_text_edit_text_changed():
	
	await get_tree().process_frame
	
	var min_height = 90  
	var max_height = 180  
	
	input_scroll.custom_minimum_size.y = 0
	input_scroll.size.y = 0
	input_box.size.y = 0
	
	
	

	var real_height = input_box.get_combined_minimum_size().y 
	
	var target_height = clamp(real_height, min_height, max_height)
	input_scroll.custom_minimum_size.y = target_height
	input_scroll.size.y = target_height 
	
	
	
	
	if real_height > max_height:
		await get_tree().process_frame
		
		
		var caret_y = input_box.get_caret_draw_pos().y
		var current_scroll = input_scroll.scroll_vertical
		
		
		if caret_y > (current_scroll + target_height - 40):
			input_scroll.scroll_vertical = caret_y - target_height + 60

