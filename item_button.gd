@tool
extends Button
class_name ItemButton

@export var tile_item: Item:
	set(val):
		tile_item = val
		if !is_inside_tree():
			return
		update()

@export var is_locked: bool:
	set(val):
		is_locked = val
		if !is_inside_tree():
			return
		update()

@export var item_name: String:
	set(val):
		item_name = val
		if !is_inside_tree():
			return
		update()
	get:
		if is_inside_tree():
			if %ItemName.text != item_name:
				return item_name
			return %ItemName.text
		else:
			return item_name

@export var item_icon: ImageTexture:
	set(val):
		item_icon = val
		if !is_inside_tree():
			return
		update()
	get:
		if is_inside_tree():
			if %ItemIcon.texture != item_icon:
				return item_icon
			return %ItemIcon.texture
		else:
			return item_icon

@export_multiline var item_description: String:
	set(val):
		item_description = val
		if !is_inside_tree():
			return
		update()
	get:
		if is_inside_tree():
			if %ItemDesc.text != item_description:
				return item_description
			return %ItemDesc.text
		else:
			return item_description

@export var item_price: String:
	set(val):
		item_price = val
		if !is_inside_tree():
			return
		update()
	get:
		if is_inside_tree():
			if %ItemPrice.text.trim_prefix("$") != item_price:
				return item_price
			return %ItemPrice.text.trim_prefix("$")
		else:
			return item_price

func _ready():
	update()

func update():
	%ItemIcon.texture = tile_item.item_icon
	%ItemName.text = tile_item.item_name
	%ItemDesc.text = "[center]" + tile_item.item_description +"\n[/center]"
	%ItemPrice.text = "$"+tile_item.item_price
	$MarginContainer.visible = not is_locked
	$Lock.visible = is_locked
	disabled = is_locked
