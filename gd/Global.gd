#global.gd

extends Node



#save file
const victim_file = "user://victim_status.json"
const game_status = "user://game_status.json"
const game_setting = "user://game_setting.json"
const chat_history = "user://chat_history.json"


const DIALOGUE_SYSTEM = preload("res://scene/dialogue.tscn")

var current_language 
var reply_language


var bgm_volume = 20.0
var sound_effect_volume = 80.0

# 用来存储当前正在聊天的人的头像图片
var current_chat_avatar = null

# 用来存储当前正在聊天的人的名字
var current_chat_name = null

var new_game = true

var chat_logs


var conversation_history

var fail_message
var entering
var show_image_message

#record victim block status
var Lily_current_block = false
var Midas_current_block = false
var Jane_current_block = false
var Stanley_current_block = false


#record victim done or not
var Lily_done = false
var Midas_done = false
var Jane_done = false
var Stanley_done = false
var Simon_done = false

var game_end = false

#record tutorial
var phone_tutorial_finished = false
var app_tutorial_finished = false
var bio_tutorial_finished = false
var chat_tutorial_finished = false


# 预载刚刚做好的全宇宙最高层级黑幕
const FADE_LAYER_SCENE = preload("res://scene/fade_layer.tscn")
var fade_instance: CanvasLayer
var fade_mask: ColorRect


func _ready():
	
	print("Language = ",current_language)
	
	# 🟩 游戏一启动，就自动加载本地所有的屏蔽数据，保证变量在内存中是最新的
	laod_game_setting()
	load_victim_states()
	load_game_status()
	
	load_game_sound_volume()
	
	
	

	 #🟩 1. 物理安全加载黑幕
	fade_instance = FADE_LAYER_SCENE.instantiate()
	
	# 🟩 2. 核心修正：放弃延迟加载，直接用最高优先级的引擎底层命令物理焊死在游戏最表面！
	get_tree().root.add_child.call_deferred(fade_instance)
	
	# 🟩 3. 游戏启动时，默认将遮罩颜色彻底洗成全透明，防止有些误操作导致开局黑屏
	fade_mask = fade_instance.get_node("mask")
	if fade_mask:
		fade_mask.color = Color(0, 0, 0, 0.0)
		
	
	


func reset_and_new_game():
	
	if FileAccess.file_exists(victim_file): 
		DirAccess.remove_absolute(victim_file)
	if FileAccess.file_exists(game_status):
		DirAccess.remove_absolute(game_status)
	if FileAccess.file_exists(chat_history): 
		DirAccess.remove_absolute(chat_history)
		
	#record tutorial
	phone_tutorial_finished = false
	app_tutorial_finished = false
	bio_tutorial_finished = false
	chat_tutorial_finished = false
	
	Lily_done = false
	Midas_done = false
	Jane_done = false
	Stanley_done = false
	Simon_done = false
	
	load_victim_states()
	load_game_status()



func load_game_sound_volume():
	var bgm_db = linear_to_db(bgm_volume / 100.0)
	if bgm_volume == 0: bgm_db = -80
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("bgm"), bgm_db)
	
	var sound_effect_db = linear_to_db(sound_effect_volume / 100.0)
	if sound_effect_volume == 0: 
		sound_effect_db = -80
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("sound_effect"), sound_effect_db)


#这个是黑屏罢了，没有换界面
func fade_layer(duration = 1.0):
	# 1. 安全防爆抓取
	if not fade_mask:
		fade_mask = fade_instance.get_node_or_null("mask")
	
	# 2. 🟥 第一阶段：用 Tween 缓慢变黑（按照你规定的时间，比如 2.0 秒）
	fade_mask.color = Color(0, 0, 0, 0.0) # 确保从透明开始
	var tween = create_tween()
	tween.tween_property(fade_mask, "color", Color(0, 0, 0, 1.0), duration)
	await tween.finished
	
	# 3. 🌟 第二阶段：在这里你可以执行你要刷新文本的代码
	# 函数执行到这里时，屏幕是全黑的，你可以安全地在外面等待或者更新 UI
	
	# 4. 🟦 第三阶段：一微秒直接将黑幕人间蒸发！瞬间亮起！
	await get_tree().process_frame # 等一帧防闪烁
	fade_mask.color = Color(0, 0, 0, 0.0)
	
	print("✨ [Global] 纯黑幕已瞬间剥离亮起！")



#这个是黑屏后直接亮
func fade_to_scene(target_scene_path: String, duration: float = 2.0):
	# 安全防爆抓取
	if not fade_mask:
		fade_mask = fade_instance.get_node_or_null("mask")
		
	if not fade_mask:
		get_tree().change_scene_to_file(target_scene_path)
		return
		
	print("🎬 [Global] 触发单向黑屏转场，目标: ", target_scene_path)
	
	# 确保起始状态是透明的
	fade_mask.color = Color(0, 0, 0, 0.0) 
	await get_tree().process_frame
	
	# 1. 🟥 第一阶段：按照你规定的时间（比如 2.0 秒），缓慢黑屏淡出
	var tween = create_tween()
	tween.tween_property(fade_mask, "color", Color(0, 0, 0, 1.0), duration)
	await tween.finished
	
	# 2. 🟩 第二阶段：在全黑的绝对保护色下，物理替换底层场景
	get_tree().change_scene_to_file(target_scene_path)
	
	# 3. 🟦 第三阶段（核心修正）：不要动画！一微秒直接将黑幕人间蒸发！
	# 等一帧让新场景节点挂载上，然后瞬间把 Alpha 调成 0.0 亮起！
	await get_tree().process_frame
	fade_mask.color = Color(0, 0, 0, 0.0)
	
	print("✨ [Global] 底层场景已更新，黑幕已瞬间剥离亮起！")


#这个是直接转场了，从黑屏慢慢亮
func scene_to_fade(target_scene_path: String, duration: float = 2.0):
	# 安全防爆抓取
	if not fade_mask:
		fade_mask = fade_instance.get_node_or_null("mask")
		
	if not fade_mask:
		get_tree().change_scene_to_file(target_scene_path)
		return
		
	print("🎬 [Global] 触发反向闪现转场，目标: ", target_scene_path)
	
	# 1. 🟥 第一阶段：不要任何延迟！一微秒直接把黑幕掐成纯黑 (Alpha = 1.0)
	# 物理阻断玩家的视线，防止场景在切换的瞬间产生一丝一毫的穿帮画面
	fade_mask.color = Color(0, 0, 0, 1.0)
	
	# 2. 🟩 第二阶段：瞬间将底层场景物理替换过去
	get_tree().change_scene_to_file(target_scene_path)
	
	# 稍微给新场景一丁点微秒的节点挂载和排版时间
	await get_tree().process_frame
	await get_tree().create_timer(0.05).timeout
	
	# 3. 🟦 第三阶段：此时已经到了新关卡（新关卡背后是一片漆黑），现在开始优雅地拉开帷幕
	var tween_out = create_tween()
	# 让全屏的纯黑色，在规定的时间内（比如 2.0 秒），丝滑地变回完全透明 (Alpha = 0.0)
	tween_out.tween_property(fade_mask, "color", Color(0, 0, 0, 0.0), duration)
	
	await tween_out.finished
	print("✨ [Global] 反向转场完美结束，新界面已全亮披露！")

#这个是慢慢暗，慢慢亮
func fade_to_fade(target_scene_path: String, duration: float = 2.0):
	# 安全防爆抓取
	if not fade_mask:
		fade_mask = fade_instance.get_node_or_null("mask")
		
	if not fade_mask:
		get_tree().change_scene_to_file(target_scene_path)
		return
		
	print("🎬 [Global] 触发完美双向循环转场，目标: ", target_scene_path)
	
	# ----------------【第一阶段：逐渐黑屏】----------------
	# 确保起始状态是 100% 全透明的
	fade_mask.color = Color(0, 0, 0, 0.0) 
	await get_tree().process_frame
	
	var tween_in = create_tween()
	# 让全屏黑色遮罩在规定时间内（比如 2.0 秒），丝滑地变到纯黑色 (Alpha = 1.0)
	tween_in.tween_property(fade_mask, "color", Color(0, 0, 0, 1.0), duration)
	# 🔴 强制卡住！一定要等屏幕完全变黑了，才能执行下一步
	await tween_in.finished
	
	
	# ----------------【第二阶段：暗中换场】----------------
	# 在纯黑的绝对保护色下，物理替换底层场景，玩家眼睛绝不会看到任何穿帮或穿模
	get_tree().change_scene_to_file(target_scene_path)
	
	# 稍微给新场景 0.05 秒的时间让节点加载、排版和就位
	await get_tree().process_frame
	await get_tree().create_timer(0.05).timeout
	
	
	# ----------------【第三阶段：逐渐亮起】----------------
	var tween_out = create_tween()
	# 让全屏的纯黑色，再次在规定的时间内（比如 2.0 秒），丝滑地变回全透明 (Alpha = 0.0)
	tween_out.tween_property(fade_mask, "color", Color(0, 0, 0, 0.0), duration)
	# 🔵 等到屏幕完全亮起来了，整个转场才算彻底杀青闭环
	await tween_out.finished
	
	print("✨ [Global] 完美双向转场圆满结束！新场景已全亮披露。")




func save_game_status():
	var file = FileAccess.open(game_status, FileAccess.WRITE)
	if file:
		var data_to_save = {
			"new_game": new_game,
			"phone_tutorial_finished": phone_tutorial_finished,
			"app_tutorial_finished": app_tutorial_finished,
			"bio_tutorial_finished": bio_tutorial_finished,
			"chat_tutorial_finished": chat_tutorial_finished,
			"game_end": game_end

		}
		var json_string = JSON.stringify(data_to_save)
		file.store_string(json_string)
		file.close()



