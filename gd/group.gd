# group_chat.gd

extends Control

const with_name_bubble = preload("res://scene/group_chat_bubble.tscn")
const without_name_bubble = preload("res://scene/MessageBubble.tscn")

@onready var message_list = $main/body/message_list # 确保路径和你的场景一致

var lang = Global.current_language
var last_speaker = ""

# ==============================================================
# 🌟 强哥多角色全自动染色系统
# ==============================================================
# 1. 动态颜色映射字典（用来锁死每个人的颜色）
var speaker_colors := {}

# 2. 预设的高颜值【浅色系调色盘】池子（保证字体是黑色时依然清晰、柔和）
# 我们用 RGB (0.85 到 0.95 之间) 调出非常小清新的马卡龙淡色系
var pastel_color_pool := [
	Color(0.92, 0.90, 0.98, 1.0), # 淡迷迭紫
	Color(0.88, 0.94, 0.95, 1.0), # 淡薄荷青
	Color(0.96, 0.93, 0.88, 1.0), # 淡燕麦象牙白
	Color(0.95, 0.90, 0.90, 1.0), # 淡茱萸粉
	Color(0.91, 0.95, 0.91, 1.0), # 淡抹茶绿
	Color(0.96, 0.95, 0.88, 1.0), # 淡奶油黄
	Color(0.90, 0.93, 0.96, 1.0)  # 淡冰川蓝
]
# ==============================================================


