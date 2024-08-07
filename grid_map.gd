extends Node3D
class_name LayeredGridMap

enum {
	FLOOR, # 0
	SCANNER_HIGH, # 1
	SCANNER_LOW, # 2
	ITEM_SOURCE, # 3
	ITEM_SINK, # 4
	CONVEYOR_STRIP_LONG, # 5
	CONVEYOR_STRIP, # 6
	CONVEYOR_LONG, # 7
	CONVEYOR, # 8
	CONVEYOR_STRIP_LONG_90,
	CONVEYOR_LONG_90,
}

var gmapping = {
	FLOOR: 0,
	# Scanners
	SCANNER_LOW: 1,
	SCANNER_HIGH: 0,
	ITEM_SINK: 3,
	ITEM_SOURCE: 2,
	
	# Conveyors
	CONVEYOR: 0,
	CONVEYOR_STRIP: 1,
	
	# Conveyors long
	CONVEYOR_LONG: 0,
	CONVEYOR_STRIP_LONG: 1,
	
	# Side
	CONVEYOR_LONG_90: 0,
	CONVEYOR_STRIP_LONG_90: 1,
}

var layers = {
	[0, 0]: FLOOR,
	[1, 1]: SCANNER_LOW,
	[1, 0]: SCANNER_HIGH,
	[1, 3]: ITEM_SINK,
	[1, 2]: ITEM_SOURCE,
	[2, 0]: CONVEYOR,
	[2, 1]: CONVEYOR_STRIP,
	[3, 0]: CONVEYOR_LONG,
	[3, 1]: CONVEYOR_STRIP_LONG,
	[4, 0]: CONVEYOR_LONG_90,
	[4, 1]: CONVEYOR_STRIP_LONG_90
}

var ories = {
	CONVEYOR_LONG_90: 10,
	CONVEYOR_STRIP_LONG_90: 10,
}

@onready var tile_mapping = {
	[FLOOR]: $Floor,
	[SCANNER_HIGH, SCANNER_LOW]: $Scanners,
	[ITEM_SINK, ITEM_SOURCE]: $Scanners,
	[CONVEYOR, CONVEYOR_STRIP]: $Conveyors,
	[CONVEYOR_LONG, CONVEYOR_STRIP_LONG]: $ConveyorsLarge,
	[CONVEYOR_LONG_90, CONVEYOR_STRIP_LONG_90]: $ConveyorsSide
}

var tiles = [] # Array[Array[Tile]]

func _get_gridmap(tile):
	for tile_map in tile_mapping:
		if tile in tile_map:
			return tile_mapping[tile_map]

func add_at(tile, pos, orientation):
	var gm: GridMap = _get_gridmap(tile)
	gm.set_cell_item(pos, gmapping[tile], ories.get(tile, orientation))

func remove(at_pos):
	var layer = 0
	for gm in get_children():
		if gm is GridMap and layer != 0:
			gm.set_cell_item(at_pos, -1, 0)
		layer += 1

func has_item_at(pos) -> bool:
	var flag = false
	for gm in get_children():
		if gm is GridMap and gm.get_cell_item(pos) != -1:
			flag = true
	return flag

func has_item_at_layers(pos, layers) -> bool:
	var flag = false
	var index = 0
	for gm in get_children():
		if gm is GridMap and gm.get_cell_item(pos) != -1 and index in layers:
			flag = true
		index += 1
	return flag
			

func get_pos_of_type(tile) -> Array[Vector3i]:
	var gm = _get_gridmap(tile)
	return gm.get_used_cells_by_item(gmapping[tile])

func get_used_cells():
	var cells = {}
	var index = 0
	for gm in get_children():
		if gm is GridMap:
			cells[index] = gm.get_used_cells()
			index += 1
	return cells

func get_cell_at(pos, layer):
	var index = 0
	for gm in get_children():
		if gm is GridMap and gm.get_cell_item(pos) != -1 and index == layer:
			return gm.get_cell_item(pos)
		index += 1
	return -1

func get_cell_orientation(pos, layer):
	var index = 0
	for gm in get_children():
		if gm is GridMap and gm.get_cell_item(pos) != -1 and index == layer:
			return gm.get_cell_item_orientation(pos)
		index += 1
	return -1

func get_adj_cells(pos, layer):
	var index = 0
	var offsets = [
		Vector3i(-1, 0, 0),
		Vector3i(1, 0, 0),
		Vector3i(0, 0, 1),
		Vector3i(0, 0, -1)
	]
	var res = []
	for gm in get_children():
		if gm is GridMap and index == layer:
			for offset in offsets:
				var final_pos = pos + offset
				var cell = gm.get_cell_item(final_pos)
				if cell == -1:
					res.append(null)
				else:
					res.append( layers[[index, cell]] )
		index += 1
	return res
