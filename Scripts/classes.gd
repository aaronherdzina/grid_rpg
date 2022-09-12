extends Node

const STRENGTH_STAT = "strength"
const DEFENSE_STAT = "defense"
const HEALTH_STAT = "health"
const FORCE_STAT = "force" # moving or throwing things around
const WISDOM_STAT = "wisdon"
const SPEED_STAT = "speed"
const REASON_STAT = "reason"
const RESILIENCE_STAT = "resilience"

const MOVE_SPEED_4 = 4
const MOVE_SPEED_5 = 5
const MOVE_SPEED_6 = 6
const MOVE_SPEED_7 = 7
const MOVE_SPEED_8 = 8
const MOVE_SPEED_9 = 9
const MOVE_SPEED_10 = 10

var classes = []
var loadedClass


####### WRESTLER

var wrestler_hp_per_lvl = 10
var wrestler_def_per_lvl = 5
var wrestler_damage_per_lvl = 3
var wrestler_prefered_stat_1 = STRENGTH_STAT
var wrestler_prefered_stat_2 = REASON_STAT
var wrestler_prefered_stat_3 = RESILIENCE_STAT
var wrestler_speed_per_lvl = 3
var wrestler_move_speed = MOVE_SPEED_6


func wrestler_skill_1_throw(target, attacker, target_stats, attacker_stats):
	print("wrestler_skill_1_throw")
	var throw_distance = attacker_stats[STRENGTH_STAT] + floor(attacker_stats[REASON_STAT]*.5)
	
	if attacker_stats[STRENGTH_STAT] > floor(target_stats[STRENGTH_STAT]*2)\
	   or attacker_stats[STRENGTH_STAT] > (target_stats[STRENGTH_STAT] - floor(attacker_stats[REASON_STAT]*.5)):
		throw_distance += 1
	else:
		pass
	
	if throw_distance >  8:
		throw_distance = 8
	elif throw_distance < 1:
		throw_distance = 1
	var saftey_count = 100
	var throw_anim_speed = 200
	var tiles_nearby = meta.get_adjacent_tiles_in_distance(attacker.current_tile, throw_distance)
	if len(tiles_nearby) <= 0:
		return
	var chosen_tile = tiles_nearby[floor(rand_range(0, len(tiles_nearby)))]

	for t in tiles_nearby:
		if t.row > attacker.current_tile.row + 1 or t.col > attacker.current_tile.col + 1:
			t = chosen_tile
			break
		
	var timer = main.make_timer(.2)
	timer.start()
	yield(timer, "timeout")
	timer.queue_free()
	target.current_tile = chosen_tile
	target.position = chosen_tile.global_position
	target.get_node("AnimationPlayer").play(target.facing_dir + "knockback")




func wrestler_skill_2_swap(target, attacker, target_stats, attacker_stats):
	print("wrestler_skill_2_swap")
	var hold_attacker_tile = attacker.current_tile
	var hold_atk_pos = attacker.global_position
	var hold_target_tile = target.current_tile
	var hold_target_pos = target.global_position

	attacker.position = hold_target_pos
	attacker.current_tile = hold_target_tile
	var timer = main.make_timer(.2)
	timer.start()
	yield(timer, "timeout")
	timer.queue_free()
	target.get_node("AnimationPlayer").play(target.facing_dir + "knockback")
	var timer2 = main.make_timer(.1)
	timer2.start()
	yield(timer2, "timeout")
	timer2.queue_free()
	target.current_tile = hold_attacker_tile
	target.position = hold_atk_pos

#######

####### MELEE

func melee_skill_1_push(target, attacker, target_stats, attacker_stats):
	print("melee_skill_1_push")
	randomize()
	var push_distance = ceil(attacker_stats[STRENGTH_STAT] * 2.5)
	if push_distance >  10:
		push_distance = 10
	elif push_distance < 1:
		push_distance = 1

	if attacker_stats[STRENGTH_STAT] > floor(target_stats[STRENGTH_STAT])\
	   or attacker_stats[STRENGTH_STAT] > (target_stats[STRENGTH_STAT] - floor(attacker_stats[REASON_STAT]*.5)):
		pass
	else:
		pass

	var saftey_count = 100
	var throw_anim_speed = 200
	var tiles_nearby = meta.get_adjacent_tiles_in_distance(attacker.current_tile, push_distance)
	if len(tiles_nearby) <= 0:
		return

	var match_row = target.current_tile.row == attacker.current_tile.row
	var match_col = target.current_tile.col == attacker.current_tile.col
	var current_push_dist_col = -1000
	var current_push_dist_row = -1000
	var top_push_dist_col = -1000
	var top_push_dist_row = -1000
	var current_tile_dif = -1000
	var previous_dif = -1000
	var chosen_tile = target.current_tile
	print("match_row " + str(match_row))
	print("match_col " + str(match_col))
	for t in tiles_nearby:
		if t == attacker.current_tile or t == target.current_tile:
			continue
		print("t.row " + str(t.row))
		print("t.col " + str(t.col))
		print("attacker.current_tile.row " + str(attacker.current_tile.row))
		print("target.current_tile.row " + str(target.current_tile.row))
		print("attacker.current_tile.col " + str(attacker.current_tile.col))
		print("target.current_tile.col " + str(target.current_tile.col))
		if match_row:
			if t.row == attacker.current_tile.row:
				top_push_dist_row = abs(abs(t.row) - abs(attacker.current_tile.row))
				if top_push_dist_row > current_push_dist_row:
					current_push_dist_row = top_push_dist_row
					chosen_tile = t
		else:
			if t.col == attacker.current_tile.col:
				top_push_dist_col = abs(abs(t.col) - abs(attacker.current_tile.col))
				if top_push_dist_col > current_push_dist_col:
					current_push_dist_col = top_push_dist_col
					chosen_tile = t

	if not chosen_tile:
		return
	var timer = main.make_timer(.2)
	timer.start()
	yield(timer, "timeout")
	timer.queue_free()
	target.current_tile = chosen_tile
	target.position = chosen_tile.global_position
	target.get_node("AnimationPlayer").play(target.facing_dir + "knockback")
#######


####### BRAWLER (TILE MODIFIER CLASS)

#######

####### RANGED (THROWN)

#######

####### RANGED (SHOT)

#######

####### 


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var dmg = 2

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.




func skill_1():
	return dmg
