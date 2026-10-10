class_name DevConsole
extends CanvasLayer

# หน้าต่างพิมพ์คำสั่งลับสำหรับนักพัฒนา: กด ` (ปุ่มซ้ายเลข 1) หรือ F1 เปิด/ปิด, Esc ปิด
# เปิดอยู่ = หยุดเกม (get_tree().paused) / คำสั่งลงทะเบียนจาก main.gd ด้วย register() เช่น /day 3
# ข้อความเป็นภาษาอังกฤษ (ฟอนต์ไม่มีอักษรไทย)

const MAX_LINES := 6
const PANEL_H := 76.0
const STAY_OPEN := ["help", "clear"]   # คำสั่งที่ไม่ปิด console หลังรัน (คำสั่งอื่นปิดก่อนรัน ให้เกมไม่ถูกหยุดค้าง)

var _commands := {}   # ชื่อ → {"usage": String, "run": Callable(args: PackedStringArray) -> String}
var _panel: ColorRect
var _log: Label
var _field: LineEdit
var _lines: Array[String] = []
var _was_paused := false


func _ready() -> void:
	layer = 30   # เหนือทุกอย่าง รวมจอดำเปลี่ยนฉาก (20)
	process_mode = Node.PROCESS_MODE_ALWAYS

	_panel = ColorRect.new()
	_panel.color = Color(0, 0, 0, 0.85)
	_panel.anchor_right = 1.0
	_panel.offset_bottom = PANEL_H
	_panel.visible = false
	add_child(_panel)

	_log = Label.new()
	_log.position = Vector2(4, 4)
	_log.add_theme_font_size_override("font_size", 8)
	_log.add_theme_color_override("font_color", Color(0.7, 1.0, 0.7))
	_panel.add_child(_log)

	_field = LineEdit.new()
	_field.anchor_right = 1.0
	_field.offset_left = 2.0
	_field.offset_right = -2.0
	_field.offset_top = PANEL_H - 18.0
	_field.offset_bottom = PANEL_H - 2.0
	_field.placeholder_text = "/help"
	_field.add_theme_font_size_override("font_size", 8)
	_field.text_submitted.connect(_on_submit)
	_panel.add_child(_field)

	register("help", "/help  list commands", func(_a: PackedStringArray) -> String: return _help())
	register("clear", "/clear  clear this log", func(_a: PackedStringArray) -> String:
		_lines.clear()
		_refresh()
		return "")


# ลงทะเบียนคำสั่ง: run(args) คืนข้อความผลลัพธ์ ("" = ไม่พิมพ์อะไร)
func register(name: String, usage: String, run: Callable) -> void:
	_commands[name] = {"usage": usage, "run": run}


func is_open() -> bool:
	return _panel.visible


# ดักปุ่มเปิด/ปิดใน _input() (ก่อน LineEdit จะพิมพ์ ` ลงไป) / physical_keycode ใช้ได้แม้ตั้งคีย์บอร์ดภาษาไทย
func _input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	if key.physical_keycode == KEY_QUOTELEFT or key.keycode == KEY_F1:
		set_open(not is_open())
		get_viewport().set_input_as_handled()
	elif key.keycode == KEY_ESCAPE and is_open():
		set_open(false)
		get_viewport().set_input_as_handled()


func set_open(on: bool) -> void:
	if on == is_open():
		return
	_panel.visible = on
	if on:
		_was_paused = get_tree().paused
		get_tree().paused = true
		_field.clear()
		_field.grab_focus()
		_refresh()
	else:
		_field.release_focus()
		get_tree().paused = _was_paused


# รันคำสั่ง (รับทั้ง "/day 3" และ "day 3") / ปิด console ก่อนรัน เพื่อให้คำสั่งที่เปลี่ยนฉากเห็นเกมที่ไม่ได้หยุดอยู่
func run(text: String) -> String:
	var parts := text.strip_edges().trim_prefix("/").split(" ", false)
	if parts.is_empty():
		return ""
	var name := parts[0].to_lower()
	if not _commands.has(name):
		return "Unknown command: %s (try /help)" % name
	return _commands[name].run.call(parts.slice(1))


func _on_submit(text: String) -> void:
	_field.clear()
	if text.strip_edges() == "":
		return
	_print("> " + text)
	var name := text.strip_edges().trim_prefix("/").get_slice(" ", 0).to_lower()
	if not STAY_OPEN.has(name):
		set_open(false)
	var result := run(text)
	if result != "":
		_print(result)   # ผลของคำสั่งที่ปิด console ไปแล้ว เห็นตอนเปิดครั้งถัดไป


func _print(line: String) -> void:
	for l in line.split("\n"):
		_lines.append(l)
	while _lines.size() > MAX_LINES:
		_lines.pop_front()
	_refresh()


func _refresh() -> void:
	_log.text = "\n".join(_lines)


func _help() -> String:
	var out: Array[String] = []
	for name in _commands:
		out.append(_commands[name].usage)
	return "\n".join(out)