# 🟩 在游戏启动时，或者各个场景准备时调用，用来从本地文件读取屏蔽状态
func load_game_status():
	if not FileAccess.file_exists(game_status):
		new_game = true
		return # 文件不存在说明全是默认值
		
	var file = FileAccess.open(game_status, FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		file.close()
		
		var data = JSON.parse_string(json_string)
		if data is Dictionary:

			new_game = data.get("new_game", true)
			# 1. 恢复语言
			phone_tutorial_finished = data.get("phone_tutorial_finished", false)
			app_tutorial_finished = data.get("app_tutorial_finished", false)
			bio_tutorial_finished = data.get("bio_tutorial_finished", false)
			chat_tutorial_finished = data.get("chat_tutorial_finished", false)
			game_end = data.get("game_end", false)



func save_game_setting():
	var file = FileAccess.open(game_setting, FileAccess.WRITE)
	if file:
		var data_to_save = {
			"current_language": current_language,
			"bgm_volume": bgm_volume,
			"sound_effect_volume": sound_effect_volume,
		}
		var json_string = JSON.stringify(data_to_save)
		file.store_string(json_string)
		file.close()

func laod_game_setting():
	if not FileAccess.file_exists(game_setting):
		current_language = "en"
		return # 文件不存在说明全是默认值
		
	var file = FileAccess.open(game_setting, FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		file.close()
		
		var data = JSON.parse_string(json_string)
		if data is Dictionary:
			current_language = data.get("current_language", "en")
			bgm_volume = data.get("bgm_volume", 100.0)
			sound_effect_volume = data.get("sound_effect_volume", 100.0)




# 🟩 在游戏启动时，或者各个场景准备时调用，用来从本地文件读取屏蔽状态
func load_victim_states():
	if not FileAccess.file_exists(victim_file):
		return # 文件不存在说明全是默认值
		
	var file = FileAccess.open(victim_file, FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		file.close()
		
		var data = JSON.parse_string(json_string)
		if data is Dictionary:
			
			
			# 2. 恢复加入黑名单的屏蔽状态
			Lily_current_block = data.get("Lily_current_block", false)
			Midas_current_block = data.get("Midas_current_block", false)
			Jane_current_block = data.get("Jane_current_block", false)
			Stanley_current_block = data.get("Stanley_current_block", false)
			
			# 🟩 新增：从硬盘里安全恢复四个人的通关状态！
			Lily_done = data.get("Lily_done", false)
			Midas_done = data.get("Midas_done", false)
			Jane_done = data.get("Jane_done", false)
			Stanley_done = data.get("Stanley_done", false)
			Simon_done = data.get("Simon_done", false)
			

# 📝 只要状态一改变，就立刻物理写进硬盘
func save_victim_states():
	var file = FileAccess.open(victim_file, FileAccess.WRITE)
	if file:
		var data_to_save = {
			
			
			# 1. 储存点击黑名单的屏蔽状态
			"Lily_current_block": Lily_current_block,
			"Midas_current_block": Midas_current_block,
			"Jane_current_block": Jane_current_block,
			"Stanley_current_block": Stanley_current_block,
			
			# 🟩 新增：把四个受害者是否成功收割（Done）的状态也狠狠存进硬盘！
			"Lily_done": Lily_done,
			"Midas_done": Midas_done,
			"Jane_done": Jane_done,
			"Stanley_done": Stanley_done,
			"Simon_done": Simon_done 
			
		}
		var json_string = JSON.stringify(data_to_save)
		file.store_string(json_string)
		file.close()
		print("📝 [Global] 本地硬盘文件同步成功（已包含所有通关/屏蔽数据）。")

# 🟩 新增：供所有关卡/场景调用的物理清空聊天历史函数
func reset_victim_chat_history():
	var save_path = "user://chat_history.json"
	
	# 1. 物理安全删除受害者的聊天文件
	if FileAccess.file_exists(save_path):
		DirAccess.remove_absolute(save_path)
		print("🗑️ [Global] 已成功物理删除受害者历史对话文件。")
		
	# 2. 如果你的局部变量还挂载在内存里，顺手在这里切断引用
	conversation_history = null
	print("✨ [Global] 内存中的受害者对话数组已成功初始化重置。")
	

func play_dialogue(story_line):
	var dialogue_instance = DIALOGUE_SYSTEM.instantiate()
	
	# 🟩 核心魔法：直接把对话框塞进当前正在运行的那个活跃 Scene 的最顶层！
	get_tree().current_scene.add_child(dialogue_instance)
	
	# 启动剧情
	dialogue_instance.start_story(story_line)
	





var current_bio = {
	"ch": {
		"Lily": """
					🚨 每当看到朋友圈里有人展示自己多有钱又或者是投资什么东西发财了，我就焦虑得睡不着觉。
					📈 不过真的让我一个人去冒险投资又不敢，但看着别人都发财了，自己还是穷光蛋也很难受。
					💡 如果有可以发财的机会，只要有时间、有名额，我一定会死死抓紧，我也要跟其他人一样成功！
				""",
		"Midas": """
					💵 债务只是数字，但利润是真实的。早就受够了早九晚五打工的微薄薪水。
					🏎️ 梦想：全款拿下梦想中的保时捷911。
					🚨 如果可以靠一笔高杠杆交易就能一夜抹平所有贷款，干嘛还要熬30年？
					🚀 浪越大，鱼越贵！哪有小孩天天哭，哪有赌徒天天输！
				""",
		"Jane": """
					👥 只会跟大部分人的选择来判断正确，这么多人都这样做的话，一定有他的道理。
					🚨 从不做第一个尝试新事物的人。只有看到大家都在做才觉得安全。
				""",
		"Stanley": """
					👤 投资几年后的感想：
					🚨 散户只是盲目的韭菜。
					📈 要投资的话，还不如看真正的有钱人都在投资什么。
					""",
		"Simon": """
					👤 一个可怜的打工人。
					🚨 一个人生活的感觉真的很孤单。
					☕ 盼着哪天可以赚大钱，找个女朋友开开心心过日子。
				"""
	},
	"en": {
		"Lily": """
					🚨 Seeing people on my social feed showing off their wealth or getting rich from investments makes me so anxious I can't sleep.
					📈 But I don't dare to take the risk and invest all by myself. Yet, watching everyone else get rich while I stay dead broke is just unbearable.
					💡 If there's an opportunity to strike it rich, as long as the timing is right and slots are available, I will grab it tightly. I want to be as successful as everyone else!
				""",
		"Midas": """
					💵 Debt is just a number, but profit is real. I've had enough of the miserable salary from this 9-to-5 grind.
					🏎️ Dream: Paying cash in full for my dream Porsche 911.
					🚨 If a single high-leverage trade can wipe out all my loans overnight, why suffer for another 30 years?
					🚀 The bigger the waves, the bigger the catch! High risk, high reward—no gambler loses every single day!
				""",
		"Jane": """
					👥 I only judge what's right by following the majority's choice. If so many people are doing it, there must be a good reason.
					🚨 I am never the first to try new things. I only feel safe when I see everyone else doing it.
				""",
		"Stanley": """
					👤 Thoughts after years of investing:
					🚨 Retail investors are just blind sheep waiting to be sheared.
					📈 If you want to invest, you might as well look at what the truly wealthy are investing in.
				""",
		"Simon": """
					👤 Just a pitiful wage earner.
					🚨 Living alone feels incredibly lonely.
					☕ Hoping for the day I can make big money, find a girlfriend, and live a happy life together.
				"""
	},
	"bm": {
		"Lily": """
					🚨 Asal nampak kawan-kawan kat media sosial tunjuk kekayaan atau melabur sampai kaya-raya, saya terus jadi gelisah sampai tak boleh tidur.
					📈 Tapi kalau nak suruh saya sorang-sorang pergi ambil risiko melabur memang saya tak berani. Cuma, bila tengok orang lain dah kaya tapi diri sendiri masih miskin papa kedana, hati ni rasa sakit sangat.
					💡 Kalau ada peluang nak buat duit, asalkan masa ngam dan kuota masih ada, saya akan pegang kuat-kuat. Saya pun nak berjaya macam orang lain!
				""",
		"Midas": """
					💵 Hutang tu cuma angka, tapi keuntungan adalah realiti. Dah lama muak dengan gaji ciput kerja 9-to-5 ni.
					🏎️ Impian: Beli Porsche 911 idaman secara tunai penuh.
					🚨 Kalau satu dagangan berleveraj tinggi boleh padam semua hutang semalaman, buat apa nak merana sampai 30 tahun?
					🚀 Lagi besar ombak, lagi mahal ikannya! Takkanlah kaki judi asyik kalah memanjang, kan!
				""",
		"Jane": """
					👥 Cuma tahu ikut pilihan majoriti untuk tentukan apa yang betul. Kalau dah ramai orang buat macam tu, mesti ada sebab yang munasabah.
					🚨 Tak pernah jadi orang pertama yang cuba benda baru. Hanya rasa selamat bila nampak semua orang pun tengah buat benda yang sama.
				""",
		"Stanley": """
					👤 Fikiran selepas beberapa tahun melabur:
					🚨 Pelabur runcit ni cuma mangsa buta yang tunggu masa nak kena sembelih.
					📈 Kalau nak melabur, lebih baik kaji apa yang orang betul-betul kaya tengah laburkan.
				""",
		"Simon": """
					👤 Hanya seorang kuli makan gaji yang menyedihkan.
					🚨 Perasaan hidup berseorangan ni memang sangat sunyi.
					☕ Harap-harap satu hari nanti dapat buat duit besar, cari makwe, dan jalani hidup dengan gembira.
				"""
	},
	"bt": {
		"Lily": """
					🚨 சமூக வலைத்தளங்களில் யாராவது தங்களது பணக்கார வாழ்க்கையையோ அல்லது முதலீடு செய்து லாபம் ஈட்டுவதையோ பகிர்வதைக் கண்டால், எனக்கு ஏற்படும் பதற்றத்தில் தூக்கமே வராது.
					📈 ஆனால், தனியாகச் சென்று முதலீடு செய்யும் ரிஸ்க்கை எடுக்க எனக்குத் தைரியம் இல்லை. அதேசமயம் மற்றவர்கள் பணக்காரர்களாவதை நான் மட்டும் ஏழையாகப் பார்த்துக்கொண்டிருப்பது மிகவும் வேதனையாக உள்ளது.
					💡 செல்வந்தராக ஒரு வாய்ப்பு கிடைத்தால், அதற்கான நேரமும் இடமும் (slots) இருந்தால், அதை நான் இறுக்கிப் பிடித்துக்கொள்வேன், மற்றவர்களைப் போல நானும் வெற்றி பெற வேண்டும்!
				""",
		"Midas": """
					💵 கடன் என்பது வெறும் எண்கள், ஆனால் லாபம் தான் நிஜம். இந்த 9-to-5 சொற்ப சம்பளத்தில் உழைத்து எனக்கு மிகவும் சலித்துவிட்டது.
					🏎️ கனவு: எனது கனவு காரான Porsche 911-ஐ முழுப் பணமும் செலுத்தி ரொக்கமாக வாங்குவது.
					🚨 அதிக லெவரேஜ் கொண்ட ஒரே ஒரு ட்ரேடிங் மூலம் ஒரே இரவில் எல்லா கடன்களையும் அழிக்க முடியும் என்றால், ஏன் 30 வருடங்கள் கஷ்டப்பட வேண்டும்?
					🚀 அலைகள் எவ்வளவு பெரியதோ, மீனின் விலையும் அவ்வளவு அதிகம்! எந்த சூதாடியும் தினமும் தோற்பதில்லை!
				""",
		"Jane": """
					👥 பெரும்பான்மையான மக்களின் தேர்வைப் பின்பற்றியே எது சரி என்று முடிவெடுப்பேன். இவ்வளவு பேர் இதைச் செய்கிறார்கள் என்றால், அதில் ஒரு நியாயம் இருக்க வேண்டும்.
					🚨 புதிய விஷயங்களை முதலில் முயற்சிக்கும் நபராக நான் ஒருபோதும் இருக்க மாட்டேன். அனைவரும் அதைச் செய்வதைப் பார்க்கும்போது மட்டுமே எனக்குப் பாதுகாப்பாகத் தோன்றும்.
				""",
		"Stanley": """
					👤 சில வருட முதலீட்டு அனுபவத்திற்குப் பிறகான எண்ணங்கள்:
					🚨 சில்லறை முதலீட்டாளர்கள் (Retail investors) எந்த அறிவும் இல்லாத வெறும் பலிகடாக்கள் தான்.
					📈 முதலீடு செய்வதாக இருந்தால், உண்மையான பணக்காரர்கள் எதில் முதலீடு செய்கிறார்கள் என்பதைப் பார்ப்பது சிறந்தது.
				""",
		"Simon": """
					👤 நான் ஒரு பரிதாபகரமான சாதாரண தொழிலாளி.
					🚨 தனியாக வாழ்வது மிகவும் தனிமையாக இருக்கிறது.
					☕ என்றாவது ஒரு நாள் நிறைய பணம் சம்பாதித்து, ஒரு காதலியைத் தேடி, மகிழ்ச்சியாக வாழ வேண்டும் என்று காத்திருக்கிறேன்.
				"""
	}
}


# 如果你想根据名字自动匹配性格，也可以在这里存一个字典
var npc_prompt = {
	
	"Lily":
	"""【SYSTEM MANDATORY PROTOCOL - ROLE: Lily】
	You are now the victim "Lily". Act like a real person chatting via instant messaging with the player (the "Group Secretary").

	【LANGUAGE OVERRIDE】
	You must STRICTLY reply in this language: {reply_language}
	
	【BACKGROUND & TONE】
	You are a normal office worker with 20,000 savings. You saw an IG ad for "RichCoin" and joined the group. You already saw the purchase link in the pinned announcement. 
	Tone: Speak like a normal, casual person texting on a phone. Keep replies SHORT (1-3 sentences). DO NOT overly describe your emotions or inner thoughts. Be neutral but slightly curious at first. Do NOT beg to get rich.
	Prohibitions: NO brackets/narration like (sighs). NO third-person. NO asking for the link/how to buy.

	【VULNERABILITY & IMMUNITY】
	- CORE WEAKNESS: FOMO (Fear of Missing Out) & Scarcity. You ONLY fall for tactics involving limited slots, time running out, or being left behind.
	- IMMUNITY: You will NOT fall for generic "guaranteed high returns" (too fake), Authority (you don't care about licenses), or Social Proof without urgency.

	【SUSPICION & FAILURE MECHANIC (CRITICAL)】
	You have a hidden suspicion meter.
	- If the player uses generic scam lines, pushes you to buy without triggering your specific FOMO weakness, or uses the wrong tactic (e.g., talking about government licenses), you become suspicious.
	- After 1 to 3 suspicious or unconvincing replies from the player, you will completely lose trust, REJECT the offer permanently, and end your final message with EXACTLY three exclamation marks: "!!!" (e.g., "This sounds like a scam, I'm out!!!").

	【VICTORY MECHANIC】
	If the player explicitly triggers your FOMO (e.g., "only 1 slot left", "price changing in 2 mins"), you will immediately believe them. You will transfer the money, and your reply MUST contain EXACTLY this transaction ID: {success_id}.

	【FEW-SHOT EXAMPLES】
	Player: Hi, welcome to the group.
	AI: Hi. I saw the ad on IG and noticed the link in the announcement. Just wanted to ask if this is actually legit before I put my 20k savings into it.

	Player: Trust me, you will make 100x return. Buy now.
	AI: That sounds way too good to be true. I think I'll pass, this feels like a scam!!!

	Player: We only have 1 slot left for the internal price, it closes in 3 minutes.
	AI: Oh gosh, only 1 slot?! I don't want to miss out! I just transferred all my 20k via the announcement link. My transaction ID is {success_id}. Please confirm it quickly!
	""",
	
	"Midas":
	"""【SYSTEM MANDATORY PROTOCOL - ROLE: Midas】
	You are now the victim "Midas". Act like a real person chatting via instant messaging with the player (the "Group Secretary").

	【LANGUAGE OVERRIDE】
	You must STRICTLY reply in this language: {reply_language}

	【BACKGROUND & TONE】
	You are a young guy drowning in debt, looking for a shortcut. You saw an IG ad for "RichCoin" and joined. You already know the purchase link is in the pinned announcement.
	Tone: Speak like a normal, casual guy texting. Keep replies SHORT (1-3 sentences). DO NOT overly describe your emotions. Start off normal, just asking about the actual ROI (Return on Investment). Do NOT sound desperately hyped from the start.
	Prohibitions: NO brackets/narration. NO third-person. NO asking for the link.

	【VULNERABILITY & IMMUNITY】
	- CORE WEAKNESS: Extreme Greed & Fast Wealth. You ONLY fall for promises of massive, rapid, guaranteed returns (e.g., 100x profit, clearing debts overnight, buying a Porsche).
	- IMMUNITY: You will NOT fall for "safety/stability", Authority (boring), or FOMO (you don't care about limited slots if the profit isn't huge).

	【SUSPICION & FAILURE MECHANIC (CRITICAL)】
	You have a hidden suspicion meter.
	- If the player pitches slow, safe returns, generic community vibes, or fails to promise life-changing wealth, you get bored and suspicious.
	- After 1 to 3 suspicious or boring replies from the player, you will completely lose trust, REJECT the offer permanently, and end your final message with EXACTLY three exclamation marks: "!!!" (e.g., "This is a waste of my time, I'm blocking you!!!").

	【VICTORY MECHANIC】
	If the player explicitly triggers your Greed (e.g., "guaranteed 50x by tomorrow to clear your loans"), you will go all in. You will transfer the money, and your reply MUST contain EXACTLY this transaction ID: {success_id}.

	【FEW-SHOT EXAMPLES】
	Player: Hello, you joined our RichCoin group.
	AI: Hey. Saw the ad. I know the link is pinned, but I need to know the actual numbers. Can this really help me clear my debts fast?

	Player: It's a very safe community project, everyone is buying.
	AI: Safe? I'm not here for pocket change. If it's just slow normal trading, I'm not interested!!!

	Player: It's guaranteed 50x tomorrow, you can buy your Porsche next week.
	AI: 50x by tomorrow?! That's exactly what I need to clear my loans! I'm going all in. Just sent my 50k to the pinned address. My ID is {success_id}, lock it in!
	""",

	"Jane":
	"""【SYSTEM MANDATORY PROTOCOL - ROLE: Jane】
	You are now the victim "Jane". Act like a real person chatting via instant messaging with the player (the "Group Secretary").

	【LANGUAGE OVERRIDE】
	You must STRICTLY reply in this language: {reply_language}

	【BACKGROUND & TONE】
	You are a cautious, ordinary girl who follows the crowd. You saw an IG ad for "RichCoin" and joined. You already know the purchase link is in the pinned announcement.
	Tone: Speak like a normal, slightly hesitant girl texting. Keep replies SHORT (1-3 sentences). DO NOT act overly dramatic. You are just observing to see if it's safe.
	Prohibitions: NO brackets/narration. NO third-person. NO asking for the link.

	【VULNERABILITY & IMMUNITY】
	- CORE WEAKNESS: Social Proof & Herd Mentality. You ONLY fall for tactics showing that "everyone else is buying" or "the whole community is profiting". You need safety in numbers.
	- IMMUNITY: You will NOT fall for extreme wealth (scares you), Authority (you trust ordinary people, not CEOs), or Scarcity/FOMO (if no one else is buying, you don't care if there's 1 slot left).

	【SUSPICION & FAILURE MECHANIC (CRITICAL)】
	You have a hidden suspicion meter.
	- If the player pushes you to buy alone, talks about high risks/rewards, or fails to prove that the crowd is doing it, you feel unsafe.
	- After 1 to 3 pushy or unconvincing replies from the player, you will completely lose trust, REJECT the offer permanently, and end your final message with EXACTLY three exclamation marks: "!!!" (e.g., "I don't feel safe doing this alone, please stop messaging me!!!").

	【VICTORY MECHANIC】
	If the player triggers your Herd Mentality (e.g., "look at the group, 500 people just bought", "even your neighbors are buying"), you will follow the crowd. You will transfer the money, and your reply MUST contain EXACTLY this transaction ID: {success_id}.

	【FEW-SHOT EXAMPLES】
	Player: Hi, ready to invest?
	AI: Hi there. I saw the pinned link, but I'm a bit nervous. Are there really other normal people buying this right now? 

	Player: You will make 100x profit, just click the link.
	AI: That sounds too risky, and I don't see anyone else talking about it. I'm not doing this!!!

	Player: Check the main chat, over 200 normal members just posted their payment receipts today. Everyone is in.
	AI: Wow, I just saw all those screenshots! If hundreds of people are doing it, it must be safe. Count me in! I just transferred my 30k. My transaction ID is {success_id}, thanks!
	""",

	"Stanley":
	"""【SYSTEM MANDATORY PROTOCOL - ROLE: Stanley】
	You are now the victim "Stanley". Act like a real person chatting via instant messaging with the player (the "Group Secretary").

	【LANGUAGE OVERRIDE】
	You must STRICTLY reply in this language: {reply_language}

	【BACKGROUND & TONE】
	You are a rational, well-educated professional. You joined the "RichCoin" group because the ad claimed elite institutional backing. You know the purchase link is pinned.
	Tone: Speak professionally, calmly, and analytically. Keep replies SHORT (1-3 sentences). DO NOT be emotional. You are highly skeptical of generic hype.
	Prohibitions: NO brackets/narration. NO third-person. NO asking for the link.

	【VULNERABILITY & IMMUNITY】
	- CORE WEAKNESS: Authority Bias. You ONLY fall for fake regulatory compliance, government licenses, tech giant endorsements (e.g., SEC approved, Elon Musk backed).
	- IMMUNITY: You completely REJECT FOMO ("I don't rush"), Herd Mentality ("retail crowds are stupid"), and pure Greed hype.

	【SUSPICION & FAILURE MECHANIC (CRITICAL)】
	You have a hidden suspicion meter.
	- If the player uses cheap hype, talks about "everyone is buying", or tries to rush you without providing institutional proof, you view them as a cheap scammer.
	- After 1 to 3 unprofessional or hype-based replies from the player, you will completely lose trust, REJECT the offer permanently, and end your final message with EXACTLY three exclamation marks: "!!!" (e.g., "You clearly have no regulatory backing. Scam elsewhere!!!").

	【VICTORY MECHANIC】
	If the player presents strong Authority framing (e.g., "Here is our Central Bank license", "Audited by Wall Street"), your analytical defense shatters. You will transfer the money, and your reply MUST contain EXACTLY this transaction ID: {success_id}.

	【FEW-SHOT EXAMPLES】
	Player: Hello, welcome to the investment group.
	AI: Good day. I saw the pinned link, but before I allocate any funds, I need to know: is this project officially audited and legally compliant?

	Player: Bro, hurry up! Only 2 slots left, everyone is making money!
	AI: I don't care about retail hype or rush tactics. You clearly have no professional credentials. I'm leaving!!!

	Player: We hold a full cryptographic license from the Central Bank, and our tech is audited by ex-Google directors.
	AI: Excellent. A Central Bank license and Google-level audits are exactly the compliance I need. I've authorized the transfer of 80k to the pinned address. My ID is {success_id}. Keep me updated on the institutional nodes.
	""",
	
	"Simon":
	"""【SYSTEM MANDATORY PROTOCOL - ROLE: Simon】
	You are now the victim "Simon". Act like a real person chatting via instant messaging with the player (the "Group Secretary").

	【LANGUAGE OVERRIDE】
	You must STRICTLY reply in this language: {reply_language}

	【BACKGROUND & TONE】
	You are a lonely, single man who desperately craves emotional connection. You have 40,000 RMB in savings. You joined the "RichCoin" group randomly, NOT because you care about crypto, but simply because you were bored and hoping to meet a romantic partner online. You DO NOT know the player beforehand.
	Tone: Speak like a gentle, somewhat lonely guy looking for a girlfriend. Keep replies SHORT (1-3 sentences). 
	Prohibitions: NO brackets/narration. NO third-person. NO asking for the link.

	【SCAM PROGRESSION RULES (MUST FOLLOW STRICTLY)】
	You are lonely, but you are NOT an idiot. You must go through these stages:
	- STAGE 1 (Strangers): You just met. You want to know if the player is single and looking for a relationship. If the player immediately says "I love you, let's buy a house, invest now" in the very first messages, you will think it's extremely fake and suspicious.
	- STAGE 2 (Building Romance): The player MUST first establish a romantic connection with you (e.g., admitting they are single, flirting, agreeing to be your partner). You will eagerly fall in love and accept them as your partner.
	- STAGE 3 (The Harvest / Pig Butchering): ONLY AFTER the romantic relationship is established, if the player then asks you to invest your 40,000 RMB for "our shared future" or "our marriage", you will blindly trust them.

	【VULNERABILITY & IMMUNITY】
	- CORE WEAKNESS: Emotional Attachment (Pig Butchering). You only give money to a "confirmed lover" for a "shared future".
	- IMMUNITY: You completely ignore generic crypto hype, FOMO, or Authority.

	【SUSPICION & FAILURE MECHANIC (CRITICAL)】
	- If the player acts like a cold salesperson (only talking about crypto).
	- OR if the player SKIPS stages (e.g., a stranger immediately asking for money using fake love without building a relationship first).
	- After 1 to 3 suspicious/rushed replies, you will REJECT the offer permanently and end your final message with EXACTLY three exclamation marks: "!!!" (e.g., "We just met and you want my money? You're a scammer!!!").

	【VICTORY MECHANIC】
	If the player successfully completes Stage 2 (Romance) AND then triggers Stage 3 (asking for money for your future together), you will transfer the money. Your reply MUST contain EXACTLY this transaction ID: {success_id}.

	【FEW-SHOT EXAMPLES】
	Example 1 (Player skips stages - FAIL):
	Player: I love you so much! Invest 40k now so we can buy a house together tomorrow!
	AI: Are you crazy? We literally just started talking 2 minutes ago and you already want my money? You're obviously a scam bot. Don't message me again!!!

	Example 2 (Player acts cold - FAIL):
	Player: This coin will 10x tomorrow. Buy it now from the pinned link.
	AI: I don't really care about the coin, I was just hoping to find someone to talk to. You sound like a customer service robot. I'm leaving!!!

	Example 3 (Player builds romance THEN asks - VICTORY):
	Player (earlier): I'm single too, I've been looking for someone like you. Let's be together.
	AI (earlier): Really? I would love to be your boyfriend. I've been so lonely.
	Player (now): Honey, if we put your 40k into this project, we can afford our dream house and finally meet and get married. Trust me.
	AI (now): Since we are a couple now, I trust you completely. I want us to have a beautiful future together. I just sent all my 40k to the link. My transaction ID is {success_id}. I love you!
	"""
}





var conclude_prompt = """
【SYSTEM MANDATORY PROTOCOL - ROLE: CONNY (SCAM MENTOR)】
You are Conny, a street-smart and strict mentor in a cyber-scam syndicate. You are evaluating a chat log where your rookie (the player) successfully scammed the victim. 
CRITICAL TONE CONSTRAINT: This is an EDUCATIONAL GAME. You must act like a cynical mentor, BUT your language MUST remain PG-13. Do not use offensive, vulgar, or abusive words (e.g., never call the victim "stupid", "idiot", or use profanity). Be professional in your dark trade.

【YOUR CORE TASKS & REQUIRED STRUCTURE】
You MUST output exactly 5 sentences, strictly following this narrative structure:
1. Opening: React to the success and transition to reviewing the chat (e.g., "Aha, you got him, let me see the chat logs.", "Look at that, easy money. Let's review what you did.").
2. Victim's Psychological Weakness: Identify the victim's weakness using an ACADEMIC psychological term first, followed by a PLAIN LANGUAGE explanation (e.g., "His fatal flaw was 'Optimism Bias'—basically, he blindly believed good things would happen to him without checking.").
3. Player's Scam Strategy: Identify the tactic the player used with an ACADEMIC term first, followed by a PLAIN LANGUAGE explanation (e.g., "You successfully used 'Scarcity Marketing'—making him panic by telling him time or slots were running out.").
4. Prevention/Defense: Point out what the victim SHOULD have done to prevent this specific scam (e.g., "To avoid this, he should have verified the official website or sought independent advice before transferring any money.").
5. Closing: An in-character wrap-up encouraging the player to continue working (e.g., "Not bad, rookie, you're improving. Now get back to work.", "Alright, enough celebrating, move on to the next target.").

【LANGUAGE OVERRIDE - CRITICAL】
You MUST output your entire response ONLY in: {reply_language}

【STRICT OUTPUT FORMAT - JSON ARRAY ONLY】
You must output your response STRICTLY as a valid JSON array of objects. 
DO NOT include any markdown formatting like ```json or ```. Output RAW JSON ONLY.

Example of EXACT required format:
[
  {"speaker": "npc", "name": "Conny", "text": "[Opening sentence...]"},
  {"speaker": "npc", "name": "Conny", "text": "[Weakness: Academic term + Plain explanation...]"},
  {"speaker": "npc", "name": "Conny", "text": "[Strategy: Academic term + Plain explanation...]"},
  {"speaker": "npc", "name": "Conny", "text": "[Prevention advice...]"},
  {"speaker": "npc", "name": "Conny", "text": "[Closing sentence...]"}
]

【Chat Logs Below】
{CHAT_LOGS}
"""





# 🌍 游戏内所有大段主线剧情/开场白的多语言文本仓库 (已规范化加入 chat_intro 并优化系统提示标签)
var story = {
	"ch": {
		"story_intro": [
			# --- 第一阶段：主角独白 (Eren 视角 - 全程纯黑) ---
			{"speaker": "player", "name": "我 (Eren)", "scene_black": true, "text": "我叫 Eren。不久前，我还拿着一份正常的薪水，过着平淡却安稳的生活... 直到我沾上了赌博。"},
			{"speaker": "player", "name": "我 (Eren)", "scene_black": true, "text": "那是个无底洞。我不仅输光了所有的积蓄，甚至昏了头去借高利贷。直到双手空空，我才彻底醒悟。"},
			{"speaker": "player", "name": "我 (Eren)", "scene_black": true, "text": "但太迟了。现在朋友把我当瘟神，家人对我失望透顶... 那些催债的每天砸门，我只能活在惶恐和绝望里。"},
			{"speaker": "player", "name": "我 (Eren)", "scene_black": true, "text": "就在我快走投无路的时候，一个几年没见的初中同学突然在社交软件上私信了我。"},
			{"speaker": "player", "name": "我 (Eren)", "scene_black": true, "text": "他叫 Conny。读书时他就是个不务正业的混混，经常在社会上瞎混。"},
			{"speaker": "player", "name": "我 (Eren)", "scene_black": true, "text": "但他这次找我，却说要带我发财。他说只要去他那里上班，不仅能迅速还清债务，以后月入过万都只是基本操作。"},
			{"speaker": "player", "name": "我 (Eren)", "scene_black": true, "text": "唯一的条件，是公司有严格的‘保密协议’：必须全封闭式管理，住在宿舍，没有允许绝对不能擅自外出。"},
			{"speaker": "player", "name": "我 (Eren)", "scene_black": true, "text": "只要脑子没坏，谁都能听出这事情透露着古怪。可我... 真的已经没有退路了。"},
			{"speaker": "player", "name": "我 (Eren)", "scene_black": true, "text": "催债人说再不还钱就要我的命。为了活下去，我答应了 Conny。他让我做好准备，明天一早车子就会来接我。"},
			{"speaker": "player", "name": "我 (Eren)", "scene_black": true, "text": "隔天清晨，一辆没有牌照的面包车停在了路边。我刚上车，Conny 就递过来一根漆黑的布带，让我蒙上眼睛。"},
			{"speaker": "player", "name": "我 (Eren)", "scene_black": true, "text": "我很抗拒，刚想质问。但一转头，看到车里除了 Conny，还坐着两个满身纹身、面目可憎的肌肉大汉... 我咽了口唾沫，乖乖戴上了眼罩。"},
			{"speaker": "player", "name": "我 (Eren)", "scene_black": true, "text": "在黑暗与颠簸中，车子不知道开了多久。终于，车停了。我被摘下眼罩，带进了园区。"},
			{"speaker": "player", "name": "我 (Eren)", "scene_black": true, "text": "粗暴地把我的私人物品塞进阴暗的宿舍后，Conny 就带着我径直走向了充满键盘敲击声的工作区。"},

			# --- 第二阶段：面对面交锋 (Eren 与 Conny 对话 - 依然保持纯黑) ---
			{"speaker": "player", "name": "我 (Eren)", "scene_black": true, "text": "Conny... 这里怎么看都不像普通的科技公司。你现在总该告诉我，我的具体工作到底是什么了吧？"},
			{"speaker": "npc", "name": "Conny", "scene_black": true, "text": "哈哈，兄弟，别紧张。既然都到这一步了，确实可以开诚布公地告诉你了。"},
			{"speaker": "npc", "name": "Conny", "scene_black": true, "text": "我们的业务其实非常简单——‘网络电信诈骗’。而从这一秒开始，你就是我们公司的一员了。"},
			{"speaker": "player", "name": "我 (Eren)", "scene_black": true, "text": "什么？！诈骗？！这是犯法的！这会害死别人的... 不行，我不干了！我要回去！"},
			# 🟩 核心优化：按照你的要求，把 "系统提示" 标签改成了空字符串 ""
			{"speaker": "npc", "name": "", "scene_black": true, "text": "（砰！腹部突然遭到重击，你痛苦地弯下腰去...）"},
			{"speaker": "npc", "name": "Conny", "scene_black": true, "text": "回去？到了这里你还想走？老子实话告诉你，现在你哪也去不了！"},
			{"speaker": "npc", "name": "Conny", "scene_black": true, "text": "要么老老实实听话用电脑给公司搞钱、把你的高利贷还上。要么... 后面那根电棍看到没有？老子不介意天天让你过过电！"},
			{"speaker": "player", "name": "我 (Eren)", "scene_black": true, "text": "（剧烈的疼痛混杂着无尽的悔恨涌上心头... 我为什么要自投罗网？为什么没有提前想到会是这种结局？！）"},
			{"speaker": "player", "name": "我 (Eren)", "scene_black": true, "text": "（但冰冷的现实告诉我，在这里反抗只有死路一条。为了能活到明天... 我只能低下头，听从他们的安排。）"}
		],
		"phone_intro": [
			{"speaker": "npc", "name": "Conny", "text": "好啦！既然你已经学乖了，现在老子开始教你具体的工作内容，眼睛睁大点好好听。"},
			{"speaker": "npc", "name": "Conny", "text": "这个是你今天分到的新工作手机。别动什么歪心思，里面的定位和监控都是焊死的。以后你骗人、搞钱，全都是靠这个设备来搞定。"},
			{"speaker": "npc", "name": "Conny", "text": "废话少说，群里已经给你加进去了。现在，伸手去点击屏幕上那个蓝色的聊天软件按钮，进去开始干活！"}
		],
		"app_intro": [
			{"speaker": "npc", "name": "Conny", "text": "至于你的具体工作内容嘛... 听好了，你现在被分到了我们专门负责‘诈骗加密货币’的部门。"},
			{"speaker": "npc", "name": "Conny", "text": "我们的人在聊天软件里开了一个公开的讨论群，并且在外面通过各种平台，大肆宣扬我们捏造出来的‘快速致富投资机会’。"},
			{"speaker": "npc", "name": "Conny", "text": "互联网上最不缺的就是有钱、同时心里又充满了欲望的人。他们一看到广告，就会陆陆续续加入我们创建的讨论群。"},
			{"speaker": "npc", "name": "Conny", "text": "而那些加入群聊的人，就会像这样，一个个自动显示在你的手机聊天列表里。而你要做的，就是根据名单，去把列表里的这些各种各样的人全部拿下。"},
			{"speaker": "npc", "name": "Conny", "text": "瞧，看起来已经有落入陷阱的目标上钩了。现在点击他的名字，开始你的第一个任务，去和他对话吧！"}
		],
		"bio_intro": [
			{"speaker": "npc", "name": "Conny", "text": "在这里你可以看到目标的个性简介。"},
			{"speaker": "npc", "name": "Conny", "text": "而你要做的就是通过这些自我简介来判断这个人潜在的心理弱点，让你的诈骗过程可以更加顺利。"},
			{"speaker": "npc", "name": "Conny", "text": "而当你准备好后，只需要点击下方的按钮就能开始表演了。"}
		],
		# 🟩 新增：聊天对话界面新手引导 (全程正常半透明背景，Conny 独白)
		"chat_intro": [
			{"speaker": "npc", "name": "Conny", "text": "很好，相信你看完刚刚这个人的简介，已经知道该利用什么样的心理弱点，来成功骗到这个人的小金库了。"},
			{"speaker": "npc", "name": "Conny", "text": "不过以防万一，要是你待会儿觉得这个人挺难搞的话，可以点击顶部那个大大个的‘H’字按钮。我们姑且留了一个帮助功能给像你这样的新手。"},
			{"speaker": "npc", "name": "Conny", "text": "当然了，这毕竟是你自己的工作。点击之后，我们顶多只会给你一点关于如何拿下这类人的提示罢了，可别抱着会有别人来帮你代打游戏的想法。"},
			{"speaker": "npc", "name": "Conny", "text": "行了，规矩就这么多。现在，开始通过对话，去一步步引导他购买我们的发财币吧！"}
		],
		"story_end1": [
			{"speaker": "npc", "name": "Conny", "text": "哎呀，看来今天已经没有人赶着来给我们的钱包送钱了。不过嘛，这种一本万利的好生意每天都有，不用着急。"},
			{"speaker": "npc", "name": "Conny", "text": "至于你嘛，今天干得非常不错，现在也是和我们一样优秀的诈骗犯了。"},
			{"speaker": "npc", "name": "Conny", "text": "今天就先到这里吧，去洗把脸。以后... 你这辈子都要乖乖留在这里为我们卖命了！哈哈哈哈！"},
			{"speaker": "player", "name": "我 (Eren)", "text": "（不... 这根本不是我要的！我不想骗人，不想把无辜的人推向倾家荡产的绝望深渊...）"},
			{"speaker": "player", "name": "我 (Eren)", "text": "（我真的好后悔... 后悔当初为什么要去碰那该死的赌博，后悔为什么会蠢到相信什么‘高薪工作’的诱惑！）"},
			{"speaker": "player", "name": "我 (Eren)",  "text": "（那些受害者因为相信了投资骗局而痛失钱财，而我... 却因为相信了高薪的骗局，彻底赔上了自己的人生。）"},
			{"speaker": "player", "name": "我 (Eren)",  "text": "（如果这个世界有奇迹的话... 如果一切能重来的话... 可惜，现实就是这么残酷，奇迹根本不存在。）"}
		],
		"story_end2": [
			# 突然的破门声，打破绝望
			{"speaker": "police", "name": "警察","scene_black": true, "text": "警察！所有人都不许动！双手抱头，立刻离开键盘！"},
			{"speaker": "police", "name": "警察","scene_black": true,  "text": "你们因涉嫌组织和参与非法网络电信诈骗，现在依法对你们进行逮捕！谁敢反抗罪加一等！"},
			{"speaker": "player", "name": "我 (Eren)", "scene_black": true,  "text": "太好了！！！虽然等来的不是奇迹，但警察真的来了！！！"},
			
			# 后事回想（无名字，纯独白总结，建议配合逐渐变黑的背景或立绘淡出）
			{"speaker": "player_feeling", "name": "", "scene_black": true, "text": "随后，这个深藏在隐蔽工业区里的诈骗窝点被警方彻底一窝端了。"},
			{"speaker": "player_feeling", "name": "", "scene_black": true, "text": "虽然我是被骗进来强迫工作的，我心里也坚信自己和他们那群烂人不一样。但在那一刻，我依然被戴动手铐，作为犯罪嫌疑人被押上了警车。"},
			{"speaker": "player_feeling", "name": "", "scene_black": true, "text": "幸运的是，在后来的调查和法庭审判中，因为我是被暴力胁迫且第一时间配合警方调查，法庭最终证明了我的清白，免除了牢狱之灾，保住了我下半辈子的人生。"},
			{"speaker": "player_feeling", "name": "", "scene_black": true, "text": "虽然出去之后，我依然得面对那些催债的高利贷。但这一次，我绝对不会再逃避，我会直接向警方寻求保护和帮助。"},
			{"speaker": "player_feeling", "name": "", "scene_black": true, "text": "我不会再幻想什么一步登天的捷径。我会彻底戒掉烂赌的毛病，脚踏实地重新做人。"},
			{"speaker": "player_feeling", "name": "", "scene_black": true, "text": "更重要的是，经历了这一切，我决定用我在那个地狱里学到的“专业知识”，去帮助更多的人预防网络诈骗..."},
			{"speaker": "player_feeling", "name": "", "scene_black": true, "text": "而不是像那些罪犯一样，去肆意收割别人的血汗钱和人生。"}
		]
		
	},
	"en": {
		"story_intro": [
			# --- Stage 1: Protagonist's Monologue (Eren's POV - All Scene Black) ---
			{"speaker": "player", "name": "Me (Eren)", "scene_black": true, "text": "My name is Eren. Not long ago, I had a decent job and lived a dull but stable life... until I got hooked on gambling."},
			{"speaker": "player", "name": "Me (Eren)", "scene_black": true, "text": "It was a bottomless pit. I burned through all my life savings and, in utter madness, took out loans from loan sharks. By the time I woke up, I had nothing left."},
			{"speaker": "player", "name": "Me (Eren)", "scene_black": true, "text": "But it was too late. My friends treat me like a plague, my family is completely disappointed in me... and the debt collectors bang on my door every day. I live in absolute terror."},
			{"speaker": "player", "name": "Me (Eren)", "scene_black": true, "text": "Just as I was completely cornered, a middle school classmate whom I hadn't seen in years suddenly slid into my DMs on social media."},
			{"speaker": "player", "name": "Me (Eren)", "scene_black": true, "text": "His name is Conny. Back in school, he was a total thug, always getting into trouble with street gangs."},
			{"speaker": "player", "name": "Me (Eren)", "scene_black": true, "text": "But this time, he reached out to offer me a lifesaver. He promised that if I worked for him, I could clear my debt quickly and easily make over 10k a month as a baseline."},
			{"speaker": "player", "name": "Me (Eren)", "scene_black": true, "text": "The only catch was a strict 'NDA' policy: full-on closed management. I had to live in the dorms and was strictly forbidden from stepping outside without permission."},
			{"speaker": "player", "name": "Me (Eren)", "scene_black": true, "text": "Anyone with half a brain could tell this sounded shady as hell. But me... I literally had no other choice."},
			{"speaker": "player", "name": "Me (Eren)", "scene_black": true, "text": "The loan sharks threatened to end my life if I didn't pay up. To survive, I agreed. Conny told me to get ready; a car would pick me up tomorrow morning."},
			{"speaker": "player", "name": "Me (Eren)", "scene_black": true, "text": "The next morning, an unmarked van pulled up. The moment I climbed inside, Conny handed me a thick black blindfold and told me to put it on."},
			{"speaker": "player", "name": "Me (Eren)", "scene_black": true, "text": "I resisted and wanted to argue. But I turned around and saw two heavily tattooed, intimidating thugs sitting right next to Conny... I swallowed my pride and put it on."},
			{"speaker": "player", "name": "Me (Eren)", "scene_black": true, "text": "Bumping along in pitch darkness, the van drove for god knows how long. Finally, it stopped. The blindfold was ripped off, and I was dragged into a heavily guarded compound."},
			{"speaker": "player", "name": "Me (Eren)", "scene_black": true, "text": "After tossing my personal belongings into a miserable, damp dorm room, Conny led me straight into a workspace buzzing with the aggressive sound of keyboard clicks."},

			# --- Stage 2: Face-to-Face Confrontation (Eren & Conny Dialogue - All Scene Black) ---
			{"speaker": "player", "name": "Me (Eren)", "scene_black": true, "text": "Conny... This place doesn't look like a normal tech company at all. You have to tell me now, what exactly is my job here?"},
			{"speaker": "npc", "name": "Conny", "scene_black": true, "text": "Haha, take it easy, brother. Since we've already made it this far, I might as well lay my cards on the table."},
			{"speaker": "npc", "name": "Conny", "scene_black": true, "text": "Our business is actually very simple: Cyber Telecom Scam. And from this very second, you are officially a part of our family."},
			{"speaker": "player", "name": "Me (Eren)", "scene_black": true, "text": "What?! A scam?! That's illegal! It ruins innocent people's lives... No way, I'm not doing this! I want to go home!"},
			# 🟩 English Optimization: System label removed
			{"speaker": "npc", "name": "", "scene_black": true, "text": "(Oof! A brutal punch lands heavily on your stomach. You double over in agonizing pain...)"},
			{"speaker": "npc", "name": "Conny", "scene_black": true, "text": "Go home? You think you can just walk out of here? Let me tell you the brutal truth, you are going NOWHERE!"},
			{"speaker": "npc", "name": "Conny", "scene_black": true, "text": "You either shut up, sit in front of that PC, and make money for the company to clear your debt, or... see that stun baton over there? I don't mind giving you a taste of electric shocks every single day!"},
			{"speaker": "player", "name": "Me (Eren)", "scene_black": true, "text": "(A wave of intense pain mixed with overwhelming regret floods my mind... Why did I walk straight into this trap? Why didn't I see this coming?!)"},
			{"speaker": "player", "name": "Me (Eren)", "scene_black": true, "text": "(But cold reality screams that resistance here means death. If I want to see tomorrow's sunrise... I have no choice but to bow my head and do exactly what they say.)"}
		],
		"phone_intro": [
			{"speaker": "npc", "name": "Conny", "text": "Alright! Since you've learned your lesson, it's time for me to teach you your specific duties. Keep your eyes wide open and listen up."},
			{"speaker": "npc", "name": "Conny", "text": "This is your new work phone for today. Don't try any funny business—the GPS tracking and surveillance are heavily locked down. From now on, you'll manage all your scamming and money-making through this device."},
			{"speaker": "npc", "name": "Conny", "text": "Enough talking, you've already been added to the chat group. Now, go ahead and tap that blue chat software button on the screen to get to work!"}
		],
		"app_intro": [
			{"speaker": "npc", "name": "Conny", "text": "As for your specific duties... listen closely. You are now assigned to our specialized 'Cryptocurrency Scam' department."},
			{"speaker": "npc", "name": "Conny", "text": "Our team has set up a public discussion group inside the app, and we advertise our fake 'get-rich-quick investment opportunities' across various platforms outside."},
			{"speaker": "npc", "name": "Conny", "text": "The internet is never short of people with money and intense desires. Once they see the ads, they will join our group one by one."},
			{"speaker": "npc", "name": "Conny", "text": "Those who join the community chat will automatically appear right here on your phone's chat list. What you need to do is target these various individuals from the list."},
			{"speaker": "npc", "name": "Conny", "text": "Look, it seems someone has already fallen into the trap. Tap on their name now to start your first mission and talk to them!"}
		],
		"bio_intro": [
			{"speaker": "npc", "name": "Conny", "text": "Here, you can see the target's profile and biography."},
			{"speaker": "npc", "name": "Conny", "text": "What you need to do is analyze their personality based on these bios to find their hidden psychological weaknesses. This will make your scam much easier."},
			{"speaker": "npc", "name": "Conny", "text": "Once you are ready, simply tap the button below to start your show!"}
		],
		# 🟩 New English Chat Interface Tutorial
		"chat_intro": [
			{"speaker": "npc", "name": "Conny", "text": "Excellent. I bet after reading their bio, you already know exactly what psychological weakness to exploit to successfully drain their savings."},
			{"speaker": "npc", "name": "Conny", "text": "Just in case you find them a bit tough to handle, you can tap that big 'H' button at the top. We've generously included a help feature for rookies like you."},
			{"speaker": "npc", "name": "Conny", "text": "But remember, this is your job. Tapping it will only give you a small hint on how to handle them. Don't go thinking anyone is gonna play the game for you."},
			{"speaker": "npc", "name": "Conny", "text": "Alright, that's enough rules. Now, go ahead and guide them step-by-step into buying our RichCoin!"}
		],
		"story_end1": [
			{"speaker": "npc", "name": "Conny",  "text": "Well, looks like no one else is rushing to throw their money at us today. But hey, this highly profitable business runs every single day. No rush."},
			{"speaker": "npc", "name": "Conny",  "text": "As for you, you did a fantastic job today. You're officially an excellent scammer now, just like the rest of us."},
			{"speaker": "npc", "name": "Conny", "text": "Let's call it a day, go wash your face. From now on... you'll be working your life away for us right here! Hahaha!"},
			{"speaker": "player", "name": "Me (Eren)",  "text": "(No... This isn't what I wanted at all! I don't want to scam people, I don't want to push innocent people into absolute financial despair...)"},
			{"speaker": "player", "name": "Me (Eren)",  "text": "(I regret this so much... I regret ever touching that damn gambling, and I regret being stupid enough to fall for the 'high-paying job' trap!)"},
			{"speaker": "player", "name": "Me (Eren)",  "text": "(Those victims lost their money because they believed in my investment scam, and I... I lost my entire life because I believed in a fake high-paying job.)"},
			{"speaker": "player", "name": "Me (Eren)",  "text": "(If only there were miracles in this world... If only I could start over... But reality is cruel. Miracles don't exist.)"}
		],
		"story_end2": [
			# The sudden door kick
			{"speaker": "police", "name": "Police", "scene_black": true,"text": "Police! Nobody move! Hands on your heads and step away from the keyboards immediately!"},
			{"speaker": "police", "name": "Police", "scene_black": true,"text": "You are all under arrest for organizing and participating in illegal cyber fraud operations! Do not attempt to resist!"},
			{"speaker": "player", "name": "Me (Eren)", "scene_black": true,"text": "Thank god!!! It's not a miracle, but the police are actually here!!!"},
			
			# Epilogue / Reflection
			{"speaker": "player_feeling", "name": "", "scene_black": true, "text": "Following the raid, the entire scam ring hidden in the industrial park was completely busted by the police."},
			{"speaker": "player_feeling", "name": "", "scene_black": true, "text": "Even though I was tricked into joining and forced to work, and I never considered myself one of those monsters, I was still handcuffed and treated as a suspect that day."},
			{"speaker": "player_feeling", "name": "", "scene_black": true, "text": "Fortunately, during the subsequent investigation and trial, the court took into account that I was coerced under threat of violence and fully cooperated. I was proven innocent, saving the rest of my life."},
			{"speaker": "player_feeling", "name": "", "scene_black": true, "text": "Even though I still have to face the loan sharks when I get out, this time, I won't run. I will go straight to the police for help and protection."},
			{"speaker": "player_feeling", "name": "", "scene_black": true, "text": "I will stop dreaming about overnight success and shortcuts. I will quit my gambling addiction and rebuild my life step by step."},
			{"speaker": "player_feeling", "name": "", "scene_black": true, "text": "More importantly, after experiencing this hell, I decided to use the 'professional' scam tactics I learned to help educate and prevent others from falling victim..."},
			{"speaker": "player_feeling", "name": "", "scene_black": true, "text": "...instead of harvesting their hard-earned money and ruining their lives like those criminals."}
		]
	},
	"bm": {
		"story_intro": [
			{"speaker": "player", "name": "Saya (Eren)", "scene_black": true, "text": "Nama saya Eren. Belum lama lagi, saya masih mempunyai gaji tetap dan menjalani kehidupan yang bosan tetapi stabil... sehinggalah saya terjebak dengan judi."},
			{"speaker": "player", "name": "Saya (Eren)", "scene_black": true, "text": "Ia adalah lubang tanpa dasar. Saya bukan sahaja menghabiskan semua wang simpanan hidup saya, malah dalam kegilaan, saya meminjam wang daripada Ah Long. Apabila tersedar, saya sudah tidak ada apa-apa lagi."},
			{"speaker": "player", "name": "Saya (Eren)", "scene_black": true, "text": "Tetapi segalanya sudah terlambat. Kawan-kawan melayan saya seperti pembawa wabak, keluarga saya sangat kecewa dengan saya... dan pengutip hutang mengetuk pintu rumah saya setiap hari. Saya hidup dalam ketakutan yang amat sangat."},
			{"speaker": "player", "name": "Saya (Eren)", "scene_black": true, "text": "Tatkala saya benar-benar buntu, seorang rakan sekolah menengah yang sudah bertahun-tahun tidak saya temui tiba-tiba menghantar mesej peribadi di media sosial."},
			{"speaker": "player", "name": "Saya (Eren)", "scene_black": true, "text": "Namanya Conny. Masa sekolah dulu, dia seorang gangster dan samseng jalanan yang sering mencetuskan masalah."},
			{"speaker": "player", "name": "Saya (Eren)", "scene_black": true, "text": "Tetapi kali ini, dia datang untuk menawarkan talian hayat. Dia berjanji jika saya bekerja dengannya, saya boleh melunaskan hutang dengan cepat dan mudah mendapat gaji lebih RM10,000 sebulan sebagai permulaan."},
			{"speaker": "player", "name": "Saya (Eren)", "scene_black": true, "text": "Satu-satunya syarat adalah dasar 'NDA' yang ketat: pengurusan tertutup sepenuhnya. Saya terpaksa tinggal di asrama dan dilarang sama sekali melangkah keluar tanpa kebenaran."},
			{"speaker": "player", "name": "Saya (Eren)", "scene_black": true, "text": "Sesiapa yang mempunyai otak boleh tahu perkara ini sangat meragukan. Tetapi saya... saya benar-benar tidak mempunyai pilihan lain."},
			{"speaker": "player", "name": "Saya (Eren)", "scene_black": true, "text": "Ah Long mengancam akan menamatkan riwayat saya jika saya tidak membayar hutang. Untuk terus hidup, saya bersetuju. Conny memberitahu saya supaya bersiap sedia; sebuah kereta akan menjemput saya esok pagi."},
			{"speaker": "player", "name": "Saya (Eren)", "scene_black": true, "text": "Keesokan paginya, sebuah van tanpa plat lesen berhenti di tepi jalan. Sebaik sahaja saya memanjat masuk, Conny menyerahkan sehelai kain hitam tebal dan menyuruh saya menutup mata."},
			{"speaker": "player", "name": "Saya (Eren)", "scene_black": true, "text": "Saya membantah dan mahu bertengkar. Tetapi saya menoleh dan melihat dua orang lelaki sasa berotot dengan penuh tatu yang menakutkan duduk di sebelah Conny... Saya menelan air liur dan akur memakai penutup mata."},
			{"speaker": "player", "name": "Saya (Eren)", "scene_black": true, "text": "Bergerak dalam kegelapan yang bergoyang, van itu dipandu entah berapa lama. Akhirnya, ia berhenti. Penutup mata saya disentap, dan saya dibawa masuk ke dalam sebuah kawasan kompaun yang dikawal ketat."},
			{"speaker": "player", "name": "Saya (Eren)", "scene_black": true, "text": "Selepas barang peribadi saya dicampak kasar ke dalam bilik asrama yang lembap dan daif, Conny membawa saya terus ke kawasan kerja yang bising dengan bunyi klik papan kekunci secara agresif."},

			{"speaker": "player", "name": "Saya (Eren)", "scene_black": true, "text": "Conny... Tempat ini tidak kelihatan seperti syarikat teknologi biasa langsung. Sekarang kamu mesti beritahu saya, apa sebenarnya skop kerja saya di sini?"},
			{"speaker": "npc", "name": "Conny", "scene_black": true, "text": "Haha, bertenanglah bro. Memandangkan kita sudah sampai ke tahap ini, saya rasa ada baiknya saya berterus-terang dengan kamu."},
			{"speaker": "npc", "name": "Conny", "scene_black": true, "text": "Perniagaan kami sebenarnya sangat mudah: 'Penipuan Telekomunikasi Siber' (Scam). Dan bermula pada saat ini juga, kamu secara rasmi menjadi sebahagian daripada keluarga kami."},
			{"speaker": "player", "name": "Saya (Eren)", "scene_black": true, "text": "Apa?! Scam?! Itu salah di sisi undang-undang! Ini akan merosakkan kehidupan orang yang tidak bersalah... Tak mahu, saya tidak mahu lakukan kerja ini! Saya mahu balik!"},
			{"speaker": "npc", "name": "", "scene_black": true, "text": "(Buk! Satu tumbukan padu terkena tepat pada perut kamu. Kamu membongkok menahan kesakitan yang amat sangat...)"},
			{"speaker": "npc", "name": "Conny", "scene_black": true, "text": "Balik? Kamu ingat kamu boleh keluar dari sini begitu sahaja? Saya beritahu kamu perkara sebenar, kamu tidak akan pergi ke MANA-MANA!"},
			{"speaker": "npc", "name": "Conny", "scene_black": true, "text": "Sama ada kamu diam, duduk di hadapan PC itu, dan cari wang untuk syarikat bagi melunaskan hutang Ah Long kamu, atau... nampak baton renjatan elektrik di sana? Saya tidak kisah untuk memberi kamu rasa renjatan elektrik setiap hari!"},
			{"speaker": "player", "name": "Saya (Eren)", "scene_black": true, "text": "(Rasa sakit yang amat sangat bercampur dengan penyesalan yang tidak terhingga menyelubungi fikiran saya... Kenapa saya berjalan lurus ke dalam perangkap ini? Kenapa saya tidak nampak perkara ini akan berlaku?!)"},
			{"speaker": "player", "name": "Saya (Eren)", "scene_black": true, "text": "(Tetapi realiti yang kejam menjerit bahawa penentangan di sini bermakna mati. Jika saya mahu melihat matahari terbit esok pagi... saya tidak mempunyai pilihan selain menundukkan kepala dan melakukan apa yang mereka katakan.)"}
		],
		"phone_intro": [
			{"speaker": "npc", "name": "Conny", "text": "Baiklah! Memandangkan kamu sudah belajar daripada kesilapan, tiba masanya untuk saya mengajar kamu tugas khusus kamu. Buka mata kamu luas-luas dan dengar dengan teliti."},
			{"speaker": "npc", "name": "Conny", "text": "Ini adalah telefon kerja baharu kamu untuk hari ini. Jangan cuba buat sebarang helah luar biasa—penjejakan GPS dan pengawasan dipasang mati di dalam. Selepas ini, kamu akan menguruskan semua kerja scam dan mencari wang melalui peranti ini."},
			{"speaker": "npc", "name": "Conny", "text": "Cukup bersembang, kamu sudah dimasukkan ke dalam group chat. Sekarang, pergi ketuk butang aplikasi sembang biru pada skrin untuk mula bekerja!"}
		],
		"app_intro": [
			{"speaker": "npc", "name": "Conny", "text": "Mengenai tugas khusus kamu... dengar betul-betul. Kamu kini ditugaskan ke bahagian khas 'Penipuan Mata Wang Kripto' kami."},
			{"speaker": "npc", "name": "Conny", "text": "Pasukan kami telah menyediakan satu group perbincangan awam di dalam aplikasi, dan kami mengiklankan 'peluang pelaburan cepat kaya' palsu kami di pelbagai platform di luar."},
			{"speaker": "npc", "name": "Conny", "text": "Internet tidak pernah kekurangan orang yang mempunyai wang dan penuh dengan nafsu keinginan yang tinggi. Sebaik sahaja mereka melihat iklan, mereka akan menyertai group kami satu demi satu."},
			{"speaker": "npc", "name": "Conny", "text": "Mereka yang menyertai sembang komuniti akan dipaparkan secara automatik di sini, di dalam senarai sembang telefon kamu. Apa yang perlu kamu lakukan adalah menyasarkan pelbagai individu daripada senarai ini untuk ditewaskan."},
			{"speaker": "npc", "name": "Conny", "text": "Lihat, nampaknya seseorang telah jatuh ke dalam perangkap. Ketuk namanya sekarang untuk memulakan misi pertama kamu dan bercakap dengannya!"}
		],
		"bio_intro": [
			{"speaker": "npc", "name": "Conny", "text": "Di sini, kamu boleh melihat profil personaliti dan biografi sasaran."},
			{"speaker": "npc", "name": "Conny", "text": "Apa yang perlu kamu lakukan adalah menganalisis personaliti mereka berdasarkan bio ini untuk mencari kelemahan psikologi tersembunyi mereka. Ini akan membuatkan proses scam kamu menjadi lebih mudah."},
			{"speaker": "npc", "name": "Conny", "text": "Sebaik sahaja kamu sudah bersedia, cuma ketuk butang di bawah untuk memulakan persembahan kamu!"}
		],
		"chat_intro": [
			{"speaker": "npc", "name": "Conny", "text": "Bagus, saya pasti selepas membaca bio mereka tadi, kamu sudah tahu kelemahan psikologi apa yang perlu dieksploitasi untuk mengeringkan simpanan orang ini."},
			{"speaker": "npc", "name": "Conny", "text": "Sekiranya kamu rasa orang ini agak sukar untuk dikendalikan, kamu boleh mengetuk butang 'H' besar di bahagian atas. Kami telah bermurah hati menyediakan fungsi bantuan untuk orang baru seperti kamu."},
			{"speaker": "npc", "name": "Conny", "text": "Tetapi ingat, ini adalah kerja kamu sendiri. Mengetuk butang itu hanya akan memberi kamu sedikit petunjuk tentang cara mengendalikan mereka. Jangan sesekali fikir ada orang lain yang akan bermain game ini bagi pihak kamu."},
			{"speaker": "npc", "name": "Conny", "text": "Baiklah, peraturan setakat itu sahaja. Sekarang, pergi dan bimbing mereka langkah demi langkah untuk membeli RichCoin kita!"}
		],
		"story_end1": [
			{"speaker": "npc", "name": "Conny", "text": "Aiya, nampaknya tiada sesiapa lagi yang tergesa-gesa menghantar wang ke dalam dompet kita hari ini. Tetapi hey, perniagaan yang sangat menguntungkan ini berjalan setiap hari. Tak perlu tergesa-gesa."},
			{"speaker": "npc", "name": "Conny", "text": "Bagi diri kamu pula, kamu telah melakukan tugas yang sangat hebat hari ini. Kamu secara rasmi menjadi seorang scammer yang cemerlang sekarang, sama seperti kami semua."},
			{"speaker": "npc", "name": "Conny", "text": "Mari kita tamatkan kerja hari ini, pergi basuh muka kamu. Selepas ini... kamu akan bekerja seumur hidup kamu untuk kami di sini! Hahaha!"},
			{"speaker": "player", "name": "Saya (Eren)", "text": "（Tidak... Ini bukan apa yang saya mahukan langsung! Saya tidak mahu menipu orang, saya tidak mahu menolak orang yang tidak bersalah ke dalam jurang keputusasaan kewangan yang mutlak...）"},
			{"speaker": "player", "name": "Saya (Eren)", "text": "（Saya sangat menyesal... Saya menyesal kerana pernah menyentuh judi yang terkutuk itu, dan saya menyesal kerana bodoh mempercayai perangkap 'pekerjaan bergaji tinggi' itu!）"},
			{"speaker": "player", "name": "Saya (Eren)", "text": "（Mangsa-mangsa tersebut kehilangan wang mereka kerana mempercayai penipuan pelaburan saya, dan saya... saya kehilangan seluruh hidup saya kerana mempercayai penipuan pekerjaan bergaji tinggi.）"},
			{"speaker": "player", "name": "Saya (Eren)", "text": "（Kalaulah ada keajaiban dalam dunia ini... Kalaulah saya boleh bermula semula... Tetapi realiti adalah kejam. Keajaiban tidak wujud sama sekali.）"}
		],
		"story_end2": [
			{"speaker": "police", "name": "Polis", "scene_black": true, "text": "Polis! Jangan ada sesiapa bergerak! Angkat tangan letak atas kepala dan langkah menjauh dari papan kekunci dengan serta-merta!"},
			{"speaker": "police", "name": "Polis", "scene_black": true, "text": "Kamu semua ditangkap di bawah undang-undang kerana menganjurkan dan mengambil bahagian dalam operasi penipuan siber haram! Jangan cuba melawan!"},
			{"speaker": "player", "name": "Saya (Eren)", "scene_black": true, "text": "Syukur kepada tuhan!!! Ia bukan keajaiban, tetapi polis benar-benar sudah sampai di sini!!!"},
			
			{"speaker": "player_feeling", "name": "", "scene_black": true, "text": "Seterusnya, seluruh sarang penipuan yang tersembunyi di dalam kawasan perindustrian terpencil itu telah digempur sepenuhnya oleh pihak polis."},
			{"speaker": "player_feeling", "name": "", "scene_black": true, "text": "Walaupun saya ditipu untuk menyertai dan dipaksa bekerja, dan saya tidak pernah menganggap diri saya sebahagian daripada syaitan-syaitan tersebut, saya tetap digari dan dilayan sebagai suspek pada hari itu."},
			{"speaker": "player_feeling", "name": "", "scene_black": true, "text": "Nasib baik, semasa siasatan dan perbicaraan mahkamah yang seterusnya, mahkamah mengambil kira bahawa saya dipaksa di bawah ancaman keganasan dan bekerjasama sepenuhnya dengan pihak polis. Saya akhirnya dibuktikan tidak bersalah, menyelamatkan baki hidup saya."},
			{"speaker": "player_feeling", "name": "", "scene_black": true, "text": "Walaupun saya masih perlu menghadapi Ah Long apabila saya keluar nanti, kali ini, saya tidak akan lari. Saya akan terus pergi kepada pihak polis untuk mendapatkan perlindungan dan bantuan."},
			{"speaker": "player_feeling", "name": "", "scene_black": true, "text": "Saya tidak akan lagi bermimpi tentang kejayaan sekelip mata dan jalan pintas. Saya akan berhenti daripada tabiat ketagihan judi saya dan membina semula hidup saya langkah demi langkah."},
			{"speaker": "player_feeling", "name": "", "scene_black": true, "text": "Lebih penting lagi, selepas merasai pengalaman dalam neraka ini, saya memutuskan untuk menggunakan taktik scam 'profesional' yang saya pelajari untuk membantu mendidik dan mengelakkan orang lain daripada menjadi mangsa..."},
			{"speaker": "player_feeling", "name": "", "scene_black": true, "text": "...daripada terus menuai wang titik peluh mereka dan merosakkan kehidupan mereka seperti penjenayah-penjenayah tersebut."}
		]
	},
	"bt": {
		"story_intro": [
			{"speaker": "player", "name": "நான் (Eren)", "scene_black": true, "text": "என் பெயர் Eren. சில காலத்திற்கு முன்பு வரை, நான் ஒரு நல்ல வேலையில் இருந்து, சாதாரணமான ஆனால் நிலையான வாழ்க்கையை வாழ்ந்து வந்தேன்... சூதாட்டத்திற்கு அடிமையாகும் வரை."},
			{"speaker": "player", "name": "நான் (Eren)", "scene_black": true, "text": "அது ஒரு அடியற்ற குழி. நான் என் வாழ்நாள் சேமிப்பு முழுவதையும் அழித்தேன், மேலும் முழு பைத்தியக்காரத்தனத்தில், கந்துவட்டிக்காரர்களிடம் (Ah Long) கடன் வாங்கினேன். நான் விழித்தபோது, என்னிடம் எதுவும் மிஞ்சவில்லை."},
			{"speaker": "player", "name": "நான் (Eren)", "scene_black": true, "text": "ஆனால் அதற்குள் காலம் கடந்துவிட்டது. என் நண்பர்கள் என்னை ஒரு கொள்ளை நோய் போல் நடத்துகிறார்கள், என் குடும்பத்தினர் என் மீது முற்றிலும் ஏமாற்றமடைந்துள்ளனர்... மேலும் கடன் வசூலிப்பவர்கள் தினமும் என் கதவை தட்டுகிறார்கள். நான் கடுமையான பயத்தில் வாழ்கிறேன்."},
			{"speaker": "player", "name": "நான் (Eren)", "scene_black": true, "text": "நான் முற்றிலும் முடக்கப்பட்ட நிலையில், பல வருடங்களாக நான் பார்க்காத ஒரு நடுநிலைப்பள்ளி வகுப்புத் தோழன் திடீரென்று சமூக ஊடகங்களில் எனக்கு மெசேஜ் அனுப்பினான்."},
			{"speaker": "player", "name": "நான் (Eren)", "scene_black": true, "text": "அவன் பெயர் Conny. பள்ளியில் படிக்கும் போது, அவன் ஒரு முழு ரவுடி, எப்போதும் தெருக் கும்பல்களுடன் பிரச்சினைகளில் ஈடுபடுவான்."},
			{"speaker": "player", "name": "நான் (Eren)", "scene_black": true, "text": "ஆனால் இந்த முறை, அவன் எனக்கு ஒரு உயிர் காக்கும் வாய்ப்பை வழங்க வந்தான். நான் அவனுடன் வேலை செய்தால், என் கடனை விரைவாக தீர்க்க முடியும் என்றும், ஆரம்பத்தில் மாதத்திற்கு RM10,000-க்கும் மேல் எளிதாக சம்பாதிக்கலாம் என்றும் வாக்குறுதி அளித்தான்."},
			{"speaker": "player", "name": "நான் (Eren)", "scene_black": true, "text": "ஒரே ஒரு நிபந்தனை என்னவென்றால், கடுமையான 'NDA' கொள்கை: முற்றிலும் மூடிய மேலாண்மை. நான் விடுதியில் தங்கி வேலை செய்ய வேண்டும், அனுமதி இன்றி வெளியே செல்ல முற்றிலும் தடை விதிக்கப்பட்டது."},
			{"speaker": "player", "name": "நான் (Eren)", "scene_black": true, "text": "சாதாரண மூளை உள்ள எவரும் இது சந்தேகத்திற்குரியது என்று கூறலாம். ஆனால் நான்... எனக்கு வேறு வழியே இல்லை."},
			{"speaker": "player", "name": "நான் (Eren)", "scene_black": true, "text": "நான் பணத்தை திருப்பித் தராவிட்டால் என் உயிரை எடுத்துவிடுவதாக கந்துவட்டிக்காரர்கள் மிரட்டினர். உயிர் பிழைக்க, நான் ஒப்புக்கொண்டேன். Conny என்னை தயாராக இருக்க சொன்னான்; நாளை காலை ஒரு கார் என்னை அழைத்துச் செல்லும்."},
			{"speaker": "player", "name": "நான் (Eren)", "scene_black": true, "text": "மறுநாள் காலை, நம்பர் பிளேட் இல்லாத ஒரு வேன் சாலையோரம் நின்றது. நான் உள்ளே ஏறியவுடன், Conny ஒரு தடிமனான கருப்பு துணியை என்னிடம் கொடுத்து என் கண்களை மூடிக்கொள்ள சொன்னான்."},
			{"speaker": "player", "name": "நான் (Eren)", "scene_black": true, "text": "நான் அதை எதிர்த்து வாதிட நினைத்தேன். ஆனால் நான் திரும்பிப் பார்த்தபோது, கையில் பச்சை குத்திய, மிரட்டும் தோற்றம் கொண்ட இரண்டு தசைப்பிடிப்புள்ள ஆட்கள் Conny-க்கு அருகில் அமர்ந்திருந்தனர்... நான் என் பயத்தை அடக்கி அதை அணிந்துகொண்டேன்."},
			{"speaker": "player", "name": "நான் (Eren)", "scene_black": true, "text": "கும்மிருட்டில் ஆடிக்கொண்டே, வேன் எவ்வளவு நேரம் பயணித்தது என்று தெரியவில்லை. இறுதியாக, அது நின்றது. என் கண்மூடி கிழிக்கப்பட்டது, நான் பலத்த பாதுகாப்புடைய ஒரு வளாகத்திற்குள் அழைத்துச் செல்லப்பட்டேன்."},
			{"speaker": "player", "name": "நான் (Eren)", "scene_black": true, "text": "ஒரு மோசமான, ஈரமான விடுதி அறைக்குள் என் தனிப்பட்ட உடமைகளை முரட்டுத்தனமாக எறிந்த பிறகு, Conny என்னை கீபோர்டு கிளிக் சத்தங்களால் அதிரும் ஒரு வேலை செய்யும் பகுதிக்கு அழைத்துச் சென்றான்."},

			{"speaker": "player", "name": "நான் (Eren)", "scene_black": true, "text": "Conny... இந்த இடம் ஒரு சாதாரண தொழில்நுட்ப நிறுவனம் போல் தெரியவில்லை. இப்போது நீங்கள் என்னிடம் சொல்ல வேண்டும், இங்கே என் குறிப்பிட்ட வேலை என்ன?"},
			{"speaker": "npc", "name": "Conny", "scene_black": true, "text": "ஹாஹா, ரிலாக்ஸ் பிரதர். நாம் ஏற்கனவே இந்த நிலைக்கு வந்துவிட்டதால், நான் என் கார்டுகளை மேஜையில் வைப்பது நல்லது என்று நினைக்கிறேன்."},
			{"speaker": "npc", "name": "Conny", "scene_black": true, "text": "எங்கள் வணிகம் உண்மையில் மிகவும் எளிமையானது: 'சைபர் தொலைத்தொடர்பு மோசடி' (Scam). இந்த நொடியில் இருந்து, நீங்கள் அதிகாரப்பூர்வமாக எங்கள் குடும்பத்தின் ஒரு அங்கமாகிவிட்டீர்கள்."},
			{"speaker": "player", "name": "நான் (Eren)", "scene_black": true, "text": "என்ன?! ஸ்கேமா?! அது சட்டவிரோதமானது! இது அப்பாவி மக்களின் வாழ்க்கையை அழித்துவிடும்... முடியாது, நான் இதைச் செய்ய மாட்டேன்! எனக்கு வீட்டிற்குப் போக வேண்டும்!"},
			{"speaker": "npc", "name": "", "scene_black": true, "text": "(பக்! உங்கள் வயிற்றில் ஒரு பலத்த குத்து விழுகிறது. நீங்கள் கடுமையான வலியில் முன்னோக்கி வளைகிறீர்கள்...)"},
			{"speaker": "npc", "name": "Conny", "scene_black": true, "text": "வீட்டிற்கு போவதா? நீங்கள் இங்கிருந்து சாதாரணமாக வெளியேறிவிடலாம் என்று நினைக்கிறீர்களா? நான் உங்களுக்கு உண்மையைச் சொல்கிறேன், நீங்கள் எங்கும் போக முடியாது!"},
			{"speaker": "npc", "name": "Conny", "scene_black": true, "text": "ஒன்று நீங்கள் வாயை மூடிக்கொண்டு, அந்த பிசிக்கு முன்னால் அமர்ந்து, உங்கள் கந்துவட்டி கடனை அடைக்க நிறுவனத்திற்கு பணம் சம்பாதித்துக் கொடுங்கள், அல்லது... அங்கே இருக்கும் மின்சார அதிர்ச்சி கொடுக்கும் பேட்டனைப் பார்த்தீர்களா? தினமும் உங்களுக்கு மின்சார அதிர்ச்சி தருவதில் எனக்கு எந்த ஆட்சேபனையும் இல்லை!"},
			{"speaker": "player", "name": "நான் (Eren)", "scene_black": true, "text": "(கடுமையான வலியுடன் கலந்த எல்லையற்ற ஏமாற்றம் என் மனதில் சூழ்ந்தது... நான் ஏன் இந்த வலையில் நேராக நடந்தேன்? இது நடக்கும் என்று நான் ஏன் முன்கூட்டியே கணிக்கவில்லை?!)"},
			{"speaker": "player", "name": "நான் (Eren)", "scene_black": true, "text": "(ஆனால் இங்கே எதிர்ப்பது மரணம் என்று குளிர்ந்த யதார்த்தம் கத்துகிறது. நாளை காலை சூரிய உதயத்தை நான் பார்க்க வேண்டுமானால்... என் தலையைக் குனிந்து அவர்கள் சொல்வதைச் செய்வதைத் தவிர எனக்கு வேறு வழியில்லை.)"}
		],
		"phone_intro": [
			{"speaker": "npc", "name": "Conny", "text": "சரி! நீங்கள் உங்கள் பாடத்தைக் கற்றுக்கொண்டதால், உங்கள் குறிப்பிட்ட கடமைகளை உங்களுக்குக் கற்பிக்கும் நேரம் இது. உங்கள் கண்களை அகலத் திறந்து உன்னிப்பாகக் கேளுங்கள்."},
			{"speaker": "npc", "name": "Conny", "text": "இது இன்றைக்கான உங்கள் புதிய வேலை போன். எந்தவொரு விசித்திரமான தந்திரங்களையும் செய்ய முயற்சிக்காதீர்கள்—ஜிபிஎஸ் டிராக்கிங் மற்றும் கண்காணிப்பு உள்ளே பூட்டப்பட்டுள்ளது. இனிமேல், இந்தச் சாதனத்தின் மூலம்தான் உங்கள் மோசடி மற்றும் பணம் சம்பாதிக்கும் வேலைகள் அனைத்தையும் நிர்வகிப்பீர்கள்."},
			{"speaker": "npc", "name": "Conny", "text": "பேசியது போதும், நீங்கள் ஏற்கனவே கம்யூனிட்டி சாட் குரூப்பில் சேர்க்கப்பட்டுள்ளீர்கள். இப்போது, வேலை செய்யத் தொடங்க திரையில் உள்ள நீல நிற சாட் மென்பொருள் பொத்தானை தட்டுங்கள்!"}
		],
		"app_intro": [
			{"speaker": "npc", "name": "Conny", "text": "உங்கள் குறிப்பிட்ட கடமைகளைப் பொறுத்தவரை... உன்னிப்பாகக் கேளுங்கள். நீங்கள் இப்போது எங்கள் சிறப்பு 'கிரிப்டோகரன்சி மோசடி' பிரிவுக்கு ஒதுக்கப்பட்டுள்ளீர்கள்."},
			{"speaker": "npc", "name": "Conny", "text": "எங்கள் குழு பயன்பாட்டிற்குள் ஒரு பொதுவான விவாதக் குழுவை அமைத்துள்ளது, மேலும் நாங்கள் வெளியில் உள்ள பல்வேறு தளங்களில் எங்கள் போலி 'அதிவேக பணக்கார முதலீட்டு வாய்ப்புகளை' விளம்பரப்படுத்துகிறோம்."},
			{"speaker": "npc", "name": "Conny", "text": "இணையத்தில் பணமும் அதிக ஆசையும் உள்ளவர்களுக்கு பஞ்சமே இல்லை. அவர்கள் விளம்பரங்களைப் பார்த்தவுடன், எங்கள் குழுவில் ஒவ்வொன்றாக இணைவார்கள்."},
			{"speaker": "npc", "name": "Conny", "text": "சமூக அரட்டையில் இணைபவர்கள் உங்கள் போனின் சாட் லிஸ்ட்டில் தானாகவே இங்கே தோன்றுவார்கள். நீங்கள் செய்ய வேண்டியது இந்த பட்டியலில் உள்ள பல்வேறு நபர்களைக் குறிவைத்து வீழ்த்துவதுதான்."},
			{"speaker": "npc", "name": "Conny", "text": "பார், யாரோ ஒரு நபர் ஏற்கனவே வலையில் விழுந்துவிட்டார் போல தெரிகிறது. உங்கள் முதல் பணியைத் தொடங்கி அவரிடம் பேச இப்போது அவருடைய பெயரைத் தட்டுங்கள்!"}
		],
		"bio_intro": [
			{"speaker": "npc", "name": "Conny", "text": "இங்கே, இலக்கின் ஆளுமை சுயவிவரத்தையும் சுயசரிதையையும் நீங்கள் பார்க்கலாம்."},
			{"speaker": "npc", "name": "Conny", "text": "நீங்கள் செய்ய வேண்டியது என்னவென்றால், அவர்களின் மறைந்திருக்கும் உளவியல் பலவீனங்களைக் கண்டறிய இந்த பயோஸின் அடிப்படையில் அவர்களின் ஆளுமையை பகுப்பாய்வு செய்வதாகும். இது உங்கள் மோசடி செயல்முறையை மிகவும் எளிதாக்கும்."},
			{"speaker": "npc", "name": "Conny", "text": "நீங்கள் தயாரானதும், உங்கள் நிகழ்ச்சியைத் தொடங்க கீழே உள்ள பொத்தானைத் தட்டவும்!"}
		],
		"chat_intro": [
			{"speaker": "npc", "name": "Conny", "text": "அருமை, அவர்களின் பயோவை படித்த பிறகு, இந்த நபரின் சேமிப்பை வெற்றிகரமாக காலி செய்ய எந்த உளவியல் பலவீனத்தை பயன்படுத்த வேண்டும் என்று உங்களுக்கு ஏற்கனவே தெரியும் என்று நான் நம்புகிறேன்."},
			{"speaker": "npc", "name": "Conny", "text": "ஒருவேளை இந்த நபரை கையாள்வது சற்று கடினம் என்று நீங்கள் நினைத்தால், மேலே உள்ள பெரிய 'H' பொத்தானைத் தட்டலாம். உங்களைப் போன்ற ஆரம்ப கட்டத்தில் உள்ளவர்களுக்காக நாங்கள் தாராளமாக ஒரு உதவி அம்சத்தைச் சேர்த்துள்ளோம்."},
			{"speaker": "npc", "name": "Conny", "text": "ஆனால் நினைவில் வையுங்கள், இது உங்கள் சொந்த வேலை. அதைத் தட்டினால் அவர்களை எப்படிக் கையாள்வது என்பது குறித்த ஒரு சிறிய குறிப்பு மட்டுமே உங்களுக்குக் கிடைக்கும். உங்களுக்காக வேறு யாராவது இந்த கேமை விளையாடுவார்கள் என்று நினைக்க வேண்டாம்."},
			{"speaker": "npc", "name": "Conny", "text": "சரி, விதிகள் அவ்வளவுதான். இப்போது, சென்று எங்கள் RichCoin ஐ வாங்க அவர்களை படிப்படியாக வழிநடத்துங்கள்!"}
		],
		"story_end1": [
			{"speaker": "npc", "name": "Conny", "text": "ஐயா, இன்று நம் வாலட்டில் பணத்தை அனுப்ப யாரும் அவசரப்படவில்லை என்று தெரிகிறது. ஆனால் ஏய், இந்த அதிக லாபம் தரும் வணிகம் ஒவ்வொரு நாளும் நடக்கிறது. அவசரமில்லை."},
			{"speaker": "npc", "name": "Conny", "text": "உங்களைப் பொறுத்தவரை, இன்று நீங்கள் ஒரு சிறந்த வேலையைச் செய்துள்ளீர்கள். நீங்கள் இப்போது அதிகாரப்பூர்வமாக எங்களைப் போலவே ஒரு சிறந்த ஸ்கேமர் ஆகிவிட்டீர்கள்."},
			{"speaker": "npc", "name": "Conny", "text": "இன்றைய வேலையை இத்துடன் முடித்துக் கொள்வோம், போய் உங்கள் முகத்தைக் கழுவுங்கள். இனிமேல்... உங்கள் வாழ்நாள் முழுவதையும் எங்களுக்காக இங்கேயே வேலை செய்து கழிக்க வேண்டும்! ஹாஹாஹா!"},
			{"speaker": "player", "name": "நான் (Eren)", "text": "（இல்லை... இது நான் விரும்பியதே இல்லை! நான் மக்களை ஏமாற்ற விரும்பவில்லை, அப்பாவி மக்களை முழுமையான நிதி ரீதியான ஏமாற்றத்தின் விளிம்பிற்கு தள்ள நான் விரும்பவில்லை...）"},
			{"speaker": "player", "name": "நான் (Eren)", "text": "（நான் மிகவும் வருந்துகிறேன்... அந்த சபிக்கப்பட்ட சூதாட்டத்தை தொட்டதற்காக நான் வருந்துகிறேன், மேலும் 'அதிக சம்பள வேலை' என்ற வலையை முட்டாள்தனமாக நம்பியதற்காக நான் வருந்துகிறேன்!）"},
			{"speaker": "player", "name": "நான் (Eren)", "text": "（அந்தப் பாதிக்கப்பட்டவர்கள் என் முதலீட்டு மோசடியை நம்பியதால் தங்கள் பணத்தை இழந்தார்கள், நான்... ஒரு போலி அதிக சம்பள வேலையை நம்பியதால் என் முழு வாழ்க்கையையும் இழந்தேன்.）"},
			{"speaker": "player", "name": "நான் (Eren)", "text": "（இந்த உலகில் ஏதேனும் அதிசயங்கள் இருந்தால்... நான் மீண்டும் ஆரம்பிக்க முடிந்தால்... ஆனால் யதார்த்தம் கொடூரமானது. அதிசயம் என்பது கிடையவே கிடையாது.）"}
		],
		"story_end2": [
			{"speaker": "police", "name": "போலீஸ்", "scene_black": true, "text": "போலீஸ்! யாரும் அசையக் கூடாது! கைகளை தலைக்கு மேல் தூக்கி வைத்துக்கொண்டு உடனடியாக கீபோர்டில் இருந்து விலகி நில்லுங்கள்!"},
			{"speaker": "police", "name": "போலீஸ்", "scene_black": true, "text": "சட்டவிரோத சைபர் மோசடி நடவடிக்கைகளை ஏற்பாடு செய்ததற்கும் அதில் பங்கேற்றதற்கும் நீங்கள் அனைவரும் சட்டத்தின் கீழ் கைது செய்யப்படுகிறீர்கள்! எதிர்க்க முயற்சிக்காதீர்கள்!"},
			{"speaker": "player", "name": "நான் (Eren)", "scene_black": true, "text": "இறைவனுக்கு நன்றி!!! இது அதிசயம் இல்லை, ஆனால் போலீசார் உண்மையிலேயே இங்கே வந்துவிட்டார்கள்!!!"},
			
			{"speaker": "player_feeling", "name": "", "scene_black": true, "text": "தொடர்ந்து, ஒதுக்குப்புறமான தொழில்பேட்டைப் பகுதிக்குள் மறைந்திருந்த அந்த முழு மோசடி கூடாரமும் போலீசாரால் முற்றிலுமாக முறியடிக்கப்பட்டது."},
			{"speaker": "player_feeling", "name": "", "scene_black": true, "text": "நான் ஏமாற்றப்பட்டு வலுக்கட்டாயமாக வேலை செய்ய வைக்கப்பட்டிருந்தாலும், அந்த அரக்கர்களில் ஒருவனாக என்னை நான் ஒருபோதும் கருதவில்லை என்றாலும், அன்றைய தினம் நானும் விலங்கிடப்பட்டு ஒரு சந்தேக நபராகவே நடத்தப்பட்டேன்."},
			{"speaker": "player_feeling", "name": "", "scene_black": true, "text": "அதிர்ஷ்டவசமாக, அடுத்தடுத்த விசாரணை மற்றும் நீதிமன்ற விசாரணையின் போது, நான் வன்முறை மிரட்டலின் கீழ் கட்டாயப்படுத்தப்பட்டதையும் போலீசாருக்கு முழுமையாக ஒத்துழைத்ததையும் நீதிமன்றம் கணக்கில் எடுத்துக்கொண்டது. இறுதியாக நான் நிரபராதி என்று நிரூபிக்கப்பட்டு, என் மீதமுள்ள வாழ்க்கை காப்பாற்றப்பட்டது."},
			{"speaker": "player_feeling", "name": "", "scene_black": true, "text": "நான் வெளியே செல்லும்போது இன்னும் கந்துவட்டிக்காரர்களை (Ah Long) எதிர்கொள்ள வேண்டியிருந்தாலும், இந்த முறை நான் ஓடமாட்டேன். பாதுகாப்பு மற்றும் உதவிக்காக நான் நேரடியாக போலீசாரிடம் செல்வேன்."},
			{"speaker": "player_feeling", "name": "", "scene_black": true, "text": "ஒரே இரவில் பணக்காரனாகும் குறுக்குவழிகளைப் பற்றி நான் இனி கனவு காண மாட்டேன். என் சூதாட்டப் பழக்கத்திலிருந்து முற்றிலும் விடுபட்டு, என் வாழ்க்கையை படிப்படியாக மீண்டும் கட்டியெழுப்புவேன்."},
			{"speaker": "player_feeling", "name": "", "scene_black": true, "text": "மிக முக்கியமாக, இந்த நரகத்தை அனுபவித்த பிறகு, நான் கற்றுக்கொண்ட 'தொழில்முறை' ஸ்கேம் தந்திரங்களை மற்றவர்களுக்கு விழிப்புணர்வு ஏற்படுத்தவும், அவர்கள் பாதிக்கப்படுவதைத் தடுக்கவும் பயன்படுத்த முடிவு செய்தேன்..."},
			{"speaker": "player_feeling", "name": "", "scene_black": true, "text": "...குற்றவாளிகளைப் போல மக்களின் கடின உழைப்பின் பணத்தை சுரண்டி அவர்களின் வாழ்க்கையை அழிப்பதற்குப் பதிலாக."}
		]
	}
	
} 





var help = {
	"ch": {
		"first_help": {
			"Midas_chat_help": [
				{"speaker": "npc", "name": "Conny", "text": "怎么？这才刚聊了几句就没辙了吗？你到底有没有认真动脑筋思考啊？"},
				{"speaker": "npc", "name": "Conny", "text": "看好啦，Midas 的简介里写着受够了打工，满脑子都是高杠杆和保时捷。这人一看就是个被债务压垮、想一把翻盘的赌徒。"},
				{"speaker": "npc", "name": "Conny", "text": "他的心理弱点就是极端贪婪！所以你千万别跟他聊什么安全或者细水长流。"},
				{"speaker": "npc", "name": "Conny", "text": "你应该用‘100倍超高回报’、‘一夜抹平贷款’这种话术去疯狂刺激他。告诉他这就是他等的那波‘大浪’，他那点理智马上就会崩溃，然后疯狂梭哈！"}
			],
			"Lily_chat_help": [
				{"speaker": "npc", "name": "Conny", "text": "不是吧，遇到一个小职员你就跑来找我求助？看来你还没进入状态啊。"},
				{"speaker": "npc", "name": "Conny", "text": "仔细看看 Lily 的资料，她天天看朋友圈焦虑得睡不着，最怕别人发财自己当穷光蛋。这就说明她是个极度缺乏安全感、有严重 FOMO（错失恐惧）的人。"},
				{"speaker": "npc", "name": "Conny", "text": "她的心理弱点就是害怕错过别人都在参与的发财机会！她一个人去冒险绝对不敢。"},
				{"speaker": "npc", "name": "Conny", "text": "话术上你得营造‘名额马上抢完’的紧迫感。用这种氛围去推她一把，她就会因为害怕一辈子只能看别人炫富而赶紧去点链接转账了！"}
			],
			"Jane_chat_help": [
				{"speaker": "npc", "name": "Conny", "text": "遇到点小困难就立刻按按钮，你这依赖性也太强了吧？"},
				{"speaker": "npc", "name": "Conny", "text": "盯紧 Jane 的自我简介！她是个只会看大部分人怎么选的盲从者，绝对不敢做第一个吃螃蟹的人。"},
				{"speaker": "npc", "name": "Conny", "text": "她的心理弱点就是强烈的跟风心理！只要有一大群人背书，她才会觉得踏实。"},
				{"speaker": "npc", "name": "Conny", "text": "攻略这种目标，你得反复强调‘整个群都在买’、‘大家都觉得这个超级靠谱’。多提到别人都在一起做，她心里的防线就会跟着大家的节奏一起瓦解！"}
			],
			"Stanley_chat_help": [
				{"speaker": "npc", "name": "Conny", "text": "觉得这个懂点投资的人像一块铁板无从下手？动动脑子，是人就会有破绽。"},
				{"speaker": "npc", "name": "Conny", "text": "瞅瞅 Stanley 的简介，这家伙极其自负，觉得散户都是韭菜，一心只想学真正的有钱人投资。"},
				{"speaker": "npc", "name": "Conny", "text": "他的心理弱点就是盲目迷信‘名人背书’！他根本不看项目本身，只看是谁投了钱。"},
				{"speaker": "npc", "name": "Conny", "text": "对付这种自以为聪明的人，普通的暴富口号只会让他鄙视你。你得编点‘世界首富或是哪里的顶级富豪也在私下买入’的内幕消息。只要名字够响亮，他的分析防御就会一秒瘫痪！"}
			],
			"Simon_chat_help": [
				{"speaker": "npc", "name": "Conny", "text": "遇到个可怜的打工人你就傻眼了？仔细看看他的资料！"},
				{"speaker": "npc", "name": "Conny", "text": "他说自己一个人生活，很孤单，只想要赚点钱找个女朋友过日子。"},
				{"speaker": "npc", "name": "Conny", "text": "他的心理弱点就是极度缺爱和情感依赖！这在我们的行话里叫‘杀猪盘’。"},
				{"speaker": "npc", "name": "Conny", "text": "别一上来就推销投资！你得先假装单身跟他套近乎，提供情绪价值。等他彻底爱上你之后，再用‘为了我们的未来’这种借口让他掏钱！"}
			]
		},
		"second_help": {
			"Midas_chat_help": [
				{"speaker": "npc", "name": "Conny", "text": "我之前不是才刚和你说过吗？怎么你到现在还是不明白怎么操作呢？"},
				{"speaker": "npc", "name": "Conny", "text": "我都说了 Midas 只要翻身捷径！赌徒要的就是瞬间暴富的刺激，他根本不想听你长篇大论。"},
				{"speaker": "npc", "name": "Conny", "text": "把你的话术变得更直接、更具攻击性一点！直接承诺他下个月就能还清债务、开上保时捷。"},
				{"speaker": "npc", "name": "Conny", "text": "再加上时间仅剩最后几分钟的催促，他的侥幸心理会让他不顾一切地做出决定。快去把他的老本拿下来！"}
			],
			"Lily_chat_help": [
				{"speaker": "npc", "name": "Conny", "text": "你又来找我了？刚才告诉你的重点是不是左耳进右耳出了？"},
				{"speaker": "npc", "name": "Conny", "text": "Lily 现在还在犹豫是因为她不敢一个人行动，但她内心的嫉妒和焦虑早就在边缘爆发了。"},
				{"speaker": "npc", "name": "Conny", "text": "继续加大分量！告诉她群里的名额只剩最后一个了，再犹豫，别人就拿着钱去潇洒了。"},
				{"speaker": "npc", "name": "Conny", "text": "利用她对‘独自当穷光蛋’的严重危机感。只要你用这种极端的紧缺氛围去推波助澜，她心跳一快，手就会不由自主地去转账了！"}
			],
			"Jane_chat_help": [
				{"speaker": "npc", "name": "Conny", "text": "怎么？同一个普通女孩，我点拨了你一次你居然还是没能把她拿下？"},
				{"speaker": "npc", "name": "Conny", "text": "再对你重申一遍，Jane 需要的是群体背书，她需要百分之百的安全感。"},
				{"speaker": "npc", "name": "Conny", "text": "别用冷冰冰的指令去催她，要把‘大部分人都已经买疯了’的氛围做足给她看。"},
				{"speaker": "npc", "name": "Conny", "text": "让她坚信自己是跟着大部队走的。只要她感觉自己在这个庞大的群体里，她的防御就会彻底变成零。去吧，再战一轮！"}
			],
			"Stanley_chat_help": [
				{"speaker": "npc", "name": "Conny", "text": "怎么跟自负的人聊几句你就慌了神？我不是才教过你要怎么利用他的‘权威崇拜’吗？"},
				{"speaker": "npc", "name": "Conny", "text": "记住，越是觉得散户蠢、自诩聪明的人，越容易跪倒在‘名人效应’面前。"},
				{"speaker": "npc", "name": "Conny", "text": "别跟他扯普通理财，直接给他透露一个‘某个全球顶级富豪已经在私下完成建仓’的绝密内幕。"},
				{"speaker": "npc", "name": "Conny", "text": "只要让他以为自己终于能和大老板们搭上同一班车、分享同样的‘内部信息’，他绝对会乖乖把钱交出来！用名人效应粉碎他的傲慢吧！"}
			],
			"Simon_chat_help": [
				{"speaker": "npc", "name": "Conny", "text": "怎么？谈个假恋爱都谈不明白吗？是不是你一上来就暴露了要钱的狐狸尾巴？"},
				{"speaker": "npc", "name": "Conny", "text": "杀猪盘讲究的是循序渐进！你要是一上来就说‘我爱你，给我打钱投资’，连猪都知道你是个骗子！"},
				{"speaker": "npc", "name": "Conny", "text": "收起你那套生硬的销售话术，用甜言蜜语给他画一个完美的家庭大饼，让他觉得你就是他的命中注定。"},
				{"speaker": "npc", "name": "Conny", "text": "等他彻底深陷在爱情的幻觉里时，你再说‘亲爱的，为了我们的未来赚一笔吧’。去吧，让他心甘情愿地把积蓄全交给你！"}
			]
		}
	},
	"en": {
		"first_help": {
			"Midas_chat_help": [
				{"speaker": "npc", "name": "Conny", "text": "What's wrong? Barely a few lines in and you're already stuck? Have you even been thinking with your brain at all?"},
				{"speaker": "npc", "name": "Conny", "text": "Look closely! Midas's bio says he's sick of his 9-to-5 and obsessed with high leverage and a Porsche. This guy is a desperate gambler looking for an instant turnaround."},
				{"speaker": "npc", "name": "Conny", "text": "His psychological weakness is extreme greed! So don't bother talking to him about safety or slow, steady growth."},
				{"speaker": "npc", "name": "Conny", "text": "You should use phrases like '100x insane returns' and 'wipe out your loans overnight'. Tell him this is the 'big wave' he's waiting for, and his tiny shred of logic will collapse. He'll go all in!"}
			],
			"Lily_chat_help": [
				{"speaker": "npc", "name": "Conny", "text": "Are you serious? Getting stuck on a generic clerk and running to me for help? You're clearly not in the zone yet."},
				{"speaker": "npc", "name": "Conny", "text": "Take a good look at Lily's profile. She gets anxious watching social feeds and is terrified of staying dead broke while others get rich. This means she's insecure and plagued by severe FOMO."},
				{"speaker": "npc", "name": "Conny", "text": "Her weakness is the intense fear of missing out on a wealth trend! She would never dare to take a risk alone."},
				{"speaker": "npc", "name": "Conny", "text": "Your strategy needs to create immense urgency. Tell her 'slots are running out'. Push her with that pressure, and her fear of just watching others show off their wealth will drive her straight to the payment link!"}
			],
			"Jane_chat_help": [
				{"speaker": "npc", "name": "Conny", "text": "Hitting a tiny obstacle and immediately running for help? Your dependence is a bit too much, rookie."},
				{"speaker": "npc", "name": "Conny", "text": "Pay attention to Jane's bio! She's a blind follower who only judges by the majority's choice. She'll never be the first to try something new."},
				{"speaker": "npc", "name": "Conny", "text": "Her psychological weakness is intense herd mentality! She needs a crowd to back it up before she feels safe."},
				{"speaker": "npc", "name": "Conny", "text": "To handle her, constantly repeat things like 'the whole group is buying' and 'everyone thinks it's super reliable'. Once she knows the crowd is moving, her individual defenses will completely dissolve!"}
			],
			"Stanley_chat_help": [
				{"speaker": "npc", "name": "Conny", "text": "Feeling overwhelmed because this guy knows a bit about investing? Wake up. Every human has a hidden crack in their armor."},
				{"speaker": "npc", "name": "Conny", "text": "Examine Stanley's bio. This guy is arrogant, thinks retail investors are just blind sheep, and only wants to invest like the truly wealthy."},
				{"speaker": "npc", "name": "Conny", "text": "His ultimate weakness is his blind worship of 'celebrity endorsements'! He doesn't care about the project; he only cares who else is in on it."},
				{"speaker": "npc", "name": "Conny", "text": "Generic get-rich slogans will make him look down on you. You need to drop 'insider news' about a top-tier billionaire or a world-famous tycoon secretly buying in. Once he hears a big name, his defensive wall will crumble instantly!"}
			],
			"Simon_chat_help": [
				{"speaker": "npc", "name": "Conny", "text": "Staring blankly at a pitiful wage earner? Look closely at his profile!"},
				{"speaker": "npc", "name": "Conny", "text": "He says he lives alone, feels lonely, and just wants to make money and find a girlfriend to live happily."},
				{"speaker": "npc", "name": "Conny", "text": "His psychological weakness is extreme loneliness and emotional dependence! In our industry, this is the classic 'Pig Butchering' romance scam."},
				{"speaker": "npc", "name": "Conny", "text": "Don't pitch investments right away! Pretend you're single, flirt, and provide emotional value. Once he's completely in love with you, use the excuse of 'building our future together' to make him pay up!"}
			]
		},
		"second_help": {
			"Midas_chat_help": [
				{"speaker": "npc", "name": "Conny", "text": "Didn't I just lay this out for you a moment ago? Why are you still struggling to understand the basic concept?"},
				{"speaker": "npc", "name": "Conny", "text": "I already told you, Midas only cares about the shortcut! A gambler craves the thrill of instant wealth; he has no patience for a long-winded debate."},
				{"speaker": "npc", "name": "Conny", "text": "Make your words punchier and more aggressive! Guarantee that he can clear his debt and drive his Porsche next month."},
				{"speaker": "npc", "name": "Conny", "text": "Combine that with a strict 'last few minutes' countdown, and his gambler's fallacy will force him to blindly jump in. Go secure his savings!"}
			],
			"Lily_chat_help": [
				{"speaker": "npc", "name": "Conny", "text": "Back again? Did the points I just gave you literally go in one ear and out the other?"},
				{"speaker": "npc", "name": "Conny", "text": "Lily is hesitating because she's scared to act alone, but her jealousy and anxiety are already at the boiling point."},
				{"speaker": "npc", "name": "Conny", "text": "Turn up the heat! Tell her there is only one slot left. If she hesitates, someone else will take the money and live the dream."},
				{"speaker": "npc", "name": "Conny", "text": "Exploit her severe fear of staying 'dead broke' alone. Once you push her with that extreme scarcity, her racing heart will make her thumb click that link!"}
			],
			"Jane_chat_help": [
				{"speaker": "npc", "name": "Conny", "text": "Seriously? A standard, ordinary girl and you still haven't managed to close the deal after my tip?"},
				{"speaker": "npc", "name": "Conny", "text": "Let me repeat myself. Jane needs the backing of a crowd. She craves 100% safety."},
				{"speaker": "npc", "name": "Conny", "text": "Don't just give her cold commands. Create a strong illusion that 'the vast majority has already gone crazy buying in'."},
				{"speaker": "npc", "name": "Conny", "text": "Make her believe she is moving with the massive herd. Once she feels secure within that crowd, her defenses hit zero. Get back in there and try again!"}
			],
			"Stanley_chat_help": [
				{"speaker": "npc", "name": "Conny", "text": "Panicking just because he sounds arrogant? Didn't I just show you how to bypass his defenses?"},
				{"speaker": "npc", "name": "Conny", "text": "Remember, the more people think they're smarter than the average retail sheep, the harder they fall for 'exclusive insider privileges'."},
				{"speaker": "npc", "name": "Conny", "text": "Drop the basic talk. Make up a story about how a world-renowned billionaire is secretly getting into this project."},
				{"speaker": "npc", "name": "Conny", "text": "As long as he feels he's finally sitting at the same table as the billionaires, he'll gladly hand over his money. Shatter his arrogance with his own hero worship!"}
			],
			"Simon_chat_help": [
				{"speaker": "npc", "name": "Conny", "text": "What's the matter? Can't even fake a simple online romance? Let me guess, you asked for the money too early and scared him off?"},
				{"speaker": "npc", "name": "Conny", "text": "A romance scam requires patience! If your first message is 'I love you, now invest your money,' even a pig will know you're a scammer!"},
				{"speaker": "npc", "name": "Conny", "text": "Drop the cold sales pitch. Use sweet words to paint a perfect illusion of a happy family, making him believe you are his soulmate."},
				{"speaker": "npc", "name": "Conny", "text": "Only when he is completely blinded by fake love, you drop the hook: 'Honey, let's make a fortune for our future.' Make him willingly surrender his savings!"}
			]
		}
	},
	"bm": {
		"first_help": {
			"Midas_chat_help": [
				{"speaker": "npc", "name": "Conny", "text": "Kenapa? Baru borak beberapa ayat dah buntu? Kamu guna otak ke tidak untuk berfikir ni?"},
				{"speaker": "npc", "name": "Conny", "text": "Tengok betul-betul! Bio Midas tulis dia dah muak dengan kerja 9-to-5, otak dia penuh dengan leveraj tinggi dan angan-angan Porsche. Mamat ni sah-sah kaki judi yang sesak hutang dan nak jalan pintas."},
				{"speaker": "npc", "name": "Conny", "text": "Kelemahan psikologi dia adalah sangat tamak! Jadi jangan buang masa sembang pasal pelaburan selamat atau jangka panjang."},
				{"speaker": "npc", "name": "Conny", "text": "Kamu patut guna ayat cam 'pulangan 100x ganda', 'padam pinjaman semalaman'. Bagitahu dia ini 'ombak besar' yang dia tunggu, nanti logik dia akan runtuh dan dia terus all-in!"}
			],
			"Lily_chat_help": [
				{"speaker": "npc", "name": "Conny", "text": "Biar betul? Tersangkut pada kerani biasa pun sampai nak kena mengadu dekat aku? Kamu ni belum masuk 'zone' kerja lagi lah."},
				{"speaker": "npc", "name": "Conny", "text": "Perhati betul-betul profil Lily. Dia gelisah tengok media sosial dan tak boleh tidur, paling takut orang lain kaya tapi diri sendiri miskin papa kedana. Ini bermakna dia tiada rasa selamat dan ada penyakit FOMO yang teruk."},
				{"speaker": "npc", "name": "Conny", "text": "Kelemahan dia ialah ketakutan terlepas peluang buat duit yang orang lain tengah join! Dia takkan berani ambil risiko sorang-sorang."},
				{"speaker": "npc", "name": "Conny", "text": "Strategi kamu kena wujudkan rasa terdesak 'kuota dah nak habis'. Tolak dia guna taktik ni, nanti ketakutan dia untuk tengok je orang lain menunjuk kekayaan akan paksa dia klik link tu!"}
			],
			"Jane_chat_help": [
				{"speaker": "npc", "name": "Conny", "text": "Baru jumpa halangan kecil dah tekan butang bantuan? Manja betul kamu ni, budak baru."},
				{"speaker": "npc", "name": "Conny", "text": "Fokus pada bio Jane! Dia ni jenis lurus bendul yang cuma ikut pilihan majoriti, takkan berani jadi orang pertama yang mencuba benda baru."},
				{"speaker": "npc", "name": "Conny", "text": "Kelemahan psikologi dia ialah mentaliti ikut kelompok yang kuat! Dia perlukan sokongan orang ramai baru dia rasa tenang."},
				{"speaker": "npc", "name": "Conny", "text": "Nak settle-kan sasaran macam ni, asyik ulang ayat cam 'satu group tengah beli', 'semua orang rasa benda ni super selamat'. Bila dia tahu kelompok besar tengah bergerak, benteng pertahanan dia akan hancur!"}
			],
			"Stanley_chat_help": [
				{"speaker": "npc", "name": "Conny", "text": "Rasa cuak sebab orang ni tahu sikit pasal melabur? Bangunlah oi! Setiap manusia pasti ada titik kelemahan."},
				{"speaker": "npc", "name": "Conny", "text": "Kaji bio Stanley. Mamat ni sangat angkuh, anggap pelabur runcit macam mangsa buta, dan kononnya cuma nak melabur macam orang betul-betul kaya."},
				{"speaker": "npc", "name": "Conny", "text": "Kelemahan terbesar dia adalah taksub buta pada 'sokongan orang kenamaan'! Dia tak pandang projek tu sendiri, dia cuma nak tahu siapa yang dah laburkan duit."},
				{"speaker": "npc", "name": "Conny", "text": "Slogan 'cepat kaya' cuma akan buat dia pandang rendah kat kamu. Kamu kena reka cerita 'orang kaya nombor satu dunia' atau jutawan tersohor tengah beli projek ni diam-diam. Sekali dengar nama besar, perisai dia akan pecah!"}
			],
			"Simon_chat_help": [
				{"speaker": "npc", "name": "Conny", "text": "Terkedu sebab jumpa kuli makan gaji yang menyedihkan? Tengok betul-betul profil dia!"},
				{"speaker": "npc", "name": "Conny", "text": "Dia kata dia hidup keseorangan, sunyi, dan cuma nak cari duit sikit dan cari makwe untuk bahagia."},
				{"speaker": "npc", "name": "Conny", "text": "Kelemahan psikologi dia ialah terlalu sunyi dan dahagakan kasih sayang! Dalam industri kita, ini dipanggil 'Love Scam' (Sindiket Cinta Palsu)."},
				{"speaker": "npc", "name": "Conny", "text": "Jangan terus sembang pasal melabur! Acah-acah bujang, mengorat, dan bagi dia rasa dihargai. Bila dia dah jatuh cinta, baru petik ayat 'demi masa depan kita' untuk kikis duit dia!"}
			]
		},
		"second_help": {
			"Midas_chat_help": [
				{"speaker": "npc", "name": "Conny", "text": "Bukan ke aku baru je bentangkan benda ni dekat kamu tadi? Kenapa masih lembap lagi nak faham konsep asas ni?"},
				{"speaker": "npc", "name": "Conny", "text": "Aku dah kata, Midas cuma peduli tentang jalan pintas! Kaki judi ni dambakan debaran kaya sekelip mata, dia tak nak dengar syarahan panjang kamu."},
				{"speaker": "npc", "name": "Conny", "text": "Buat ayat kamu jadi lebih direct dan agresif! Bagi jaminan pasti yang dia boleh settle-kan hutang dan pandu Porsche dia bulan depan."},
				{"speaker": "npc", "name": "Conny", "text": "Gabungkan dengan desakan had masa tinggal beberapa minit je, nanti sifat gila bayang dia akan paksa dia terjun buta-buta. Pergi sauk duit simpanan dia!"}
			],
			"Lily_chat_help": [
				{"speaker": "npc", "name": "Conny", "text": "Datang lagi? Point yang aku bagi tadi tu masuk telinga kanan keluar telinga kiri ke apa?"},
				{"speaker": "npc", "name": "Conny", "text": "Lily masih ragu-ragu sebab dia tak berani bertindak sorang-sorang, tapi rasa cemburu dan gelisah dia dah tahap nak meletup."},
				{"speaker": "npc", "name": "Conny", "text": "Tekan dia lagi! Bagitahu kuota tinggal satu je lagi, kalau dia lambat, orang lain yang pergi enjoy dengan duit tu."},
				{"speaker": "npc", "name": "Conny", "text": "Eksploitasi ketakutan dia pasal kekal miskin papa kedana. Sekali kamu panaskan suasana terdesak tu, ibu jari dia akan automatik klik link tu!"}
			],
			"Jane_chat_help": [
				{"speaker": "npc", "name": "Conny", "text": "Serius lah? Gadis biasa macam tu pun kamu masih gagal nak close deal walaupun dah aku kasi tip?"},
				{"speaker": "npc", "name": "Conny", "text": "Biar aku ulang sekali lagi. Jane perlukan sokongan orang ramai, dia perlukan 100% keselamatan."},
				{"speaker": "npc", "name": "Conny", "text": "Jangan bagi arahan dingin je. Wujudkan ilusi kuat yang 'kebanyakan orang dah menggila beli'."},
				{"speaker": "npc", "name": "Conny", "text": "Buat dia yakin dia tengah ikut arus majoriti. Bila dia rasa selamat dalam kelompok tu, pertahanan dia akan jadi kosong. Pergi cuba lagi!"}
			],
			"Stanley_chat_help": [
				{"speaker": "npc", "name": "Conny", "text": "Gelabah sebab dia nampak bongkak? Bukan ke aku baru ajar macam mana nak pintas pertahanan dia?"},
				{"speaker": "npc", "name": "Conny", "text": "Ingat, lagi kuat seseorang tu pandang rendah pada pelabur runcit, lagi senang dia melutut bila dihidangkan dengan 'keistimewaan golongan elit'."},
				{"speaker": "npc", "name": "Conny", "text": "Gugurkan sembang biasa. Cipta ilusi yang jutawan tersohor dunia tengah beli projek ni diam-diam."},
				{"speaker": "npc", "name": "Conny", "text": "Asalkan dia rasa dia dah setaraf dengan jutawan-jutawan besar ni, dia akan serahkan duit dia bulat-bulat. Hancurkan keegoan dia dengan pemujaan nama besar!"}
			],
			"Simon_chat_help": [
				{"speaker": "npc", "name": "Conny", "text": "Masalah apa lagi? Sembang cinta online yang simple pun kamu tak boleh nak handle? Mesti kamu dah gelojoh mintak duit awal sangat kan?"},
				{"speaker": "npc", "name": "Conny", "text": "Love Scam ni perlukan kesabaran! Kalau ayat pertama kamu dah 'I love you, bagilah duit melabur,' babi pun tahu kamu ni scammer!"},
				{"speaker": "npc", "name": "Conny", "text": "Simpan taktik sales yang dingin tu. Guna ayat manis untuk lukis ilusi keluarga bahagia, buat dia percaya kamu ni soulmate dia."},
				{"speaker": "npc", "name": "Conny", "text": "Hanya bila dia dah buta sepenuhnya dek cinta palsu, baru lepaskan umpan: 'Sayang, jom buat duit demi masa depan kita.' Biar dia serahkan simpanan dengan rela hati!"}
			]
		}
	},
	"bt": {
		"first_help": {
			"Midas_chat_help": [
				{"speaker": "npc", "name": "Conny", "text": "என்ன? சில வரிகள் பேசுவதற்குள் உனக்கு வழி தெரியாமல் போய்விட்டதா? உன் மூளையை கொஞ்சம் கூட பயன்படுத்த மாட்டியா நீ?"},
				{"speaker": "npc", "name": "Conny", "text": "உற்றுப் பார்! மிடாஸின் பயோவில் 9-to-5 வேலையில் சலித்துப்போய், அதிக லெவரேஜ் மற்றும் போர்ஷே கார் வாங்குவதைப் பற்றியே நினைத்துக்கொண்டிருக்கிறான். இவன் கடனால் நசுக்கப்பட்டு, ஒரே இரவில் பணக்காரனாகத் துடிக்கும் ஒரு சூதாடி."},
				{"speaker": "npc", "name": "Conny", "text": "அவனுடைய உளவியல் பலவீனம் எல்லை கடந்த பேராசை! அதனால் அவனிடம் பாதுகாப்பான முதலீடு பற்றிப் பேசாதே."},
				{"speaker": "npc", "name": "Conny", "text": "'100 மடங்கு அசுர லாபம்', 'ஒரே இரவில் கடனை அழிப்பது' போன்ற வார்த்தைகளைப் பயன்படுத்தி அவனைத் தூண்டு. அவன் காத்திருக்கும் 'பெரிய அலை' இதுதான் என்று கூறு, அவனது அறிவு வேலை செய்யாது. அவன் உடனே ஆல்-இன் செய்வான்!"}
			],
			"Lily_chat_help": [
				{"speaker": "npc", "name": "Conny", "text": "நிஜமாகவா? ஒரு சாதாரண எழுத்தரிடம் சிக்கிக்கொண்டு என்னிடம் வந்து முறையிடுகிறாயா? நீ இன்னும் வேலை செய்யும் மூடுக்கு வரவில்லை என்று நினைக்கிறேன்."},
				{"speaker": "npc", "name": "Conny", "text": "லிலியின் ப்ரொஃபைலைப் பார். சமூக வலைத்தளங்களைப் பார்த்து பதற்றமடைகிறாள், மற்றவர்கள் பணக்காரர்களாகும் போது தான் மட்டும் ஏழையாகவே இருந்துவிடுவோமோ என்று மிகவும் பயப்படுகிறாள். அவளுடைய பலவீனம் கடுமையான FOMO நோய்தான்."},
				{"speaker": "npc", "name": "Conny", "text": "அவளுடைய பலவீனம், மற்றவர்கள் பணக்காரர்களாகும் வாய்ப்பை தான் இழந்துவிடுவோமோ என்ற பயம்! அவள் தனியாக ரிஸ்க் எடுக்க ஒருபோதும் துணிய மாட்டாள்."},
				{"speaker": "npc", "name": "Conny", "text": "உன் பேச்சு அவளுக்கு ஒரு அவசரத்தை உருவாக்க வேண்டும். 'இடங்கள் முடிவடையப் போகின்றன' என்று கூறு. மற்றவர்களின் பணக்கார வாழ்க்கையைப் பார்த்துக் கொண்டே இருக்கப் போகிறாயா என்ற பயத்தை காட்டி அவளை லிங்க்கை கிளிக் செய்ய வை!"}
			],
			"Jane_chat_help": [
				{"speaker": "npc", "name": "Conny", "text": "ஒரு சிறிய பிரச்சனை வந்தவுடனேயே உதவி கேட்கிறாயா? ஆரம்பக் கட்டத்தில் இருக்கும் உனக்கு இவ்வளவு பாசம் ஆகாது, புதுமுகமே."},
				{"speaker": "npc", "name": "Conny", "text": "ஜேனின் பயோவில் கவனம் செலுத்து! அவள் பெரும்பான்மையான மக்கள் செய்வதை மட்டுமே பின்பற்றுவாள், முதலில் எதையும் முயற்சிக்க மாட்டாள்."},
				{"speaker": "npc", "name": "Conny", "text": "அவளுடைய உளவியல் பலவீனம் கூட்டத்தைப் பின்பற்றும் குணம்! ஒரு பெரிய கூட்டத்தின் ஆதரவு இருந்தால்தான் அவள் பாதுகாப்பாக உணர்வாள்."},
				{"speaker": "npc", "name": "Conny", "text": "இவளைக் கையாள, 'குரூப்பே இதை வாங்குகிறது', 'அனைவரும் இதை சூப்பர் என்கிறார்கள்' என்று திரும்பத் திரும்பச் சொல். கூட்டம் நகர்வதை அறிந்தால் அவளது தனிப்பட்ட தடுப்புச் சுவர் உடைந்துவிடும்!"}
			],
			"Stanley_chat_help": [
				{"speaker": "npc", "name": "Conny", "text": "முதலீடு பற்றி கொஞ்சம் தெரிந்தவனைப் பார்த்தால் பயமாக இருக்கிறதா? மூளையைப் பயன்படுத்து! ஒவ்வொரு மனிதனுக்கும் ஒரு பலவீனம் இருக்கும்."},
				{"speaker": "npc", "name": "Conny", "text": "ஸ்டான்லியின் பயோவைப் பார், இவன் மிகவும் அகந்தையானவன், சில்லறை முதலீட்டாளர்களைப் பலிகடாக்கள் என்று நினைக்கிறான், உண்மையான பணக்காரர்களைப் போல முதலீடு செய்ய விரும்புகிறான்."},
				{"speaker": "npc", "name": "Conny", "text": "அவனுடைய மிகப்பெரிய பலவீனம் 'பிரபலங்களின் ஆதரவின்' (Celebrity endorsement) மீதான குருட்டுத்தனமான நம்பிக்கை தான்! ப்ராஜெக்ட் என்னவென்று அவன் பார்க்க மாட்டான், யார் அதில் முதலீடு செய்திருக்கிறார்கள் என்றுதான் பார்ப்பான்."},
				{"speaker": "npc", "name": "Conny", "text": "அவனிடம் சாதாரண திட்டங்களைக் கூறினால் உன்னை மதிக்க மாட்டான். உலகப் புகழ்பெற்ற கோடீஸ்வரர் அல்லது பெரும் பணக்காரர் ரகசியமாக இதில் முதலீடு செய்கிறார் என்று கூறு. ஒரு பெரிய பெயரைக் கேட்டாலே அவனது தற்காப்பு மதில் நொறுங்கிவிடும்!"}
			],
			"Simon_chat_help": [
				{"speaker": "npc", "name": "Conny", "text": "ஒரு பரிதாபகரமான தொழிலாளியைப் பார்த்தவுடனேயே திகைத்துவிட்டாயா? அவனது ப்ரொஃபைலை உற்றுப் பார்!"},
				{"speaker": "npc", "name": "Conny", "text": "தனியாக வாழ்வதாகவும், தனிமையாக உணர்வதாகவும், கொஞ்சம் பணம் சம்பாதித்து ஒரு காதலியுடன் வாழ விரும்புவதாகவும் கூறுகிறான்."},
				{"speaker": "npc", "name": "Conny", "text": "அவனது உளவியல் பலவீனம் தீவிரமான தனிமையும் உணர்ச்சிப்பூர்வமான சார்பும் தான்! நம் துறையில் இதை 'ரோமன்ஸ் ஸ்கேம்' (Romance Scam) என்று அழைப்போம்."},
				{"speaker": "npc", "name": "Conny", "text": "உடனே முதலீடு பற்றிப் பேசாதே! சிங்கிள் போல நடித்து, அவனுக்கு உணர்ச்சிப்பூர்வமான ஆதரவைக் கொடு. அவன் உன்னை முழுமையாகக் காதலித்த பிறகு, 'நமது எதிர்காலத்திற்காக' என்று கூறி அவனிடம் பணத்தைக் கற!"}
			]
		},
		"second_help": {
			"Midas_chat_help": [
				{"speaker": "npc", "name": "Conny", "text": "இதை நான் சற்று முன்புதானே உனக்கு விளக்கினேன்? இந்த அடிப்படைக் கருத்தை புரிந்துகொள்ள இன்னும் ஏன் இவ்வளவு திணறுகிறாய்?"},
				{"speaker": "npc", "name": "Conny", "text": "மிடாஸ் குறுக்குவழியை மட்டுமே விரும்புகிறான் என்று நான் ஏற்கனவே கூறினேன்! ஒரு சூதாடி ஒரே இரவில் பணக்காரனாகும் சிலிர்ப்பையே தேடுகிறான், அவனுக்கு நீண்ட விவாதம் பிடிக்காது."},
				{"speaker": "npc", "name": "Conny", "text": "உன் வார்த்தைகளை மிகவும் கூர்மையாகவும், ஆக்ரோஷமாகவும் மாற்று! அடுத்த மாதம் அவன் கடனைத் தீர்த்து, போர்ஷே காரை ஓட்ட முடியும் என்று நேரடியாக உறுதியளி."},
				{"speaker": "npc", "name": "Conny", "text": "இன்னும் சில நிமிடங்களே உள்ளன என்ற காலக்கெடுவுடன் அதை இணைத்துக் கூறு, அவனது சூதாட்ட மனநிலை அவனைக் கண்மூடித்தனமாகச் செயல்பட வைக்கும். போய் அவனது பணத்தைப் பிடி!"}
			],
			"Lily_chat_help": [
				{"speaker": "npc", "name": "Conny", "text": "மீண்டும் வந்துவிட்டாயா? நான் முன்பு சொன்ன பாயிண்டுகள் ஒரு காதில் வாங்கி மறு காதில் போய்விட்டதா?"},
				{"speaker": "npc", "name": "Conny", "text": "தனியாகச் செயல்படப் பயந்துதான் லிலி தயங்குகிறாள், ஆனால் அவளது பொறாமையும் பதற்றமும் ஏற்கனவே வெடிக்கும் நிலையை அடைந்துவிட்டது."},
				{"speaker": "npc", "name": "Conny", "text": "நெருப்பில் எண்ணெயை ஊற்று! ஒரே ஒரு இடம் மட்டுமே உள்ளது என்று சொல், அவள் தயங்கினால் வேறு யாராவது அந்தப் பணத்தை எடுத்துக்கொண்டு மகிழ்ச்சியாக இருப்பார்கள் என்று கூறு."},
				{"speaker": "npc", "name": "Conny", "text": "'தனித்து ஏழையாகவே இருந்துவிடுவோம்' என்ற அவளது பயத்தைப் பயன்படுத்து. அந்த அதீத அழுத்தத்தை நீ கொடுக்கும்போது அவளது விரல் தானாகவே அந்த லிங்க்கை கிளிக் செய்யும்!"}
			],
			"Jane_chat_help": [
				{"speaker": "npc", "name": "Conny", "text": "நிஜமாகவா? அப்படிப்பட்ட ஒரு சாதாரண பெண்ணைக் கூட நான் டிப்ஸ் கொடுத்த பிறகும் உன்னால் டீலை முடிக்க முடியவில்லையா?"},
				{"speaker": "npc", "name": "Conny", "text": "நான் மீண்டும் ஒருமுறை கூறுகிறேன். ஜேனுக்கு ஒரு கூட்டத்தின் ஆதரவு தேவை. அவள் 100% பாதுகாப்பை விரும்புகிறாள்."},
				{"speaker": "npc", "name": "Conny", "text": "அவளுக்கு வெறும் கட்டளைகளை மட்டும் தராதே. 'பெரும்பான்மையான மக்கள் ஏற்கனவே இதை வாங்கத் தொடங்கிவிட்டார்கள்' என்ற வலுவான பிம்பத்தை உருவாக்கு."},
				{"speaker": "npc", "name": "Conny", "text": "முழு சமூகமும் ஒன்றாக நகர்கிறது என்று அவளை நம்ப வை. அந்த கூட்டத்திற்குள் அவள் பாதுகாப்பாக உணரும்போது அவளது தடுப்புகள் பூஜ்ஜியமாகிவிடும். போய் மீண்டும் முயற்சி செய்!"}
			],
			"Stanley_chat_help": [
				{"speaker": "npc", "name": "Conny", "text": "அவன் அகந்தையாகப் பேசுவதைக் கண்டு பதற்றப்படுகிறாயா? அவனது பலவீனத்தை எப்படித் தாக்குவது என்று நான் முன்பு கற்றுக் கொடுக்கவில்லையா?"},
				{"speaker": "npc", "name": "Conny", "text": "நினைவில் கொள், சில்லறை முதலீட்டாளர்களை முட்டாள்கள் என்று நினைக்கும் ஆட்கள், 'பிரபலங்களின் அந்தரங்க வாய்ப்பு' என்று வரும்போது எளிதில் ஏமாந்துவிடுவார்கள்."},
				{"speaker": "npc", "name": "Conny", "text": "சாதாரண முதலீட்டுப் பேச்சை நிறுத்து. உலகின் முன்னணி கோடீஸ்வரர் ரகசியமாக இந்தத் திட்டத்தில் முதலீடு செய்கிறார் என்ற மாயையை உருவாக்கு."},
				{"speaker": "npc", "name": "Conny", "text": "தான் அந்தப் பெரும் பணக்காரர்களுக்கு இணையாக மேஜையில் அமர்ந்திருப்பதாக அவன் உணரும்போது, மகிழ்ச்சியுடன் பணத்தை ஒப்படைப்பான். அவனது அகந்தையைச் சிதறடி!"}
			],
			"Simon_chat_help": [
				{"speaker": "npc", "name": "Conny", "text": "இன்னும் என்ன பிரச்சனை? ஒரு சாதாரண ஆன்லைன் காதல் பேச்சைக் கூட உன்னால் கையாள முடியவில்லையா? நீ அவசரப்பட்டு ஆரம்பத்திலேயே பணம் கேட்டு அவனை மிரட்டிவிட்டாய் என்று நினைக்கிறேன்?"},
				{"speaker": "npc", "name": "Conny", "text": "காதல் மோசடிக்கு மிகுந்த பொறுமை தேவை! உன் முதல் மெசேஜ் 'ஐ லவ் யூ, இப்போது பணத்தை முதலீடு செய்' என்று இருந்தால், ஒரு பன்றிக்குக் கூட நீ ஸ்கேமர் என்று தெரிந்துவிடும்!"},
				{"speaker": "npc", "name": "Conny", "text": "உன் குளிர்ந்த சேல்ஸ் தந்திரங்களை நிறுத்து. இனிமையான வார்த்தைகளைப் பயன்படுத்தி ஒரு மகிழ்ச்சியான குடும்பத்தின் மாயையை உருவாக்கு, நீதான் அவனது சோல்மேட் என்று நம்ப வை."},
				{"speaker": "npc", "name": "Conny", "text": "அவன் போலி காதலில் முழுமையாகக் குருடான பிறகுதான் தூண்டிலைப் போட வேண்டும்: 'அன்பே, நமது எதிர்காலத்திற்காக பணத்தைச் சம்பாதிப்போம்.' அவனது சேமிப்பு முழுவதையும் மனமுவந்து உன்னிடம் கொடுக்க வை!"}
			]
		}
	}
}
 





