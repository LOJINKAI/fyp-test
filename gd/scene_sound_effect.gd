extends AudioStreamPlayer

# 预加载你的 4 个音乐文件
var success_sound = preload("res://sound/result/success.mp3")
var fail_sound = preload("res://sound/result/fail.mp3")
var kick_door_sound = preload("res://sound/result/kick door.mp3")


@onready var player = $"."

# 核心功能：带防重启逻辑的切换音乐
# 在你的 BGM_Manager.gd 中
func play_sound(type):
	# 如果 type 为 null 或空字符串，说明不想切歌，直接返回，保持当前播放
	if type == null or type == "":
		return 
		
	var new_stream = null
	match type:
		"success_sound": new_stream = success_sound
		"fail_sound": new_stream = fail_sound
		"kick_door_sound": new_stream = kick_door_sound
	
	if new_stream:
		# 检查是否已经在播这首了，如果是，直接返回，不从头播放
		if player.stream == new_stream and player.playing:
			return
			
	player.stream = new_stream
	player.play()
	# ... 后面的判断逻辑保持不变



# 停止音乐
func stop_sound():
	player.stop()
