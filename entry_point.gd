extends Node2D
class_name EntryPoint

func teleport(node):
	node.global_position = global_position
	if node.has_method("stop_navigating"): node.stop_navigating()
