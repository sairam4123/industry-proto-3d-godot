extends Node

var items = {}

func _ready() -> void:
	var _items = {}
	var dir_access = DirAccess.open("res://resources/tiles")
	for file in dir_access.get_files():
		var item_file = dir_access.get_current_dir().path_join(file)
		var item = load(item_file.rstrip(".remap"))
		if not item:
			prints("Loading failed item:", item, "dir:", item_file)
		_items[item.item_id] = item
	
	var _item_list = _items.values().duplicate()
	_item_list.sort_custom(_sorter)
	for _item in _item_list:
		items[_item.item_id] = _item

func _sorter(a: Item, b: Item):
	if a.item_type == b.item_type:
		return a.item_unlock_level < b.item_unlock_level
	else:
		return a.item_type < b.item_type
