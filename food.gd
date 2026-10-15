class_name Food
var name: String
var is_healthy: bool
var description: String
var icon_texture: Texture2D

func _init(p_name: String, p_is_healthy: bool, p_description: String = "", p_icon_path: String = "") -> void:
	self.name = p_name
	self.is_healthy = p_is_healthy
	self.description = p_description
	if p_icon_path != "" and ResourceLoader.exists(p_icon_path):
		self.icon_texture = load(p_icon_path)
