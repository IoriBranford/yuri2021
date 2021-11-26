tool
extends EditorScenePostImport

func get_meshinstance(node):
	for child in node.get_children():
		if child is MeshInstance:
			return child
		var meshinstance = get_meshinstance(child)
		if meshinstance:
			return meshinstance
	return null
	
func post_import(scene):
	var meshinstance:MeshInstance = get_meshinstance(scene)
	if meshinstance:
		meshinstance.create_convex_collision()
		return meshinstance
	return scene
