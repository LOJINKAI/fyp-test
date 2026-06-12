extends AudioStreamPlayer


var music_menu = preload("res://sound/bgm/main.mp3")
var music_gameplay = preload("res://sound/bgm/game.mp3")
var music_before_police = preload("res://sound/bgm/bad_end.mp3")
var music_police = preload("res://sound/bgm/good_end.mp3")

@onready var player = $"."

func play_music(type):
	
	if type == null or type == "":
		return 
		
	var new_stream = null
	match type:
		"main": new_stream = music_menu
		"game": new_stream = music_gameplay
		"before_police": new_stream = music_before_police
		"police": new_stream = music_police
	
	if new_stream:
		
		if player.stream == new_stream and player.playing:
			return
			
	player.stream = new_stream
	player.play()





func stop_music():
	player.stop()
