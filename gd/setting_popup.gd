extends CanvasLayer


@onready var bgm_slider = $window/VBoxContainer/bgm_slider
@onready var sound_effect_slider = $window/VBoxContainer/sound_effect_slider


func _ready():
	Bgm.play_music("main")
	
	bgm_slider.value = Global.bgm_volume
	sound_effect_slider.value = Global.sound_effect_volume
	
	apply_volume("bgm", Global.bgm_volume)
	apply_volume("sound_effect", Global.sound_effect_volume)
	
	bgm_slider.value_changed.connect(_on_bgm_slider_changed)
	sound_effect_slider.value_changed.connect(_on_sound_effect_slider_changed)

func apply_volume(bus_name, value):
	var db = linear_to_db(value / 100.0)
	if value == 0: db = -80
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(bus_name), db)


func _on_bgm_slider_changed(value):

	Global.bgm_volume = value 
	
	var db = linear_to_db(value / 100.0)
	if value == 0: 
		db = -80
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("bgm"), db)
	Global.save_game_setting()



func _on_sound_effect_slider_changed(value):
	
	Global.sound_effect_volume = value 
	
	var db = linear_to_db(value / 100.0)
	if value == 0: 
		db = -80
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("sound_effect"), db)
	Global.save_game_setting()
	
	
func _process(delta):
	pass


func _on_texture_button_pressed():
	SoundEffect.play_sound("ui_click")
	Global.save_game_setting()
	queue_free() 




func _on_ch_pressed():
	SoundEffect.play_sound("ui_click")
	Global.current_language = "ch" 
	Global.save_game_setting()
	print("Global.current_language = ",Global.current_language)


func _on_en_pressed():
	SoundEffect.play_sound("ui_click")
	Global.current_language = "en" 
	Global.save_game_setting()
	print("Global.current_language = ",Global.current_language)

func _on_bm_pressed():
	SoundEffect.play_sound("ui_click")
	Global.current_language = "bm" 
	Global.save_game_setting()
	print("Global.current_language = ",Global.current_language)

func _on_bt_pressed():
	SoundEffect.play_sound("ui_click")
	Global.current_language = "bt" 
	Global.save_game_setting()
	print("Global.current_language = ",Global.current_language)
