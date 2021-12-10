extends Node


func handle_event(event_data, dialog_node):
	## if you want to stop the user from progressing while this even is handled
	#dialog_node.waiting = true

	var dialog_events = dialog_node.dialog_script['events']
	var jump_target_id = event_data["jump_target_id"]
	for i in range(0, len(dialog_events)):
		var other_data = dialog_events[i]
		if other_data.get("event_id") == "jump_point":
			if other_data["jump_point_id"] == jump_target_id:
				dialog_node._load_event_at_index(i)
				return

	# once you want to continue with the next event
	dialog_node._load_next_event()
	# dialog_node.waiting = false