var all_groups_data = {
	"ch": {
		"Midas": [
			{"is_mine": false, "speaker": "群主", "text": "来跟各位新加入群组的人介绍一下，我们团队推出了新的加密货币，叫“发财币”！"},
			{"is_mine": false, "speaker": "群主", "text": "现在发财币还是内部销售没上线，现在买绝对是全网最低价！"},
			{"is_mine": false, "speaker": "群主", "text": "预计一上线最少暴涨10倍！到时候一抛售就是10倍的超高回报率！"},
			{"is_mine": false, "speaker": "群主", "text": "我自己也砸了重本等发财，有钱大家一起赚！"},
			{"is_mine": false, "speaker": "群主", "text": "只要有兴趣的人，都可以点击群置顶的链接来购买我们的发财币。"},
			{"is_mine": false, "speaker": "Vincent", "text": "10倍回报率看着真香啊！算我一个，我也要买！"},
			{"is_mine": false, "speaker": "Aidan", "text": "这么高的回报率绝对不能错过，错过等几年啊！"},
			{"is_mine": false, "speaker": "Lucas", "text": "我就等这个还房贷了，说不定翻倍了还能提一辆梦中情车！"}
		],
		"Lily": [
			{"is_mine": false, "speaker": "Kelvin", "text": "啊，这个发财币看着是真的不错，回报率这么高。"},
			{"is_mine": false, "speaker": "Kelvin", "text": "不过这东西这么火，会不会晚一步就直接被抢完了啊？"},
			{"is_mine": false, "speaker": "群主", "text": "你问到点上了，这个内部销售的名额现在只剩下10个名额了！"},
			{"is_mine": false, "speaker": "群主", "text": "所以各位千万要快！犹豫就会败北！现在买，之后你我都是有钱人！"},
			{"is_mine": false, "speaker": "Jolim", "text": "蛤！名额这么快就要完了吗？！那我也不等了，直接买！"},
			{"is_mine": false, "speaker": "Angie", "text": "天啊只剩一点了？帮我留一个名额，我现在就去转账！"},
			{"is_mine": false, "speaker": "Adam", "text": "我也要买！别抢完啊，我正在点链接了！"}
		],
		"Jane": [
			{"is_mine": false, "speaker": "群主", "text": "非常感谢大家的支持，刚刚的最后10个名额已经被一抢而空了！"},
			{"is_mine": false, "speaker": "群主", "text": "可是为了照顾社区热度，我们团队紧急开会决定破例再开放100个名额！！"},
			{"is_mine": false, "speaker": "群主", "text": "虽然贵了5%，但再不抢就真的要等上线交易所了！到时候就不是低价了！"},
			{"is_mine": false, "speaker": "Marcus", "text": "哇！这么多人都买了吗？！我才刚进来群罢了。"},
			{"is_mine": false, "speaker": "Marcus", "text": "原本还以为说这东西应该没人会买，看来是我见识短了。"},
			{"is_mine": false, "speaker": "Marcus", "text": "看到这么多人都买了，我也想不错过这个机会了。"},
			{"is_mine": false, "speaker": "Chloe", "text": "我也一样，看到这么多人都买了，我也感觉没什么好怕的了。"},
			{"is_mine": false, "speaker": "Chloe", "text": "这么多人都买了肯定没问题，我也跟上！"}
		],
		"Stanley": [
			{"is_mine": false, "speaker": "群主", "text": "说的没错！而且偷偷告诉各位，其实世界首富马X克也买了我们的发财币！"},
			{"is_mine": false, "speaker": "Eric", "text": "真的假的！？那个马X克也买了这个发财币！！"},
			{"is_mine": false, "speaker": "Jason", "text": "这个发财币居然这么厉害吗！连首富都会来买，牛逼啊！"},
			{"is_mine": false, "speaker": "Joey", "text": "马X克的投资眼光肯定错不了！我不观望了，直接买！"},
			{"is_mine": false, "speaker": "Jolim", "text": "幸好刚刚有抢到最低价钱的名额，首富都来买了，这次想不发财都难啊。"},
			{"is_mine": false, "speaker": "Angie", "text": "真的！幸好我刚才手快抢到了，跟着首富绝对稳赚！"},
			{"is_mine": false, "speaker": "Adam", "text": "太险了，幸好我也抢到了！现在简直安全感满满！"}
		],
		"Simon": [
			{"is_mine": false, "speaker": "Simon", "text": "各位好啊，我是新加入的新人，想来认识朋友。"},
			{"is_mine": false, "speaker": "Eric", "text": "认真的吗？来这个群是为了认识朋友？"},
			{"is_mine": false, "speaker": "Eric", "text": "有发财的机会他不香吗，认识朋友哪有发财重要啊兄弟。"},
			{"is_mine": false, "speaker": "Aidan", "text": "就是啊，还不如点击置顶的链接一起发财，赚钱才是硬道理。"},
			{"is_mine": false, "speaker": "Chloe", "text": "对啊新来的，听句劝，跟着大家一起买发财币才是正经事！"}
		]
	},
	"en": {
		"Midas": [
			{"is_mine": false, "speaker": "Admin", "text": "Let me introduce to the newcomers, our team launched a new crypto called Richcoin!"},
			{"is_mine": false, "speaker": "Admin", "text": "It's still in internal presale. Buying now is the absolute lowest price!"},
			{"is_mine": false, "speaker": "Admin", "text": "Expected to surge 10x once listed! You'll get a 10x ROI when you sell!"},
			{"is_mine": false, "speaker": "Admin", "text": "I've invested heavily myself. Let's make money and get rich together!"},
			{"is_mine": false, "speaker": "Admin", "text": "If you're interested, just click the pinned link to buy our Richcoin."},
			{"is_mine": false, "speaker": "Vincent", "text": "A 10x return looks amazing! Count me in, I want to buy!"},
			{"is_mine": false, "speaker": "Aidan", "text": "Can't miss such high returns. If we miss this, we wait years!"},
			{"is_mine": false, "speaker": "Lucas", "text": "I'm counting on this for my mortgage, maybe even buy my dream car!"}
		],
		"Lily": [
			{"is_mine": false, "speaker": "Kelvin", "text": "Ah, this Richcoin really looks good with such a high ROI."},
			{"is_mine": false, "speaker": "Kelvin", "text": "But will it be sold out directly if I'm just a bit slower?"},
			{"is_mine": false, "speaker": "Admin", "text": "Spot on! There are only 10 spots left for this internal sale!"},
			{"is_mine": false, "speaker": "Admin", "text": "So hurry up! Hesitation means losing! Buy now, be rich later!"},
			{"is_mine": false, "speaker": "Jolim", "text": "What! Spots running out so fast?! I'm not waiting, buying now!"},
			{"is_mine": false, "speaker": "Angie", "text": "Omg only a few left? Save me a spot, I'm transferring now!"},
			{"is_mine": false, "speaker": "Adam", "text": "I want to buy too! Don't sell out, I'm clicking the link!"}
		],
		"Jane": [
			{"is_mine": false, "speaker": "Admin", "text": "Thanks for your trust. The last 10 spots were just sold out!"},
			{"is_mine": false, "speaker": "Admin", "text": "But to keep the hype, we had an emergency meeting and opened 100 more spots!!"},
			{"is_mine": false, "speaker": "Admin", "text": "It's 5% pricier, but it's your last chance before it hits the exchange!"},
			{"is_mine": false, "speaker": "Marcus", "text": "Wow! So many people bought it?! I just joined the group."},
			{"is_mine": false, "speaker": "Marcus", "text": "I originally thought no one would buy this thing."},
			{"is_mine": false, "speaker": "Marcus", "text": "Seeing so many buyers, I don't want to miss this chance anymore."},
			{"is_mine": false, "speaker": "Chloe", "text": "Same here. Seeing so many buyers makes me feel there's nothing to fear."},
			{"is_mine": false, "speaker": "Chloe", "text": "With so many people buying, it must be fine. I'm in too!"}
		],
		"Stanley": [
			{"is_mine": false, "speaker": "Admin", "text": "Exactly! And a secret insider tip: the world's richest man M**k also bought Richcoin!"},
			{"is_mine": false, "speaker": "Eric", "text": "For real!? M**k bought this Richcoin too!!"},
			{"is_mine": false, "speaker": "Jason", "text": "Is this Richcoin really that powerful! Even the richest man is buying."},
			{"is_mine": false, "speaker": "Joey", "text": "M**k's investment vision is never wrong! No more waiting, I'm buying!"},
			{"is_mine": false, "speaker": "Jolim", "text": "Glad I grabbed the lowest price earlier. With M**k in, we'll definitely get rich."},
			{"is_mine": false, "speaker": "Angie", "text": "So true! Glad I was fast enough. Following the richest man is guaranteed profit!"},
			{"is_mine": false, "speaker": "Adam", "text": "That was close, glad I bought it too! I feel so secure now!"}
		],
		"Simon": [
			{"is_mine": false, "speaker": "Simon", "text": "Hello everyone, I'm new here and just want to make some friends."},
			{"is_mine": false, "speaker": "Eric", "text": "Seriously? You came to this group just to make friends?"},
			{"is_mine": false, "speaker": "Eric", "text": "Isn't a chance to get rich better? Making friends isn't as important as money."},
			{"is_mine": false, "speaker": "Aidan", "text": "Exactly. You might as well click the pinned link and get rich with us."},
			{"is_mine": false, "speaker": "Chloe", "text": "Yeah newbie, take our advice, buying Richcoin with us is the real deal!"}
		]
	},
	"bm": {
		"Midas": [
			{"is_mine": false, "speaker": "Admin", "text": "Mari saya perkenalkan kpd ahli baru, team kami lancarkan kripto baru bernama Richcoin!"},
			{"is_mine": false, "speaker": "Admin", "text": "Masih dalam jualan dalaman. Beli sekarang dapat harga paling rendah!"},
			{"is_mine": false, "speaker": "Admin", "text": "Dijangka naik 10x ganda! Jual nanti confirm dapat pulangan 10x!"},
			{"is_mine": false, "speaker": "Admin", "text": "Saya sendiri dah labur banyak. Jom kita buat duit sama-sama!"},
			{"is_mine": false, "speaker": "Admin", "text": "Sesiapa berminat, boleh klik pautan yang dipinkan untuk beli Richcoin."},
			{"is_mine": false, "speaker": "Vincent", "text": "Pulangan 10x nampak gempak sangat! Nak join juga, saya nak beli!"},
			{"is_mine": false, "speaker": "Aidan", "text": "Pulangan tinggi macam ni tak boleh lepas. Rugi besar nanti!"},
			{"is_mine": false, "speaker": "Lucas", "text": "Harap boleh bayar loan rumah, silap-silap boleh beli kereta idaman!"}
		],
		"Lily": [
			{"is_mine": false, "speaker": "Kelvin", "text": "Ah, Richcoin ni memang nampak bagus, pulangan pun tinggi sangat."},
			{"is_mine": false, "speaker": "Kelvin", "text": "Tapi benda ni takkan habis dijual terus kalau lambat sikit?"},
			{"is_mine": false, "speaker": "Admin", "text": "Tepat sekali! Kuota jualan dalaman sekarang tinggal 10 slot sahaja!"},
			{"is_mine": false, "speaker": "Admin", "text": "Korang kena cepat! Teragak-agak akan rugi! Beli sekarang, nanti kita kaya!"},
			{"is_mine": false, "speaker": "Jolim", "text": "Hah! Kuota nak habis dah ke?! Saya tak tunggu dah, beli terus!"},
			{"is_mine": false, "speaker": "Angie", "text": "Biar betul tinggal sikit? Simpan satu slot, nak transfer sekarang!"},
			{"is_mine": false, "speaker": "Adam", "text": "Saya pun nak beli! Jangan bagi habis, tengah klik pautan ni!"}
		],
		"Jane": [
			{"is_mine": false, "speaker": "Admin", "text": "Terima kasih atas sokongan. 10 kuota terakhir tadi dah disapu bersih!"},
			{"is_mine": false, "speaker": "Admin", "text": "Demi kehangatan komuniti, team kami buka 100 kuota tambahan secara khas!!"},
			{"is_mine": false, "speaker": "Admin", "text": "Harga naik sikit 5%, tapi ini peluang terakhir sebelum masuk bursa!"},
			{"is_mine": false, "speaker": "Marcus", "text": "Wah! Ramainya yang beli?! Saya baru je masuk group ni."},
			{"is_mine": false, "speaker": "Marcus", "text": "Ingatkan takde orang yang akan beli benda ni pada mulanya."},
			{"is_mine": false, "speaker": "Marcus", "text": "Bila tengok ramai yang beli, saya pun tak nak lepaskan peluang ni."},
			{"is_mine": false, "speaker": "Chloe", "text": "Saya pun sama, nampak ramai yang dah beli, rasa tak takut dah."},
			{"is_mine": false, "speaker": "Chloe", "text": "Ramai dah beli mesti takde masalah punya. Saya pun nak beli!"}
		],
		"Stanley": [
			{"is_mine": false, "speaker": "Admin", "text": "Betul tu! Rahsia dalaman, orang terkaya dunia M**k pun beli Richcoin kita!"},
			{"is_mine": false, "speaker": "Eric", "text": "Biar betul!? M**k pun beli Richcoin ni!! Gila ah!"},
			{"is_mine": false, "speaker": "Jason", "text": "Hebat betul Richcoin ni! Sampai orang terkaya pun masuk beli."},
			{"is_mine": false, "speaker": "Joey", "text": "Pandangan pelaburan M**k takkan salah! Tak payah tunggu dah, beli terus!"},
			{"is_mine": false, "speaker": "Jolim", "text": "Nasib baik sempat grab harga murah tadi. M**k pun join, confirm kaya!"},
			{"is_mine": false, "speaker": "Angie", "text": "Betul! Nasib baik cepat beli tadi. Ikut M**k memang confirm untung!"},
			{"is_mine": false, "speaker": "Adam", "text": "Nasib baik saya pun dah beli! Rasa selamat dan yakin gila sekarang!"}
		],
		"Simon": [
			{"is_mine": false, "speaker": "Simon", "text": "Hai semua, saya orang baru kat sini, masuk ni nak cari kawan je."},
			{"is_mine": false, "speaker": "Eric", "text": "Seriuslah? Masuk group ni semata-mata nak cari kawan?"},
			{"is_mine": false, "speaker": "Eric", "text": "Peluang kaya depan mata kot. Cari kawan tak sepenting buat duit."},
			{"is_mine": false, "speaker": "Aidan", "text": "Betul tu, baik klik pautan kat atas lepastu kita kaya sama-sama."},
			{"is_mine": false, "speaker": "Chloe", "text": "Yalah orang baru, dengar nasihat ni, beli Richcoin dengan kitorang lagi bagus!"}
		]
	},
	"bt": {
		"Midas": [
			{"is_mine": false, "speaker": "Admin", "text": "புதியவர்களுக்கு அறிமுகம், எங்கள் குழு Richcoin என்ற புதிய கிரிப்டோவை வெளியிட்டுள்ளது!"},
			{"is_mine": false, "speaker": "Admin", "text": "இதை இன்னும் ஆரம்ப கட்ட விற்பனையில்தான் உள்ளது. இப்போது வாங்குவதுதான் மிக குறைந்த விலை!"},
			{"is_mine": false, "speaker": "Admin", "text": "இது வந்ததும் 10 மடங்கு உயரும்! விற்றால் 10 மடங்கு லாபம்!"},
			{"is_mine": false, "speaker": "Admin", "text": "நானும் அதிக முதலீடு செய்துள்ளேன். வாருங்கள் ஒன்றாக பணம் சம்பாதிப்போம்!"},
			{"is_mine": false, "speaker": "Admin", "text": "ஆர்வம் உள்ளவர்கள், பின் செய்யப்பட்ட இணைப்பை கிளிக் செய்து Richcoin வாங்கலாம்."},
			{"is_mine": false, "speaker": "Vincent", "text": "10 மடங்கு லாபம் அருமையாக உள்ளது! நானும் வாங்க விரும்புகிறேன்!"},
			{"is_mine": false, "speaker": "Aidan", "text": "இதை தவறவிட முடியாது. தவறவிட்டால் பல வருடங்கள் காத்திருக்க வேண்டும்!"},
			{"is_mine": false, "speaker": "Lucas", "text": "இதை வைத்து வீட்டுக்கடன் அடைத்து, கனவு காரையும் வாங்கலாம் என நம்புகிறேன்!"}
		],
		"Lily": [
			{"is_mine": false, "speaker": "Kelvin", "text": "ஆஹா, இந்த Richcoin பார்ப்பதற்கு நன்றாக உள்ளது, லாபமும் மிக அதிகம்."},
			{"is_mine": false, "speaker": "Kelvin", "text": "ஆனால் கொஞ்சம் தாமதித்தால் இது சீக்கிரம் விற்றுத் தீர்ந்துவிடுமா?"},
			{"is_mine": false, "speaker": "Admin", "text": "சரியான கேள்வி! இந்த விற்பனையில் இப்போது 10 இடங்கள் மட்டுமே மீதமுள்ளன!"},
			{"is_mine": false, "speaker": "Admin", "text": "எனவே விரைந்து செயல்படுங்கள்! தயங்கினால் நஷ்டம்! இப்போது வாங்குங்கள்!"},
			{"is_mine": false, "speaker": "Jolim", "text": "என்ன! இடங்கள் சீக்கிரம் முடிகிறதா?! நான் இப்போதே வாங்குகிறேன்!"},
			{"is_mine": false, "speaker": "Angie", "text": "கொஞ்சம் தான் உள்ளதா? எனக்கும் ஒரு இடம் வேண்டும், பணம் அனுப்புகிறேன்!"},
			{"is_mine": false, "speaker": "Adam", "text": "நானும் வாங்க வேண்டும்! தீர்ந்துவிட வேண்டாம், லிங்கை கிளிக் செய்கிறேன்!"}
		],
		"Jane": [
			{"is_mine": false, "speaker": "Admin", "text": "உங்கள் ஆதரவுக்கு நன்றி, முந்தைய 10 இடங்களும் விற்றுத் தீர்ந்துவிட்டன!"},
			{"is_mine": false, "speaker": "Admin", "text": "ஆனால் குழுவின் ஆர்வத்திற்காக, மேலும் 100 இடங்களை திறந்துள்ளோம்!!"},
			{"is_mine": false, "speaker": "Admin", "text": "விலை 5% அதிகம் என்றாலும், இதுவே உங்கள் கடைசி வாய்ப்பு!"},
			{"is_mine": false, "speaker": "Marcus", "text": "வாவ்! இவ்வளவு பேர் வாங்கிவிட்டார்களா?! நான் இப்போதுதான் சேர்ந்தேன்."},
			{"is_mine": false, "speaker": "Marcus", "text": "ஆரம்பத்தில் இதை யாரும் வாங்க மாட்டார்கள் என்று நினைத்தேன்."},
			{"is_mine": false, "speaker": "Marcus", "text": "இவ்வளவு பேர் வாங்குவதைப் பார்த்தால், வாய்ப்பை தவறவிட விரும்பவில்லை."},
			{"is_mine": false, "speaker": "Chloe", "text": "நானும் அப்படித்தான், இத்தனை பேர் வாங்கியதைப் பார்த்தால் பயமாக இல்லை."},
			{"is_mine": false, "speaker": "Chloe", "text": "நிச்சயமாக எந்தப் பிரச்சனையும் இருக்காது. நானும் வாங்குகிறேன்!"}
		],
		"Stanley": [
			{"is_mine": false, "speaker": "Admin", "text": "உண்மைதான்! ரகசிய செய்தி: உலகின் பணக்காரரான M**k-உம் Richcoinவாங்கியுள்ளார்!"},
			{"is_mine": false, "speaker": "Eric", "text": "நிஜமாகவா!? அந்த M**k-உம் இந்த Richcoin-ஐ வாங்கியுள்ளாரா!!"},
			{"is_mine": false, "speaker": "Jason", "text": "இந்த Richcoin இவ்வளவு பெரியதா! உலகப் பணக்காரர் கூட வாங்குகிறார்."},
			{"is_mine": false, "speaker": "Joey", "text": "M**k-இன் முதலீட்டுப் பார்வை தவறாகாது! நான் நேரடியாக வாங்குகிறேன்!"},
			{"is_mine": false, "speaker": "Jolim", "text": "குறைந்த விலையில் வாங்கியது நல்லது. இப்போது லாபம் உறுதி!"},
			{"is_mine": false, "speaker": "Angie", "text": "உண்மைதான்! அவரைப் பின்தொடர்வது எப்பொழுதும் லாபமே!"},
			{"is_mine": false, "speaker": "Adam", "text": "நல்லவேளையாக நானும் வாங்கிவிட்டேன்! மிகவும் பாதுகாப்பாக உணர்கிறேன்!"}
		],
		"Simon": [
			{"is_mine": false, "speaker": "Simon", "text": "வணக்கம், நான் இங்கு புதியவன், நண்பர்களை உருவாக்கவே இங்கு வந்தேன்."},
			{"is_mine": false, "speaker": "Eric", "text": "நிஜமாகவா? நண்பர்களை உருவாக்கவா இந்த குழுவிற்கு வந்தீர்கள்?"},
			{"is_mine": false, "speaker": "Eric", "text": "பணக்காரராகும் வாய்ப்பு இருக்கும்போது, நண்பர்கள் முக்கியமா?"},
			{"is_mine": false, "speaker": "Aidan", "text": "உண்மைதான், மேலே உள்ள லிங்கை கிளிக் செய்து பணக்காரராகுங்கள்."},
			{"is_mine": false, "speaker": "Chloe", "text": "ஆமாம் புதியவரே, எங்கள் பேச்சைக் கேளுங்கள், Richcoin வாங்குவதுதான் சிறந்தது!"}
		]
	}
}




