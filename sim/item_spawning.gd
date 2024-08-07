extends Node3D

@export var layered_grid_map: LayeredGridMap
@export var small_box: PackedScene

var tile_rates = {
	CONVEYOR: 25,
	CONVEYOR_STRIP: 10,
}

enum {
	FLOOR,
	SCANNER_HIGH,
	SCANNER_LOW,
	ITEM_SOURCE,
	ITEM_SINK,
	CONVEYOR_STRIP_LONG,
	CONVEYOR_STRIP,
	CONVEYOR_LONG,
	CONVEYOR,
	CONVEYOR_STRIP_LONG_90,
	CONVEYOR_LONG_90,
}

var items = {} # Dict[(Vector3, int), int]
var rates = {}
var next_items = {}

var boxes = {}
var next_boxes = {}

func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.keycode == KEY_Y and event.pressed and !event.echo:
			print("------")
			step(1/16)
			print(items)

func _physics_process(delta: float) -> void:
	
	next_boxes = boxes.duplicate()
	next_items = items.duplicate()
	step(delta)
	
	for pos in next_items:
		var item = items.get(pos, 0)
		var next_item = next_items.get(pos, 0)
		var cell = layered_grid_map.layers.get([1, layered_grid_map.get_cell_at(pos, 1)], -1)
		var cell_ori = layered_grid_map.get_cell_orientation(pos, 2) # Rot of conveyors
		var conv = layered_grid_map.layers.get([2, layered_grid_map.get_cell_at(pos, 2)], -1)
		var offsets = {
			0: Vector3i(-1, 0, 0),     # D - 0
			16: Vector3i(0, 0, 1),     # W - 16
			10: Vector3i(1, 0, 0),     # A - 10
			22: Vector3i(0, 0, -1),    # S - 22
			-1: Vector3i(0, 0, 0)
		}
		var offset = offsets[cell_ori]
		if cell in [ITEM_SINK, ITEM_SOURCE]:
			if cell == ITEM_SOURCE:
				if (next_item - item) > 0:
					spawn_box(pos)
			
			if cell == ITEM_SINK:
				if (next_item - item) < 0:
					queue_free_box(pos)
					GameManager.add_xp(5)
			
		if conv in [CONVEYOR, CONVEYOR_STRIP]:
			var adj_pos = pos + offset
			var adj_item = items.get(adj_pos, -INF)
			var adj_next_item = next_items.get(adj_pos, -INF)
			
			if (adj_next_item - next_item) > 0 and (item - adj_item) > 0:
				move_box(pos, adj_pos)
			
	items = next_items.duplicate()
	boxes = next_boxes.duplicate()

func step(delta: float) -> void:
	var layers = layered_grid_map.get_used_cells()
	
	for layer in layers:
		if layer == 0:
			continue
		
		for pos in layers[layer]:
			var cell = layered_grid_map.get_cell_at(pos, layer)
			if cell == -1:
				continue
			
			var tile = layered_grid_map.layers[[layer, cell]]
			if tile == ITEM_SOURCE:
				if !rates.has([pos, layer]):
					rates[[pos, layer]] = 1
				
				if rates[[pos, layer]] % 60 == 0:
					var con_cell_item = layered_grid_map.get_cell_at(pos, 2)
					if con_cell_item == -1:
						rates[[pos, layer]] += 1
						continue
					
					if items.get(pos, 0) < 5:
						next_items[pos] = items.get(pos, 0) + 1
					rates[[pos, layer]] += 1
				else:
					rates[[pos, layer]] += 1
			
			if tile == ITEM_SINK:
				if !rates.has([pos, layer]):
					rates[[pos, layer]] = 1
				
				if rates[[pos, layer]] % 15 == 0:
					var con_cell_item = layered_grid_map.get_cell_at(pos, 2)
					if con_cell_item == -1:
						rates[[pos, layer]] += 1
						continue
					
					next_items[pos] = max(0, items.get(pos, 1) - 1) # Prevent negative values
					rates[[pos, layer]] += 1
				else:
					rates[[pos, layer]] += 1
			if tile in [CONVEYOR, CONVEYOR_STRIP]:
				var offsets = {
					0: Vector3i(-1, 0, 0),     # D - 0
					16: Vector3i(0, 0, 1),     # W - 16
					10: Vector3i(1, 0, 0),     # A - 10
					22: Vector3i(0, 0, -1),    # S - 22
				}
				
				if !rates.has([pos, layer]):
					rates[[pos, layer]] = 1
				if rates[[pos, layer]] % tile_rates[tile] != 0:
					rates[[pos, layer]] += 1
					continue

				var orientation = layered_grid_map.get_cell_orientation(pos, layer)
				var offset = offsets.get(orientation, Vector3(0, 0, 0)) # Default to (0, 0, 0) if orientation not found
				var final_pos = pos + offset
				if layered_grid_map.get_cell_at(final_pos, layer) != -1:
					if items.get(pos, 0) > 0 and items.get(final_pos, 0) < 1: # implement cloging
						next_items[pos] = max(items.get(pos, 1) - 1, 0)
						next_items[final_pos] = items.get(final_pos, 0) + 1
				rates[[pos, layer]] += 1


func spawn_box(at_pos: Vector3i):
	var small_box_node = small_box.instantiate()
	small_box_node.position = Vector3(at_pos.x+ 0.25, 0.8, at_pos.z)
	prints("Spawing box at", at_pos)
	next_boxes[at_pos] = small_box_node
	var prev_scale = small_box_node.scale
	small_box_node.scale = Vector3.ONE * 0.01
	get_parent().add_child(small_box_node)
	for i in range(10):
		small_box_node.scale = small_box_node.scale.lerp(prev_scale, 10 * get_physics_process_delta_time())
		await get_tree().process_frame

func queue_free_box(at_pos: Vector3i):
	var small_box_node = boxes.get(at_pos)
	if not small_box_node:
		return
	prints("Freeing box at", at_pos)
	next_boxes[at_pos] = null
	for i in range(10):
		small_box_node.scale = small_box_node.scale.lerp(Vector3.ZERO, 10 * get_physics_process_delta_time())
		await get_tree().process_frame
	small_box_node.queue_free()

func move_box(at_pos: Vector3i, to_pos: Vector3i):
	var small_box_node = boxes.get(Vector3i(at_pos))
	if not small_box_node:
		return
	next_boxes[at_pos] = null
	next_boxes[to_pos] = small_box_node
	prints("Moving box from:", at_pos, "to:", to_pos)
	for i in range(10):
		if not small_box_node:
			break
		small_box_node.position = small_box_node.position.lerp(Vector3(to_pos.x+ 0.25, 0.8, to_pos.z), 10 * get_physics_process_delta_time())
		await get_tree().process_frame
