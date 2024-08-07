extends Node3D

var _trans = Vector3(5, 0, 5)
var _zoom = 50.0

var _new_trans: Vector3
var _new_zoom: float

var _dir = Vector3.ZERO
var _new_dir = Vector3.ZERO

func _ready() -> void:
	_new_trans = _trans
	_new_zoom = _zoom

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.keycode == KEY_W and event.pressed:
			_new_dir += -int(event.pressed) * basis.z
			_new_dir = _new_dir.normalized()
		elif event.keycode == KEY_S and event.pressed:
			_new_dir += int(event.pressed) * basis.z
			_new_dir = _new_dir.normalized()
		if event.keycode == KEY_A and event.pressed:
			_new_dir += -int(event.pressed)  * basis.x
			_new_dir = _new_dir.normalized()
		elif event.keycode == KEY_D and event.pressed:
			_new_dir += int(event.pressed) * basis.x
			_new_dir = _new_dir.normalized()
		_new_dir *= remap(_zoom, 20.0, 80.0, 0.5, 0.85)
	
		if event.keycode == KEY_Z:
			_new_zoom += 5
		elif event.keycode == KEY_X:
			_new_zoom -= 5
		_new_zoom = clamp(_new_zoom, 20.0, 80.0)
	
	if event is InputEventMouseMotion:
		if event.button_mask & MOUSE_BUTTON_MASK_MIDDLE == MOUSE_BUTTON_MASK_MIDDLE:
			_new_dir += -event.relative.x * 0.01 * basis.x * remap(_zoom, 20.0, 80.0, 0.06, 6)
			_new_dir += -event.relative.y * 0.01 * basis.z * remap(_zoom, 20.0, 80.0, 0.06, 6)
	
	if event is InputEventMultiScreenDrag:
		if event.fingers == 2:
			_new_dir += -event.relative.x * 0.01 * basis.x * remap(_zoom, 20.0, 80.0, 0.06, 6)
			_new_dir += -event.relative.y * 0.01 * basis.z * remap(_zoom, 20.0, 80.0, 0.06, 6)
	if event is InputEventScreenPinch:
		if event.fingers == 2:
			_new_zoom += -event.relative
		_new_zoom = clamp(_new_zoom, 20.0, 80.0)
		
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_new_zoom += 5
		if event .button_index == MOUSE_BUTTON_WHEEL_UP:
			_new_zoom -= 5
		_new_zoom = clamp(_new_zoom, 20.0, 80.0)
		
func _process(delta: float) -> void:
	_dir = _dir.lerp(_new_dir, 6 * delta)
	_new_dir = _new_dir.lerp(Vector3.ZERO, 8 * delta)
	_new_trans += _dir

	_trans = _trans.lerp(_new_trans, 4 * delta)
	_zoom = lerp(_zoom, _new_zoom, 2 * delta)

	$RotatableCamera/ZoomableCamera.position.z = _zoom
	position = _trans
