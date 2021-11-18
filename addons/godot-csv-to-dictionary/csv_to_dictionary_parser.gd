extends Node


func parse(
	file_path: String,
	id_column: String = "id",
	delimiter: String = ","
) -> Dictionary:
	var file: File = File.new()
	file.open(file_path, File.READ)

	var dict_data: Dictionary = {}

	var line_index: int = -1
	var column_headers: PoolStringArray
	while not file.eof_reached():
		line_index += 1
		var line: PoolStringArray = file.get_csv_line(delimiter)

		if line_index == 0:
			column_headers = line
		else:
			var entry: Dictionary = {}
			for column_index in column_headers.size():
				var value = line[column_index]

				# Detect bools.
				if value is String:
					var value_lower: String = value.to_lower()
					if value_lower == "true":
						value = true
					elif value_lower == "false":
						value = false

				entry[column_headers[column_index]]	= value
				if column_headers[column_index] == id_column:
					dict_data[entry[id_column]] = entry

	file.close()

	return dict_data
