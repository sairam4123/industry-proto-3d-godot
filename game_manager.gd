extends Node

var level = 0
var xp = 0

var money = 500

var min_xp = 0
var max_xp = 0


# Thanks GPT!
func get_max_xp(level):
	var base = 20
	var exp_gr = 1.3
	var scale = 100
	var lin_gr = 28
	var max_level = 10
	
	if level < 0:
		return 1
	elif level == 1:
		return base
	elif level <= max_level:
		return base + (level - 1) * lin_gr
	else:
		return int(base + (max_level - 1) * lin_gr + pow(level - max_level, exp_gr) * scale)

func get_amount(level):
	var base = 12
	var exp_gr = 1.5
	var scale = 50
	var lin_gr = 10
	var max_level = 20
	
	if level < 0:
		return 1
	elif level == 1:
		return base
	elif level <= max_level:
		return base + (level - 1) * lin_gr
	else:
		return int(base + (max_level - 1) * lin_gr + pow(level - max_level, exp_gr) * scale)


func get_min_max_xp(level):
	return [get_max_xp(level), get_max_xp(level+1)]

func add_money(amount: int):
	prints("Adding amount:", amount, "Total:", money + amount)
	money += amount
	EventBus.money_changed.emit(money)

func remove_money(amount: int):
	prints("Removing amount:", amount, "Total:", money - amount)
	money -= amount
	EventBus.money_changed.emit(money)

func add_xp(amount: int):
	xp += amount
	EventBus.xp_changed.emit(xp)
	var xps = get_min_max_xp(level)
	min_xp = xps[0]
	max_xp = xps[1]
	if xp > max_xp:
		level += 1
		EventBus.level_changed.emit(level)
		xps = get_min_max_xp(level)
		min_xp = xps[0]
		max_xp = xps[1]
		
		var reward = get_amount(level)
		add_money(reward)
	
