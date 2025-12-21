class_name ValidationUtils
extends RefCounted

static func validate_scene_script(scene: PackedScene, expectedClass: Script)->String:
	if not expectedClass:
		return "Scene is null in validate call!"
	
	if not scene:
		return "Class is null in validate call!"
	
	var state := scene.get_state()
	# The root node is typically at index 0
	for i in range(state.get_node_property_count(0)):
		var prop_name := state.get_node_property_name(0, i)
		if prop_name == "script":
			var property_value: Variant = state.get_node_property_value(0, i)
			if property_value is Script:
				var attached_script := property_value as Script
				# Check for a specific class_name or script path
				if attached_script == expectedClass or attached_script.get_base_script() == expectedClass:
					return ""
				return "Assigned scene root has an incorrect script!"
	return "Assigned scene root has no script attached."
