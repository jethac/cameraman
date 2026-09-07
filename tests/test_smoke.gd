extends GutTest

func test_smoke() -> void:
	assert_true(true)

func test_all_addon_scripts_are_tools() -> void:
	_assert_tool_scripts("res://addons/cameraman")

func _assert_tool_scripts(path: String) -> void:
	var directory: DirAccess = DirAccess.open(path)
	assert_not_null(directory, "Could not open %s" % path)
	if directory == null:
		return
	directory.list_dir_begin()
	while true:
		var entry: String = directory.get_next()
		if entry.is_empty():
			break
		if entry == "." or entry == "..":
			continue
		var entry_path: String = path.path_join(entry)
		if directory.current_is_dir():
			_assert_tool_scripts(entry_path)
		elif entry.ends_with(".gd"):
			var source: FileAccess = FileAccess.open(entry_path, FileAccess.READ)
			assert_not_null(source, "Could not read %s" % entry_path)
			if source != null:
				assert_eq(source.get_line(), "@tool", entry_path)
				source.close()
	directory.list_dir_end()