func _ready():
	# 🟩 全局紧贴设置：让所有气泡默认死死贴合在一起（去除 VBoxContainer 的阻力）
	message_list.add_theme_constant_override("separation", 2)
	
	# 1. 优先防错：判断语言
	var current_lang = lang
	if not all_groups_data.has(current_lang):
		current_lang = "en"
	var lang_dict = all_groups_data[current_lang]
	
	# 2. 🌟 核心设计：定义固定的关卡推进顺序
	var npc_order = ["Midas", "Lily", "Jane", "Stanley", "Simon"]
	
	# 3. 抓取玩家当前正在攻略的目标
	var target_npc = Global.current_chat_name
	if target_npc == null or not lang_dict.has(target_npc):
		target_npc = "Midas"
		
	# 4. 🌟 动态计算截止到当前关卡的历史层级数量
	var target_index = npc_order.find(target_npc)
	if target_index == -1:
		target_index = 0 
		
	print("📂 [群聊追加系统] 当前目标: ", target_npc, " | 历史关卡数: ", target_index + 1)
	
	# 5. 🔄 嵌套循环：按时序加载所有的对话剧本
	for i in range(target_index + 1):
		var current_load_npc = npc_order[i]
		
		if lang_dict.has(current_load_npc):
			var current_script = lang_dict[current_load_npc]
			
			for msg in current_script:
				create_bubble(msg["text"], msg["is_mine"], msg["speaker"])
				
	# 6. 全部加载完后滚动到底部
	scroll_to_bottom()
	print("✨ [群聊历史追加完毕] 已完美无缝连接旧消息！")


