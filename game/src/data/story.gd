class_name Story
extends RefCounted
## Порядок глав и кнопки ливта.

const CHAPTERS := [
	["dorm", "Общага"], ["murino", "Мурино"], ["milk", "Село Молочное"], ["myt", "Мытищи"],
	["banya", "Банька"], ["jmur", "Жмурино"], ["final", "Первый этаж"],
]
## уровни, где лежат кнопки ливта: [уровень, предмет, название направления]
const BUTTONS := [["milk", "btn1", "Село Молочное"], ["myt", "btn2", "Мытищи"], ["banya", "btn3", "Банька"], ["jmur", "btn4", "Жмурино"]]


static func buttons_have() -> int:
	var n := 0
	for b in BUTTONS:
		if G.has(b[1]):
			n += 1
	return n


static func title_of(id: String) -> String:
	for c in CHAPTERS:
		if c[0] == id:
			return c[1]
	return id


static func mark_done(id: String) -> void:
	var d: Array = G.save.get("done", [])
	if not d.has(id):
		d.append(id)
		G.save["done"] = d
