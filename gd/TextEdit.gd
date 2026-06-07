extends TextEdit

# 🌟 向上找 3 层，精准抓到你的聊天记录区 (TextEdit -> footer -> MarginContainer -> main -> body)
@onready var chat_body = $"../../../../body"

const MIN_HEIGHT: float = 80.0    # 初始单行高度
const MAX_HEIGHT: float = 180.0   # 最高限制高度

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
		
	# ========================================================
	# 🌟 联动核心：高度发生变化时，推高聊天记录！
	# ========================================================
	if custom_minimum_size.y != target_height:
		custom_minimum_size.y = target_height
		
		# 🔥 如果抓到了聊天记录区，强制让它滚到最底下！
		if chat_body:
			# 必须等一帧，让 Godot 先把挤压变矮的 UI 尺寸算好
			await get_tree().process_frame
			# 强行把 ScrollContainer 的滚动条拽到最大值（最底部）
			chat_body.scroll_vertical = chat_body.get_v_scroll_bar().max_value
			
	# ========================================================
	# 🌟 防吞第一行 & 内部滚动锁
	# ========================================================
	if target_height < MAX_HEIGHT:
		# 没顶到天花板前，锁死内部滚动，第一行稳如泰山！
		scroll_vertical = 0.0
	else:
		var v_scroll = get_v_scroll_bar()
		if v_scroll and v_scroll.visible:
			if get_caret_line() == get_line_count() - 1:
				v_scroll.value = v_scroll.max_value