func create_bubble(content, is_mine, speaker):
	var bubble
	var is_same_person = (speaker == last_speaker and speaker != "")
	
	# ==============================================================
	# 🌟 绝杀：透明垫脚石法 (Spacer)
	# 如果是换了新人说话，且聊天记录里已经有信息了，塞一个 15 像素高的隐形方块拉开间距！
	# ==============================================================
	if not is_same_person and message_list.get_child_count() > 0:
		var spacer = Control.new()
		spacer.custom_minimum_size.y = 15 
		message_list.add_child(spacer)
	
	if is_same_person:
		# 同一个人连续说话：直接用没有名字标签的私聊气泡！
		bubble = without_name_bubble.instantiate()
	else:
		# 新换了一个人说话：用带有名字标签的群聊气泡！
		bubble = with_name_bubble.instantiate()
		
	message_list.add_child(bubble)
	
	# 更新上一个发言人
	last_speaker = speaker
	
	var content_label 
	
	if is_same_person:
		content_label = bubble.get_node("Content") 
	else:
		content_label = bubble.get_node("PanelContainer/Content")
	
	content_label.text = content 
	
	if not is_same_person:
		var name_label = bubble.get_node("name")
		name_label.text = speaker
		
		# 控制名字的对齐
		if is_mine == true:
			name_label.size_flags_horizontal = Control.SIZE_SHRINK_END
			name_label.add_theme_color_override("font_color", Color(0.6, 0.8, 1.0, 1.0))
		else:
			name_label.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
			name_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 1.0))
	
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
	
	# ==============================================================
	# 🌟 核心调色系统修改：多角色浅色系分配与同人沿用逻辑
	# ==============================================================
	var assigned_color: Color
	
	if is_mine == true:
		# 玩家自身（或者大管理员）：保持统一帅气的科技蓝（浅亮色调）
		assigned_color = Color(0.2, 0.6, 1.0, 1.0)
	else:
		# 如果是其他群友发言：
		if speaker_colors.has(speaker):
			# A. 如果这个人在字典里已经分配过颜色了，直接沿用以前的专属色
			assigned_color = speaker_colors[speaker]
		else:
			# B. 如果这是一个全新的人开口说话：
			if pastel_color_pool.size() > 0:
				# 还有富余的独立颜色，直接从池子里【弹出（Pop）】一个给他绑定
				assigned_color = pastel_color_pool.pop_front()
			else:
				# 万一池子里的 7 种马卡龙浅色全被抢光了，给一个高雅的淡灰色保底
				assigned_color = Color(0.88, 0.88, 0.88, 1.0)
			
			# 存进映射字典里，锁死这个名字和颜色的关系
			speaker_colors[speaker] = assigned_color
	
	# 将决定好的浅色系颜色，直接赋予当前实例化的气泡背景！
	bubble.modulate = assigned_color
	# ==============================================================
	
	if is_mine == true:
		bubble.size_flags_horizontal = Control.SIZE_SHRINK_END
		content_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	else:
		bubble.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		content_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT

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
	get_tree().change_scene_to_file("res://scene/app.tscn") 

func _on_quit_pressed():
	SoundEffect.play_sound("ui_click")
	get_tree().change_scene_to_file("res://scene/app.tscn")
