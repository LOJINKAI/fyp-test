# group_chat.gd

extends Control

const BUBBLE_SCENE = preload("res://scene/group_chat_bubble.tscn")
@onready var message_list = $main/body/message_list # 确保路径和你的场景一致

var lang = Global.current_language


var all_groups_data = {
	"ch": {
		"Midas": [
			{"is_mine": false, "text": "绝了！昨天丢进去 5000，今天早上看利息直接翻倍了！"},
			{"is_mine": false, "text": "我刚把大马银行的定期存款全提出来了，导师说这波 RichCoin 回报率高达 300%！"},
			{"is_mine": true,  "text": "欢迎新群友。今天下午的【稳赚暴利通道】最后开放。"},
			{"is_mine": true,  "text": "想跟我们一起资本翻倍的，速度点链接锁仓：\n[url=https://richcoin-global.invest-now.pro]https://richcoin-global.invest-now.pro[/url]"},
			{"is_mine": false, "text": "收到！我又追投了 2 万，跟着管理员买真的躺着数钱啊！"}
		],
		"Lily": [
			{"is_mine": false, "text": "喂喂喂，刚看公告私募名额只剩几个了！还有谁没上车的？"},
			{"is_mine": false, "text": "我刚才迟了一分钟差点没买到！幸好手快，不买真的会后悔一辈子！"},
			{"is_mine": true,  "text": "各位，最后一波红利倒计时 5 分钟，错过今天再也没有这个价了。"},
			{"is_mine": true,  "text": "别等别人都暴富了你才来拍大腿，抢购直达：\n[url=https://vip-access.richcoin-launch.net/private-sale]https://vip-access.richcoin-launch.net/private-sale[/url]"},
			{"is_mine": false, "text": "天啊，幸好我全仓跟进了，慢一秒就彻底错过了！"}
		],
		"Jane": [
			{"is_mine": false, "text": "之前欠了银行几万的大马卡债，全靠导师带我买币，下个月就能一次过还清了！"},
			{"is_mine": false, "text": "明白你的感受，我之前生意失败也是每天睡不着，是这个币救了我全家。"},
			{"is_mine": true,  "text": "别灰心，发财币就是给普通人打破死局、实现打工人生意翻盘的唯一机会。"},
			{"is_mine": true,  "text": "想要尽早摆脱债务、彻底翻身的，通道在这里：\n[url=https://pay.crypto-assets.secure-gateway.app/checkout]https://pay.crypto-assets.secure-gateway.app/checkout[/url]"},
			{"is_mine": false, "text": "哭死，今天终于把拖欠几个月的租金给清了，这绝对是老天爷给的翻身出路！"}
		],
		"Stanley": [
			{"is_mine": false, "text": "听内幕说好几个华尔街的顶级风投大咖都在私下增持 RichCoin 了。"},
			{"is_mine": false, "text": "那当然，普通的割韭菜项目那些富豪根本看不上。这个是有大集团技术背书的。"},
			{"is_mine": true,  "text": "没错，普通理财只能抗通胀。大亨富豪玩的是高门槛的行业绝密私募。"},
			{"is_mine": true,  "text": "本群享有专属白名单通道，想要跻身高阶资产圈的，直接直达链接：\n[url=https://internal-referral.richcoin-launch.com]https://internal-referral.richcoin-launch.com[/url]"},
			{"is_mine": false, "text": "跟着上流社会的风向走绝对不会错，今天又入手了 5 个节点，格调立刻拉满。"}
		],
		"Simon": [
			{"is_mine": false, "text": "之前一个人在吉隆坡打拼感觉很孤单，谢谢这个群的兄弟姐妹每天无私分享赚钱内幕。"},
			{"is_mine": false, "text": "对啊，导师和管理员真的就像家里人一样亲切，有钱大家一起赚，太温暖了。"},
			{"is_mine": true,  "text": "我们不仅是一个投资群，更是一个互相扶持、共同走向富裕的大家庭。"},
			{"is_mine": true,  "text": "信任我们的家人，请直接点击属于我们家庭的内部私募直达链接：\n[url=https://exclusive-mint.crypto-fast-track.org]https://exclusive-mint.crypto-fast-track.org[/url]"},
			{"is_mine": false, "text": "感恩遇到这个充满爱的群，跟着大家一起买发财币，心里特别踏实安全！"}
		]
	},
	"en": {
		"Midas": [
			{"is_mine": false, "text": "Insane! Placed 5,000 yesterday, checked this morning and my profit doubled!"},
			{"is_mine": false, "text": "Just withdrew all my fixed deposits. Mentor says this RichCoin wave yields 300% ROI!"},
			{"is_mine": true,  "text": "Welcome newcomers. Today's [Guaranteed High-Yield Channel] is open for the last time."},
			{"is_mine": true,  "text": "To double your capital with us, secure your spot now:\n[url=https://richcoin-global.invest-now.pro]https://richcoin-global.invest-now.pro[/url]"},
			{"is_mine": false, "text": "Done! Topped up another 20,000. Easiest money I've ever made!"}
		],
		"Lily": [
			{"is_mine": false, "text": "Hey guys! Notice says only a few private spots left! Who hasn't boarded yet?"},
			{"is_mine": false, "text": "I was one minute late and almost missed out! You'll regret it for life if you don't buy now!"},
			{"is_mine": true,  "text": "Countdown 5 minutes left for the final wave. You'll never see this price again."},
			{"is_mine": true,  "text": "Don't wait until everyone is rich to regret it. Grab your quota now:\n[url=https://vip-access.richcoin-launch.net/private-sale]https://vip-access.richcoin-launch.net/private-sale[/url]"},
			{"is_mine": false, "text": "Gosh, glad I went all in. A second later and I would've missed the flight entirely!"}
		],
		"Jane": [
			{"is_mine": false, "text": "Had massive credit card debts before, but thanks to mentor, I can clear them all next month!"},
			{"is_mine": false, "text": "I feel you. My business failed before and I couldn't sleep. This coin saved my whole family."},
			{"is_mine": true,  "text": "Don't lose hope. Fortune Coin is the only chance for average folks to break their dead ends and flip their lives."},
			{"is_mine": true,  "text": "To get out of debt and start your comeback journey, click here:\n[url=https://pay.crypto-assets.secure-gateway.app/checkout]https://pay.crypto-assets.secure-gateway.app/checkout[/url]"},
			{"is_mine": false, "text": "Tearing up right now. Finally cleared my overdue rent today. This is truly our way out!"}
		],
		"Stanley": [
			{"is_mine": false, "text": "Insider leaks say several top Wall Street venture capitalists are secretly accumulating RichCoin."},
			{"is_mine": false, "text": "Of course, those elites wouldn't look at ordinary retail projects. This has major institutional backing."},
			{"is_mine": true,  "text": "Correct. Ordinary financial products only combat inflation. Tycoons play with exclusive, private allocations."},
			{"is_mine": true,  "text": "This group enjoys a direct whitelist channel. To join the high-net-worth circle, click here:\n[url=https://internal-referral.richcoin-launch.com]https://internal-referral.richcoin-launch.com[/url]"},
			{"is_mine": false, "text": "Following smart money never goes wrong. Just secured 5 more nodes today, elite status achieved."}
		],
		"Simon": [
			{"is_mine": false, "text": "Used to feel so lonely hustling alone in KL, thank you brothers and sisters here for selflessly sharing tips."},
			{"is_mine": false, "text": "Exactly! The mentor and admin are like family. Making money together feels so warm."},
			{"is_mine": true,  "text": "We are more than an investment group; we are a family supporting each other towards wealth."},
			{"is_mine": true,  "text": "For the family members who trust us, here is our exclusive allocation link:\n[url=https://exclusive-mint.crypto-fast-track.org]https://exclusive-mint.crypto-fast-track.org[/url]"},
			{"is_mine": false, "text": "Grateful to find this loving community. Buying Fortune Coin with everyone gives me total peace of mind!"}
		]
	},
	"bm": {
		"Midas": [
			{"is_mine": false, "text": "Memang gila! Labur 5,000 semalam, pagi ni tengok untung terus ganda dua!"},
			{"is_mine": false, "text": "Aku baru keluarkan semua simpanan tetap bank. Mentor kata RichCoin kali ni ROI sampai 300%!"},
			{"is_mine": true,  "text": "Selamat datang ahli baru. Saluran [Untung Lumayan Dijamin] petang ini dibuka buat kali terakhir."},
			{"is_mine": true,  "text": "Nak gandakan modal bersama kami? Klik pautan sekarang:\n[url=https://richcoin-global.invest-now.pro]https://richcoin-global.invest-now.pro[/url]"},
			{"is_mine": false, "text": "Setel! Aku tambah lagi 20,000. Goyang kaki je buat duit dengan admin!"}
		],
		"Lily": [
			{"is_mine": false, "text": "Wey korang! Pengumuman kata slot private sale tinggal sikit je lagi! Siapa belum naik van?"},
			{"is_mine": false, "text": "Aku lambat satu minit tadi hampir melepas! Menyesal seumur hidup kalau tak beli sekarang!"},
			{"is_mine": true,  "text": "Perhatian, kaunter bonus terakhir tutup lagi 5 minit. Lepas ni tak dapat dah harga ni."},
			{"is_mine": true,  "text": "Jangan tunggu orang lain dah kaya baru nak menangis. Klik pautan pantas:\n[url=https://vip-access.richcoin-launch.net/private-sale]https://vip-access.richcoin-launch.net/private-sale[/url]"},
			{"is_mine": false, "text": "Fuh nasib baik aku dah sauk semua, lambat sesaat tadi memang rugi besar!"}
		],
		"Jane": [
			{"is_mine": false, "text": "Dulu hutang kad kredit keliling pinggang, nasib baik mentor bantu beli koin ni, bulan depan setel semua!"},
			{"is_mine": false, "text": "Aku faham. Bisnes aku lingkup dulu sampai tak boleh tidur. Koin inilah yang selamatkan keluarga aku."},
			{"is_mine": true,  "text": "Jangan putus asa. Fortune Coin adalah satu-satunya jalan untuk orang biasa lepaskan diri daripada kesempitan hidup."},
			{"is_mine": true,  "text": "Sesiapa yang nak bebas hutang dan ubah nasib hidup, klik pautan ini:\n[url=https://pay.crypto-assets.secure-gateway.app/checkout]https://pay.crypto-assets.secure-gateway.app/checkout[/url]"},
			{"is_mine": false, "text": "Nak nangis rasanya. Hari ni dapat setel sewa rumah yang tertunggak. Ini memang peluang keemasan!"}
		],
		"Stanley": [
			{"is_mine": false, "text": "Info dalaman kata beberapa pakar modal teroka Wall Street secara senyap tengah borong RichCoin."},
			{"is_mine": false, "text": "Mestilah, golongan elit tak pandang projek runcit biasa. Projek ni ada sokongan institusi besar."},
			{"is_mine": true,  "text": "Tepat sekali. Produk kewangan biasa cuma lawan inflasi. Golongan jutawan main 'private sale' premium."},
			{"is_mine": true,  "text": "Group ini mendapat akses senarai putih eksklusif. Nak sertai komuniti aset kelas tinggi? Klik pautan:\n[url=https://internal-referral.richcoin-launch.com]https://internal-referral.richcoin-launch.com[/url]"},
			{"is_mine": false, "text": "Ikut jejak langkah orang kaya takkan silap. Hari ni aku sauk lagi 5 nod, status elit setel."}
		],
		"Simon": [
			{"is_mine": false, "text": "Dulu rasa sunyi sangat cari rezeki sorang-sorang kat KL, terima kasih abang kakak kat sini sebab selalu kongsi tips untung."},
			{"is_mine": false, "text": "Betul! Mentor dengan admin dah macam keluarga sendiri, mesra sangat. Cari duit sama-sama rasa gembira."},
			{"is_mine": true,  "text": "Kita bukan sekadar group pelaburan, kita adalah keluarga besar yang saling membantu demi kesenangan bersama."},
			{"is_mine": true,  "text": "Buat ahli keluarga yang percaya kepada kami, klik pautan eksklusif kita di sini:\n[url=https://exclusive-mint.crypto-fast-track.org]https://exclusive-mint.crypto-fast-track.org[/url]"},
			{"is_mine": false, "text": "Bersyukur sangat jumpa group yang penuh kasih sayang ni. Beli Fortune Coin sama-sama rasa tenang sangat!"}
		]
	},
	"bt": {
		"Midas": [
			{"is_mine": false, "text": "அற்புதம்! நேற்று 5,000 போட்டேன், இன்று காலை லாபம் இரட்டிப்பாகிவிட்டது!"},
			{"is_mine": false, "text": "எனது பிக்சட் டெபாசிட் முழுவதையும் எடுத்துவிட்டேன். RichCoin 300% லாபம் தரும் என வழிகாட்டி கூறுகிறார்!"},
			{"is_mine": true,  "text": "புதியவர்களை வரவேற்கிறோம். இன்றைய [உத்தரவாத அதிக லாப வழி] கடைசி முறையாக திறக்கப்பட்டுள்ளது."},
			{"is_mine": true,  "text": "எங்களுடன் உங்கள் மூலதனத்தை இரட்டிப்பாக்க, இப்போதே லிங்க்கை கிளிக் செய்யவும்:\n[url=https://richcoin-global.invest-now.pro]https://richcoin-global.invest-now.pro[/url]"},
			{"is_mine": false, "text": "முடிந்தது! மேலும் 20,000 முதலீடு செய்துள்ளேன். நிர்வாகியுடன் சேர்ந்தால் மிக எளிதாக பணம் சம்பாதிக்கலாம்!"}
		],
		"Lily": [
			{"is_mine": false, "text": "நண்பர்களே! அறிவிப்பில் சில பிரத்தியேக இடங்கள் மட்டுமே உள்ளன எனக் கூறப்பட்டுள்ளது! இன்னும் யார் வாங்கவில்லை?"},
			{"is_mine": false, "text": "நான் ஒரு நிமிடம் தாமதித்தேன், நூலிழையில் தப்பித்தேன்! இப்போது வாங்காவிட்டால் வாழ்நாள் முழுவதும் வருந்துவீர்கள்!"},
			{"is_mine": true,  "text": "இறுதி வாய்ப்பிற்கான கவுண்ட்டவுன் 5 நிமிடங்கள் மட்டுமே உள்ளது. இந்த விலை மீண்டும் கிடைக்காது."},
			{"is_mine": true,  "text": "மற்றவர்கள் பணக்காரர்களாகும் வரை காத்திருந்து வருந்தாதீர்கள். இப்போதே லிங்க் மூலம் வாங்குங்கள்:\n[url=https://vip-access.richcoin-launch.net/private-sale]https://vip-access.richcoin-launch.net/private-sale[/url]"},
			{"is_mine": false, "text": "நல்லவேளை, நான் இப்போதே முதலீடு செய்துவிட்டேன். ஒரு விநாடி தாமதித்திருந்தாலும் வாய்ப்பு போயிருக்கும்!"}
		],
		"Jane": [
			{"is_mine": false, "text": "முன்பு பெரும் கிரெடிட் கார்டு கடன் இருந்தது, ஆனால் வழிகாட்டியால் அடுத்த மாதம் அனைத்தையும் அடைத்துவிடலாம்!"},
			{"is_mine": false, "text": "உங்கள் நிலை புரியுது. எனது தொழில் நஷ்டமடைந்து தூக்கமில்லாமல் தவித்தேன். இந்த காயின்தான் என் குடும்பத்தை மீட்டது."},
			{"is_mine": true,  "text": "நம்பிக்கையை இழக்காதீர்கள். சாதாரண மக்கள் தங்கள் கஷ்டங்களிலிருந்து விடுபட்டு வாழ்க்கையை மாற்றிக்கொள்ள ஃபார்ட்டூன் காயின் மட்டுமே ஒரே வழி."},
			{"is_mine": true,  "text": "கடனிலிருந்து விடுபட்டு உங்கள் வாழ்க்கையை மீட்டெடுக்க, இங்கே கிளிக் செய்யவும்:\n[url=https://pay.crypto-assets.secure-gateway.app/checkout]https://pay.crypto-assets.secure-gateway.app/checkout[/url]"},
			{"is_mine": false, "text": "கண்ணீர் வருகிறது. இன்று இறுதியாக எனது நிலுவை வாடகையை செலுத்திவிட்டேன். இதுவே நமக்கான நல்வழி!"}
		],
		"Stanley": [
			{"is_mine": false, "text": "பல முன்னணி வால் ஸ்ட்ரீட் முதலீட்டாளர்கள் ரகசியமாக RichCoin-ஐ வாங்கி வருவதாக உள்விவரங்கள் கூறுகின்றன."},
			{"is_mine": false, "text": "நிச்சயமாக, அந்த உயரடுக்கு மக்கள் சாதாரண திட்டங்களை பார்க்க மாட்டார்கள். இதற்கு பெரும் நிறுவனங்களின் ஆதரவு உள்ளது."},
			{"is_mine": true,  "text": "சரிதான். சாதாரண நிதி தயாரிப்புகள் பணவீக்கத்தை மட்டுமே எதிர்க்கும். பெரும் பணக்காரர்கள் பிரத்தியேக தனியார் ஒதுக்கீடுகளில் விளையாடுகிறார்கள்."},
			{"is_mine": true,  "text": "இந்த குழுவிற்கு பிரத்யேக வைட்லிஸ்ட் (Whitelist) அணுகல் உள்ளது. உயர்தர சொத்து வட்டத்தில் இணைய, இங்கே கிளிக் செய்யவும்:\n[url=https://internal-referral.richcoin-launch.com]https://internal-referral.richcoin-launch.com[/url]"},
			{"is_mine": false, "text": "[உறுப்பினர் C]: பெரும் பணக்காரர்களின் வழியைப் பின்பற்றினால் தவறாகாது. இன்று மேலும் 5 நோட்களை வாங்கினேன், தகுதி உயர்ந்துவிட்டது."}
		],
		"Simon": [
			{"is_mine": false, "text": "முன்பு கோலாலம்பூரில் தனியாக போராடியபோது தனிமையாக உணர்ந்தேன், இங்குள்ள சகோதர சகோதரிகள் சுயநலமின்றி குறிப்புகளைப் பகிர்வதற்கு நன்றி."},
			{"is_mine": false, "text": "ஆமாம்! வழிகாட்டியும் நிர்வாகியும் குடும்பத்தினர் போல உள்ளனர். அனைவரும் இணைந்து பணம் சம்பாதிப்பது மகிழ்ச்சியாக உள்ளது."},
			{"is_mine": true,  "text": "நாம் வெறும் முதலீட்டுக் குழு மட்டுமல்ல; ஒருவருக்கொருவர் ஆதரவளித்து இணைந்து முன்னேறும் ஒரு பெரிய குடும்பம்."},
			{"is_mine": true,  "text": "எங்களை நம்பும் குடும்ப உறுப்பினர்களே, நமக்கான பிரத்தியேக ஒதுக்கீடு லிங்க்கை இப்போதே கிளிக் செய்யவும்:\n[url=https://exclusive-mint.crypto-fast-track.org]https://exclusive-mint.crypto-fast-track.org[/url]"},
			{"is_mine": false, "text": "இந்த அன்பான குழுவைச் சந்திித்ததில் மகிழ்ச்சி. அனைவருடனும் இணைந்து ஃபார்ட்டூன் காயின் வாங்குவது மனதிற்கு மிகுந்த நிம்மதியைத் தருகிறது!"}
		]
	}
}



