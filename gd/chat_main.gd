extends VBoxContainer

@onready var chat_body = $body 


const KEYBOARD_PADDING: float = 35.0

var last_keyboard_height = 0

func _process(_delta):
	
	if OS.get_name() != "Android" and OS.get_name() != "iOS":
		offset_top = 0
		offset_left = 0
		offset_right = 0
		offset_bottom = 0
		return

	var window_size = DisplayServer.window_get_size()
	if window_size.x == 0 or window_size.y == 0:
		return
		
	var viewport_size = get_viewport_rect().size
	var scale_ratio_y = viewport_size.y / float(window_size.y)
	
	
	var kb_height = DisplayServer.virtual_keyboard_get_height()
	
	
	offset_top = 0
	offset_left = 0
	offset_right = 0
	
	
	if kb_height > 0:
		 
		var target_bottom = (kb_height * scale_ratio_y) + KEYBOARD_PADDING
		offset_bottom = -target_bottom
	else:
		offset_bottom = 0
	
	
	if kb_height > 0 and last_keyboard_height == 0:
		if chat_body:
			call_deferred("_scroll_to_bottom")
			
	last_keyboard_height = kb_height


func _scroll_to_bottom():
	
	await get_tree().process_frame
	await get_tree().process_frame
	if chat_body:
		var v_scroll = chat_body.get_v_scroll_bar()
		if v_scroll:
			
			chat_body.scroll_vertical = v_scroll.max_value - v_scroll.page
