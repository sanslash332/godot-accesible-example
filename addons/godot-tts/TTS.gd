tool
extends Node

var TTS

var tts

func _ready():
    if OS.get_name() == "Server" or OS.has_feature("JavaScript"):
        return
    elif Engine.has_singleton("AndroidTTS"):
        tts = Engine.get_singleton("AndroidTTS")
    else:
        TTS  = preload("godot-tts.gdns")
    if TTS and (TTS.can_instance() or Engine.editor_hint):
        tts = TTS.new()
    else:
        print_debug("TTS not available!")

var javascript_rate = 50

func set_rate(rate):
    if rate < 0:
        rate = 0
    elif rate > 100:
        rate = 100
    if tts != null:
        tts.rate = rate
    elif OS.has_feature('JavaScript'):
        javascript_rate = rate

func get_rate():
    if tts != null:
        return tts.rate
    elif OS.has_feature('JavaScript'):
        return javascript_rate
    else:
        return 0

var rate setget set_rate, get_rate

func speak(text, interrupt := true):
    if tts != null:
        tts.speak(text, interrupt)
    elif OS.has_feature('JavaScript'):
        var scaled_rate: float
        if javascript_rate <= 50:
            scaled_rate = javascript_rate / 50.0
        else:
            scaled_rate = javascript_rate - 50
            scaled_rate = 1 + (scaled_rate / 5.0)
        var code = """
            let utterance = new SpeechSynthesisUtterance("%s")
            utterance.rate = %s
        """ % [text.replace("\n", " "), scaled_rate]
        if interrupt:
            code += """
                window.speechSynthesis.cancel()
            """
        code += "window.speechSynthesis.speak(utterance)"
        JavaScript.eval(code)
    else:
        print_debug("%s: %s" % [text, interrupt])

func stop():
    if tts != null:
        tts.stop()
    elif OS.has_feature('JavaScript'):
        JavaScript.eval("window.speechSynthesis.cancel()")

func get_is_rate_supported():
    if Engine.get_singleton("AndroidTTS"):
        return false
    elif OS.has_feature('JavaScript'):
        return true
    elif tts != null:
        return tts.is_rate_supported()
    else:
        return false

var is_rate_supported setget , get_is_rate_supported

func get_can_detect_screen_reader():
    if OS.get_name() == "Windows":
        return true
    else:
        return false

var can_detect_screen_reader setget , get_can_detect_screen_reader

func singular_or_plural(count, singular, plural):
    if count == 1:
        return singular
    else:
        return plural

func _exit_tree():
    if not tts or not TTS:
        return
    tts.free()