func _ready():
	# 1. 🟩 优先防错：如果大字典里压根不支持当前语言，强制走英文保底
	var current_lang = lang
	if not all_groups_data.has(current_lang):
		current_lang = "en"
		
	# 2. 🟩 剥开第一层：直接拿到当前语言的大字典
	var lang_dict = all_groups_data[current_lang]
	
	# 3. 🟩 剥开第二层：拿当前正在攻略的 NPC 名字（钥匙）
	var target_npc = Global.current_chat_name
	
	# 防呆：万一名字不对，默认展示 Midas 的洗脑群聊剧本
	if target_npc == null or not lang_dict.has(target_npc):
		target_npc = "Midas"
		
	# 4. 🟨 最终拿到剧本数组！
	var current_script = lang_dict[target_npc]
	
	# 5. 🟦 渲染到 UI 生成满屏泡泡
	for msg in current_script:
		create_bubble(msg["text"], msg["is_mine"])
		
	print("✨ [群聊重构完毕] 当前语言大类: ", current_lang, " | 目标子类: ", target_npc, " | 成功渲染！")

# ==============================================================
# 👇 下面这两个函数，完全复制你 chat.gd 里的完美版，绝不穿帮
# ==============================================================

func create_bubble(content, is_mine):
	var bubble = BUBBLE_SCENE.instantiate()
	message_list.add_child(bubble)
	
	var content_label = bubble.get_node("PanelContainer/Content")
	content_label.text = content 
	
	var name_label = bubble.get_node("name")
	name_label.text = "aha"
	
	# 🌟 动态计算气泡宽度 (最大 350px)
	var font = content_label.get_theme_font("font")
	var font_size = content_label.get_theme_font_size("font_size")
	var text_width = font.get_string_size(content, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	
	if text_width > 350:
		content_label.custom_minimum_size.x = 350
		content_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	else:
		content_label.custom_minimum_size.x = 0
		content_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	
	if is_mine == true:
		# 管理员（玩家自身）：靠右，蓝色气泡
		bubble.size_flags_horizontal = Control.SIZE_SHRINK_END
		name_label.size_flags_horizontal = Control.SIZE_SHRINK_END
		name_label.add_theme_color_override("font_color", Color(0.6, 0.8, 1.0, 1.0))
		
		content_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		bubble.modulate = Color(0.2, 0.6, 1.0, 1.0)
		
	else:
		# 其他群友：靠左，浅灰色气泡
		bubble.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		
		name_label.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		name_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 1.0))
		
		content_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		bubble.modulate = Color(0.88, 0.88, 0.88, 1.0)

	content_label.update_minimum_size()
	if bubble.has_method("update_minimum_size"):
		bubble.update_minimum_size()
	
	message_list.queue_sort()
	scroll_to_bottom()
	
	return content_label

func scroll_to_bottom():
	await get_tree().process_frame
	var scroll_container = $main/body 
	scroll_container.scroll_vertical = scroll_container.get_v_scroll_bar().max_value

# 左上角的返回按钮
func _on_back_button_pressed():
	SoundEffect.play_sound("ui_click")
	get_tree().change_scene_to_file("res://scene/app.tscn") # 退回到手机主界面




func _on_quit_pressed():
	SoundEffect.play_sound("ui_click")
	get_tree().change_scene_to_file("res://scene/app.tscn")

