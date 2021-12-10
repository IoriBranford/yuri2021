tool
extends "res://addons/dialogic/Editor/Events/Parts/EventPart.gd"

onready var selector:MenuButton = $Selector
onready var popup_menu:PopupMenu = selector.get_popup()

func _ready():
	popup_menu.connect("index_pressed", self, "_on_popup_menu_index_pressed")

 # called by the event block
func load_data(data:Dictionary):
	.load_data(data)
	
	if editor_reference:
		var timeline = editor_reference.get_node("MainPanel/TimelineEditor/TimelineArea/TimeLine")
		if timeline:
			popup_menu.clear()
			var events = timeline.get_children()
			var jump_target_id = data.get("jump_target_id")
			for event in events:
				var event_data = event.event_data
				if event_data && event_data["event_id"] == "jump_point":
					var jump_point_id = event_data["jump_point_id"]
					popup_menu.add_item(jump_point_id)
					if jump_point_id == jump_target_id:
						selector.text = jump_point_id

 # has to return the wanted preview, only useful for body parts
func get_preview():
	return ''

func _on_popup_menu_index_pressed(i):
	var jump_target_id = popup_menu.get_item_text(i)
	selector.text = jump_target_id
	event_data["jump_target_id"] = jump_target_id
	data_changed()
