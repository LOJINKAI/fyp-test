extends AudioStreamPlayer

# 预加载你的 4 个音乐文件
var music_menu = preload("res://sound/bgm/main.mp3")
var music_gameplay = preload("res://sound/bgm/game.mp3")
var music_before_police = preload("res://sound/bgm/bad_end.mp3")
var music_police = preload("res://sound/bgm/good_end.mp3")

@onready var player = $"."

# 核心功能：带防重启逻辑的切换音乐
# 在你的 BGM_Manager.gd 中
func play_music(type):
	# 如果 type 为 null 或空字符串，说明不想切歌，直接返回，保持当前播放
	if type == null or type == "":
		return 
		
	var new_stream = null
	match type:
		"main": new_stream = music_menu
		"game": new_stream = music_gameplay
		"before_police": new_stream = music_before_police
		"police": new_stream = music_police
	
	if new_stream:
		# 检查是否已经在播这首了，如果是，直接返回，不从头播放
		if player.stream == new_stream and player.playing:
			return
			
	player.stream = new_stream
	player.play()
	# ... 后面的判断逻辑保持不变



# 停止音乐
func stop_music():
	player.stop()
