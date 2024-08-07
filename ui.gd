extends Control

const ItemButton = preload("res://item_button.tscn")
@onready var tile_items_list: VBoxContainer = %TileItemsList
@onready var progress_bar: ProgressBar = %ProgressBar
@onready var level_label: Label = %LevelLabel
@onready var bank_amount: Label = %BankAmount

var ui_level = 0
var ui_xp = 0
var ui_money = 0
var max_xp = 0
var min_xp = 0

var _build_tool_enabled = false

func _ready() -> void:
	EventBus.level_changed.connect(_level_changed)
	EventBus.xp_changed.connect(_xp_changed)
	EventBus.money_changed.connect(_money_changed)
	
	_money_changed(500)
	_level_changed(0)
	_xp_changed(1)
	var type = Item.ItemType.CONVEYOR
	for item in ItemManager.items.values():
		var btn = ItemButton.instantiate()
		btn.tile_item = item
		btn.pressed.connect(_on_item_btn_pressed.bind(item.item_id))
		if item.item_type != type:
			var spacer = tile_items_list.add_spacer(false)
			spacer.size_flags_horizontal = Control.SIZE_FILL
			spacer.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
			spacer.custom_minimum_size.y = 20
		
		tile_items_list.add_child(btn, true)
		type = item.item_type
		if (item as Item).item_unlock_level > 0:
			btn.is_locked = true
	
func _level_changed(_level: int):
	ui_level = _level
	min_xp = max(1, GameManager.get_max_xp(ui_level))
	max_xp = GameManager.get_max_xp(ui_level+1)
	%LevelLabel.text = "Level {0} ({1}XP / {2}XP)".format([ui_level, ui_xp, max_xp])
	%ProgressBar.max_value = max_xp
	%ProgressBar.min_value = min_xp
	
	for item in %TileItemsList.get_children():
		if not item is ItemButton:
			continue
		item.is_locked = item.tile_item.item_unlock_level > ui_level
	
	
func _xp_changed(_xp: int):
	create_tween().tween_method(_tween_xp, float(ui_xp), float(_xp), 0.25)

func _tween_xp(_xp):
	ui_xp = int(_xp)
	%ProgressBar.value = ui_xp
	%LevelLabel.text = "Level {0} ({1}XP / {2}XP)".format([ui_level, int(ui_xp), int(max_xp)])
	
func _money_changed(_money: int):
	create_tween().tween_method(_tween_money, float(ui_money), float(_money), 0.25)
	
func _tween_money(_money):
	ui_money = int(_money)
	%BankAmount.text = "$"+str(ui_money)
	#prints("Amount:", _money)

func _on_item_btn_pressed(item_id):
	_build_tool_enabled = true
	if OS.has_feature("mobile"):
		%BuildToolBox.show()
	UiEventBus.ui_building_pressed.emit(item_id)

func _on_left_pressed() -> void:
	UiEventBus.ui_orientation_pressed.emit(-1)

func _on_close_pressed() -> void:
	_build_tool_enabled = false
	if OS.has_feature("mobile"):
		%BuildToolBox.hide()
	UiEventBus.ui_close_pressed.emit()

func _on_right_pressed() -> void:
	UiEventBus.ui_orientation_pressed.emit(1)
