extends Resource
class_name Item

enum ItemType {
	CONVEYOR,
	SCANNER
}

@export var item_name: String
@export_multiline var item_description: String
@export var item_icon: Texture
@export var item_price: String
@export var item_id: String
@export var item_type: ItemType
@export var item_unlock_level: int
