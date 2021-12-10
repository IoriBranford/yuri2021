tool
extends "res://addons/dialogic/Editor/Events/Parts/EventPart.gd"

onready var selector:MenuButton = $Selector
onready var popup_menu:PopupMenu = selector.get_popup()
var popup_menu_dirty = true

func _ready():
	selector.connect("about_to_show", self, "_on_Selector_about_to_show")
	popup_menu.connect("index_pressed", self, "_on_popup_menu_index_pressed")

func refresh_popup_menu():
	if !popup_menu_dirty:
		return
	if editor_reference:
		var timeline = editor_reference.get_node("MainPanel/TimelineEditor/TimelineArea/TimeLine")
		if timeline:
			popup_menu_dirty = false
			popup_menu.clear()
			var events = timeline.get_children()
			for event in events:
				var event_data = event.event_data
				if event_data && event_data["event_id"] == "jump_point":
					var jump_point_id = event_data["jump_point_id"]
					popup_menu.add_item(jump_point_id)

 # called by the event block
func load_data(data:Dictionary):
	.load_data(data)
	popup_menu_dirty = true
	var jump_target_id = data.get("jump_target_id")
	selector.text = jump_target_id if jump_target_id else "Select jump target"

 # has to return the wanted preview, only useful for body parts
func get_preview():
	return ''

func _on_Selector_about_to_show():
	refresh_popup_menu()

func _on_popup_menu_index_pressed(i):
	var jump_target_id = popup_menu.get_item_text(i)
	selector.text = jump_target_id
	event_data["jump_target_id"] = jump_target_id
	data_changed()
