extends TextEdit

@onready var chat_body = $"../../../../body"

const MIN_HEIGHT: float = 80.0   
const MAX_HEIGHT: float = 180.0   

func _ready():
	custom_minimum_size.y = MIN_HEIGHT

func _process(_delta):
	var visual_lines = 0
	for i in range(get_line_count()):
		visual_lines += 1 + get_line_wrap_count(i)
		
	var real_line_height = get_line_height()
	var target_height = MIN_HEIGHT + (visual_lines - 1) * real_line_height
	
	if target_height > MAX_HEIGHT:
		target_height = MAX_HEIGHT
		
	
	if custom_minimum_size.y != target_height:
		custom_minimum_size.y = target_height
		
		
		if chat_body:
		
			await get_tree().process_frame
			
			chat_body.scroll_vertical = chat_body.get_v_scroll_bar().max_value
			

	if target_height < MAX_HEIGHT:
		
		scroll_vertical = 0.0
	else:
		var v_scroll = get_v_scroll_bar()
		if v_scroll and v_scroll.visible:
			if get_caret_line() == get_line_count() - 1:
				v_scroll.value = v_scroll.max_value
