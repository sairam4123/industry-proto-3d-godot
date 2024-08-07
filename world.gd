extends Node3D

var current_item_id
var current_tile
var current_preview: Node3D
var current_orientation: int
var current_pos = Vector3i.ZERO

var _anim_cur_pos = Vector3.ZERO
var _anim_cur_rot = Vector3.ZERO

var supported_ories = [0, 16, 10, 22]
var auto_rot_tile = true
var prev_pos = Vector3i.ZERO

var offsets = {
	0: Vector3i(-1, 0, 0),     # D - 0
	16: Vector3i(0, 0, 1),     # W - 16
	10: Vector3i(1, 0, 0),     # A - 10
	22: Vector3i(0, 0, -1),    # S - 22
}

var ories = {
	Vector3i(1, 0, 0): 0,     # D - 0
	Vector3i(0, 0, -1): 16,     # W - 16
	Vector3i(-1, 0, 0): 10,     # A - 10
	Vector3i(0, 0, 1): 22,    # S - 22
}

var auto_rot_mapping = {
	0: 0,
	16: 16,
	10: 10,
	22: 22,
}

const ERROR = preload("res://mats/error.tres")
const SELECTED = preload("res://mats/selected.tres") 

var scene_mapping = {

	SCANNER_HIGH: preload("res://kenney_conveyor-kit/Models/GLB format/scanner-high.glb"),
	SCANNER_LOW: preload("res://kenney_conveyor-kit/Models/GLB format/scanner-low.glb"),
	CONVEYOR: preload("res://kenney_conveyor-kit/Models/GLB format/Custom/conveyor_2.tscn"),
	CONVEYOR_STRIP: preload("res://kenney_conveyor-kit/Models/GLB format/Custom/conveyor-stripe.tscn"),

	#SCANNER_HIGH: preload("res://kenney_conveyor-kit/Models/GLB format/scanner-high.glb"),
	#SCANNER_HIGH: preload("res://kenney_conveyor-kit/Models/GLB format/scanner-high.glb"),
	#SCANNER_HIGH: preload("res://kenney_conveyor-kit/Models/GLB format/scanner-high.glb"),
	#SCANNER_HIGH: preload("res://kenney_conveyor-kit/Models/GLB format/scanner-high.glb"),

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

func _ready() -> void:
	for i in range(0, 256):
		for j in range(0, 256):
			$LayeredGridMap.add_at(FLOOR, Vector3i(i, 0, j), 0)
	
	var item_source = Vector3i(10, 0, 10)
	var item_dest = Vector3i(20, 0, 20)
	$LayeredGridMap.add_at(ITEM_SOURCE, item_source, 16)
	$LayeredGridMap.add_at(ITEM_SINK, item_dest, 16)
	
	UiEventBus.ui_building_pressed.connect(_ui_building_pressed)
	UiEventBus.ui_close_pressed.connect(_on_ui_close_pressed)
	UiEventBus.ui_orientation_pressed.connect(_on_ui_orientation_pressed)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		#if event.keycode in [KEY_1, KEY_2, KEY_3, KEY_4]:
			#if current_preview:
				#current_preview.queue_free()
		#
		#if event.keycode == KEY_1:
			#current_tile = CONVEYOR
			#current_preview = scene_mapping[CONVEYOR].instantiate()
		#
		#elif event.keycode == KEY_2:
			#current_tile = CONVEYOR_STRIP
			#current_preview = scene_mapping[CONVEYOR_STRIP].instantiate()
		#
		#elif event.keycode == KEY_3:
			#current_tile = SCANNER_LOW
			#current_preview = scene_mapping[SCANNER_LOW].instantiate()
		#
		#elif event.keycode == KEY_4:
			#current_tile = SCANNER_HIGH
			#current_preview = scene_mapping[SCANNER_HIGH].instantiate()
		#
		if event.keycode in [KEY_RIGHT, KEY_E] and event.pressed and current_tile:
			_on_ui_orientation_pressed(-1)
		if event.keycode in [KEY_LEFT, KEY_Q] and event.pressed and current_tile:
			_on_ui_orientation_pressed(1)
		if event.keycode == KEY_ESCAPE and event.pressed:
			_on_ui_close_pressed()
		
		#if event.keycode in [KEY_1, KEY_2, KEY_3, KEY_4]:
			#if current_preview:
				#$Preview.add_child(current_preview)
				#var mesh: MeshInstance3D = current_preview.get_child(0)
				#mesh.position = Vector3(current_pos) + Vector3(0.5, 0.125, 0.5)
				#mesh.basis = $LayeredGridMap/Floor.get_basis_with_orthogonal_index(current_orientation)
	if OS.has_feature("mobile"):
		if event is InputEventSingleScreenTap and current_tile and GameManager.money > 0:
			$LayeredGridMap.add_at(current_tile, current_pos, current_orientation)
			var amount = int(ItemManager.items[current_item_id].item_price)
			GameManager.remove_money(amount)
		if event is InputEventSingleScreenLongPress and current_tile and GameManager.money > 0:
			$LayeredGridMap.remove(current_pos)
			var amount = int(ItemManager.items[current_item_id].item_price)
			amount -= amount * 0.15
			GameManager.add_money(int(amount))
			print("Delete item:", current_item_id, "amount:", amount)
			Input.vibrate_handheld(500)
		if event is InputEventSingleScreenDrag and current_tile and GameManager.money > 0:
			$LayeredGridMap.add_at(current_tile, current_pos, current_orientation)
	
	if OS.has_feature("pc"):
		if event is InputEventMouseButton and current_tile:
			if event.button_mask & MOUSE_BUTTON_MASK_LEFT == MOUSE_BUTTON_LEFT and event.pressed and GameManager.money > 0:
				$LayeredGridMap.add_at(current_tile, current_pos, current_orientation)
				var amount = int(ItemManager.items[current_item_id].item_price)
				GameManager.remove_money(amount)
			
			if event.button_mask & MOUSE_BUTTON_MASK_RIGHT == MOUSE_BUTTON_MASK_RIGHT and event.pressed and GameManager.money > 0:
				$LayeredGridMap.remove(current_pos)
				var amount = int(ItemManager.items[current_item_id].item_price)
				amount -= amount * 0.15
				GameManager.add_money(int(amount))
				print("Delete item:", current_item_id, "amount:", amount)
			
		if event is InputEventMouseMotion and current_tile in [CONVEYOR, CONVEYOR_STRIP]:
			if event.button_mask & MOUSE_BUTTON_MASK_LEFT == MOUSE_BUTTON_MASK_LEFT:
				$LayeredGridMap.add_at(current_tile, current_pos, current_orientation)
				#var amount = int(ItemManager.items[current_item_id].item_price)
				#GameManager.remove_money(amount)
			if auto_rot_tile:
				var dir_vec = (prev_pos - current_pos)
				var shortest = INF
				var shortest_dir = Vector3.INF
				for dir in ories:
					var dist = Vector3(dir_vec).dot(Vector3(dir))
					prints("SHORT ROT DIST:", dist, dir, shortest)
					if dist < shortest:
						shortest = dist
						shortest_dir = dir
				
				print("POS ROT", prev_pos, current_pos)
				var _offset = shortest_dir
				var ori = ories.get(_offset, -1)
				if ori != -1:
					current_orientation = ori
				prints("Auto Rot", shortest_dir)

func _process(delta: float) -> void:
	if is_instance_valid(current_preview):
		var _3d_pos = get_3d_mouse_pos()
		var mesh: MeshInstance3D = current_preview.get_child(0)
		var basis_: Basis = $LayeredGridMap/Floor.get_basis_with_orthogonal_index(current_orientation)
		mesh.basis = mesh.basis.orthonormalized().slerp(basis_, 8 * delta).scaled(Vector3(1.01, 1.01, 1.01))
		if _3d_pos.is_finite():
			_3d_pos = Vector3i(_3d_pos.x, 0, _3d_pos.z)
			_anim_cur_pos = Vector3(_3d_pos) + Vector3(0.5, 0, 0.5)
			mesh.position = mesh.position.lerp(_anim_cur_pos, 10 * delta)
			handle_cell_type(_3d_pos)
			prev_pos = current_pos
			current_pos = _3d_pos
			
		if current_tile in [CONVEYOR, CONVEYOR_STRIP]:
			mesh.material_overlay = ERROR if $LayeredGridMap.has_item_at_layers(current_pos, [2, 3, 4]) else SELECTED
		elif current_tile in [SCANNER_LOW, SCANNER_HIGH]:
			mesh.material_overlay = SELECTED if $LayeredGridMap.has_item_at_layers(current_pos, [2, 3, 4]) and not $LayeredGridMap.has_item_at_layers(current_pos, [1]) else ERROR

func handle_cell_type(pos):
	if not auto_rot_tile:
		return
	var cell = $LayeredGridMap.get_cell_at(pos, 2)
	var rot = $LayeredGridMap.get_cell_orientation(pos, 2)
	if rot == -1:
		return
	if current_tile in [SCANNER_LOW, SCANNER_HIGH]:
		current_orientation = auto_rot_mapping[rot]

func get_3d_mouse_pos() -> Vector3:
	var mp = get_viewport().get_mouse_position()
	var cam = get_viewport().get_camera_3d()
	var from = cam.project_ray_origin(mp)
	var to = cam.project_ray_normal(mp) * cam.far
	var query = PhysicsRayQueryParameters3D.new()
	query.from = from
	query.to = to
	var info = get_world_3d().direct_space_state.intersect_ray(query)
	return info.get("position", Vector3(-INF, -INF, -INF))

func _ui_building_pressed(item_id):
	if is_instance_valid(current_preview):
		current_preview.queue_free()
	
	if item_id == "conveyor":
		current_tile = CONVEYOR
	if item_id == "conveyor2":
		current_tile = CONVEYOR_STRIP
	if item_id == "scanner_low":
		current_tile = SCANNER_LOW
	if item_id == "scanner_high":
		current_tile = SCANNER_HIGH
	current_item_id = item_id
	if current_tile:
		current_preview = scene_mapping[current_tile].instantiate() 
	if current_preview:
		$Preview.add_child(current_preview)
		var mesh: MeshInstance3D = current_preview.get_child(0)
		mesh.position = Vector3(current_pos) + Vector3(0.5, 0.125, 0.5)
		mesh.basis = $LayeredGridMap/Floor.get_basis_with_orthogonal_index(current_orientation)
		
func _on_ui_orientation_pressed(direction: int):
	current_orientation = supported_ories[(supported_ories.find(current_orientation)-direction ) % 4]

func _on_ui_close_pressed():
	current_tile = null
	current_item_id = ""
	if is_instance_valid(current_preview):
		current_preview.queue_free()
	current_preview = null
