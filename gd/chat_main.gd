extends VBoxContainer

@onready var chat_body = $body 

# 🌟 强哥，如果手机键盘弹起后还是会吞掉一点点内容，就调大这个缓冲区（单位：游戏内像素）
# 它会给输入框和键盘之间留出一段舒服的“呼吸空间”
const KEYBOARD_PADDING: float = 35.0

var last_keyboard_height = 0

func _process(_delta):
	# 电脑运行直接归零拦截，不折腾预览画面
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
	
	# 实时获取当前键盘高度
	var kb_height = DisplayServer.virtual_keyboard_get_height()
	
	# ========================================================
	# 🌟 修复 1：顶部和左右全部归零！
	# 因为关闭了沉浸模式，安卓已经帮我们把状态栏和镜头完美让开了。
	# 这里设为 0，顶部多出来的奇怪白色空块会瞬间消失，完美恢复！
	# ========================================================
	offset_top = 0
	offset_left = 0
	offset_right = 0
	
	# ========================================================
	# 🌟 修复 2：底部加入自定义 Padding 缓冲区，防止键盘压线
	# ========================================================
	if kb_height > 0:
		# 键盘像素高度换算 + 强哥专属安全缓冲
		var target_bottom = (kb_height * scale_ratio_y) + KEYBOARD_PADDING
		offset_bottom = -target_bottom
	else:
		offset_bottom = 0
	
	# 侦测键盘刚刚弹出的那一瞬间
	if kb_height > 0 and last_keyboard_height == 0:
		if chat_body:
			call_deferred("_scroll_to_bottom")
			
	last_keyboard_height = kb_height

# 精准滚到底部
func _scroll_to_bottom():
	# 连续等待两帧！死死确保 Godot 已经把整个聊天布局被顶起、缩水的数据全部算死
	await get_tree().process_frame
	await get_tree().process_frame
	if chat_body:
		var v_scroll = chat_body.get_v_scroll_bar()
		if v_scroll:
			# 修正 Godot 的精确滚底公式：最大值减去当前视口页高
			chat_body.scroll_vertical = v_scroll.max_value - v_scroll.page
