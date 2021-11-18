tool
extends EditorPlugin


func _enter_tree() -> void:
	add_autoload_singleton(
		"CsvToDictionaryParser",
		"res://addons/godot-csv-to-dictionary/csv_to_dictionary_parser.gd"
	)


func _exit_tree() -> void:
	remove_autoload_singleton("CsvToDictionaryParser")
