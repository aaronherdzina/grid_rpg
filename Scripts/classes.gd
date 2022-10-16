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

const PRE_ANIM_TIMER = .5
const POST_ANIM_TIMER = .25
const BASE_HIT_ANIM_TIMER = .75


var classes = []
var loadedClass

#### CREATURES

# Creature alg:
# each attribute adds to a max 
# (move + health) + ((defense * toughness) * evasion) + (atks * dmg)
#
#
#
var BASE_EXPECTED_STAT_TOTAL = 300
###

var BEAR_BASE_MOVE = 5 # amount of tiles they can move
var BEAR_BASE_ATTACKS = 5 # amount of attacks they can make
var BEAR_BASE_ATTACK_RANGE = 2
var BEAR_BASE_DEFENSE = 5 # Amount of dmg blocked, lost when used, does not regen
var BEAR_BASE_TOUGHNESS = 50 # amount of dmg blocked, lost when used for turn
var BEAR_BASE_EVASION = 0 # 1 in 100 chance of dogging an attack al together
var BEAR_BASE_DMG = 20 # amount of dmg blocked, lost when used for turn
var BEAR_BASE_HEALTH = 150


var PUMA_BASE_MOVE = 14 # amount of tiles they can move
var PUMA_BASE_ATTACKS = 3 # amount of attacks they can make
var PUMA_BASE_ATTACK_RANGE = 4
var PUMA_BASE_DEFENSE = 15 # Amount of dmg blocked, lost when used, does not regen
var PUMA_BASE_TOUGHNESS = 10 # amount of dmg blocked, lost when used for turn
var PUMA_BASE_EVASION = 7 # 1 in 100 chance of dogging an attack al together
var PUMA_BASE_DMG = 4 # amount of dmg blocked, lost when used for turn
var PUMA_BASE_HEALTH = 75

var DOG_BASE_MOVE = 9 # amount of tiles they can move
var DOG_BASE_ATTACKS = 4 # amount of attacks they can make
var DOG_BASE_ATTACK_RANGE = 1
var DOG_BASE_DEFENSE = 5 # Amount of dmg blocked, lost when used, does not regen
var DOG_BASE_TOUGHNESS = 20 # amount of dmg blocked, lost when used for turn
var DOG_BASE_EVASION = 4 # 1 in 100 chance of dogging an attack al together
var DOG_BASE_DMG = 5 # amount of dmg blocked, lost when used for turn
var DOG_BASE_HEALTH = 100
####### WRESTLER

var wrestler_hp_per_lvl = 10
var wrestler_def_per_lvl = 5
var wrestler_damage_per_lvl = 3
var wrestler_prefered_stat_1 = STRENGTH_STAT
var wrestler_prefered_stat_2 = REASON_STAT
var wrestler_prefered_stat_3 = RESILIENCE_STAT
var wrestler_speed_per_lvl = 3
var wrestler_move_speed = MOVE_SPEED_6


func verify_char_stat_total(char_payload):
	var char_stat_value = (char_payload["move"] + char_payload["health"]) \
						  + ((char_payload["defense"] * char_payload["toughness"])  * char_payload["evasion"]) \
						  + (char_payload["attacks"] * char_payload["damage"])
	var dif = BASE_EXPECTED_STAT_TOTAL - char_stat_value
	if dif != 0:
		if dif < 0:
			print(char_payload["name"] + " is " + str(dif) + " stat points ABOVE min amount " + str(char_stat_value) + ". Expected " + str(BASE_EXPECTED_STAT_TOTAL)+"\n")
		else:
			print(char_payload["name"] + " is " + str(dif) + " stat points below min amount " + str(char_stat_value) + ". Expected " + str(BASE_EXPECTED_STAT_TOTAL)+"\n")
	else:
		print(char_payload["name"] + " stats are look good " + str(char_stat_value) + ". Expected " + str(BASE_EXPECTED_STAT_TOTAL)+"\n")


const WRESTLER_SKILL_THROW = "wrestler_skill_1_throw"
func wrestler_skill_1_throw(target, attacker, target_stats, attacker_stats):
	print("wrestler_skill_1_throw")
	var throw_distance = attacker_stats[STRENGTH_STAT] + floor(attacker_stats[REASON_STAT]*.5)
	
	if attacker_stats[STRENGTH_STAT] > floor(target_stats[STRENGTH_STAT]*2)\
	   or attacker_stats[STRENGTH_STAT] > (target_stats[STRENGTH_STAT] - floor(attacker_stats[REASON_STAT]*.5)):
		throw_distance += 1
	else:
		pass

	attacker.get_node("AnimationPlayer").play("healed")
	var timer_1 = main.make_timer(BASE_HIT_ANIM_TIMER)
	timer_1.start()
	yield(timer_1, "timeout")
	timer_1.queue_free()

	if throw_distance >  8:
		throw_distance = 8
	elif throw_distance < 1:
		throw_distance = 1
	var saftey_count = 100
	var throw_anim_speed = 200
	var tiles_nearby = meta.get_adjacent_tiles_in_distance(attacker.current_tile, throw_distance)
	var chosen_tile = target.current_tile
	if len(tiles_nearby) > 0:
		chosen_tile = tiles_nearby[floor(rand_range(0, len(tiles_nearby)))]

	for t in tiles_nearby:
		if t.row > attacker.current_tile.row + 1 or t.col > attacker.current_tile.col + 1:
			t = chosen_tile
			break

	var timer = main.make_timer(BASE_HIT_ANIM_TIMER)
	timer.start()
	yield(timer, "timeout")
	timer.queue_free()
	chosen_tile.map_tile_type(meta.DIRT_TYPE)
	target.current_tile = chosen_tile
	target.position = chosen_tile.global_position
	
	var atk_anim = main.atk_scene.instance()
	get_node("/root").add_child(atk_anim)
	atk_anim.position = target.global_position
	atk_anim.get_node("anim").play("atk")

	target.get_node("AnimationPlayer").play("hurt")

	for t in get_node("/root/level").level_tiles:
		meta.helpers_set_edge_tiles(t)

	var post_anim_timer = main.make_timer(BASE_HIT_ANIM_TIMER)
	post_anim_timer.start()
	yield(post_anim_timer, "timeout")
	post_anim_timer.queue_free()

	target.get_node("AnimationPlayer").stop()
	target.get_node("AnimationPlayer").play(target.facing_dir + "knockback")


const WRESTLER_SKILL_SWAP = "wrestler_skill_2_swap"
func wrestler_skill_2_swap(target, attacker, target_stats, attacker_stats):
	print("wrestler_skill_2_swap")

	attacker.get_node("AnimationPlayer").stop()
	attacker.get_node("AnimationPlayer").play("buff")

	var timer_1 = main.make_timer(PRE_ANIM_TIMER)
	timer_1.start()
	yield(timer_1, "timeout")
	timer_1.queue_free()

	var hold_attacker_tile = attacker.current_tile
	var hold_atk_pos = attacker.global_position
	var hold_target_tile = target.current_tile
	var hold_target_pos = target.global_position

	attacker.position = hold_target_pos
	attacker.current_tile = hold_target_tile

	var timer = main.make_timer(BASE_HIT_ANIM_TIMER)
	timer.start()
	yield(timer, "timeout")
	timer.queue_free()

	target.get_node("AnimationPlayer").play("hurt")

	var timer2 = main.make_timer(.1)
	timer2.start()
	yield(timer2, "timeout")
	timer2.queue_free()

	var atk_anim = main.atk_scene.instance()
	get_node("/root").add_child(atk_anim)
	atk_anim.position = target.global_position
	atk_anim.get_node("anim").play("atk")

	target.current_tile = hold_attacker_tile
	target.position = hold_atk_pos
	atk_anim.position = target.global_position

	var post_anim_timer = main.make_timer(BASE_HIT_ANIM_TIMER)
	post_anim_timer.start()
	yield(post_anim_timer, "timeout")
	post_anim_timer.queue_free()

	target.get_node("AnimationPlayer").stop()
	target.get_node("AnimationPlayer").play(target.facing_dir + "knockback")
#######


####### MELEE
const MELEE_SKILL_PUSH = "melee_skill_1_push"
func melee_skill_1_push(target, attacker, target_stats, attacker_stats):
	print("melee_skill_1_push")
	randomize()

	var push_distance = ceil(attacker_stats[STRENGTH_STAT] * 2.5)
	if push_distance >  10:
		push_distance = 10
	elif push_distance < 1:
		push_distance = 1

	attacker.get_node("AnimationPlayer").play("defbuff")

	var timer_1 = main.make_timer(PRE_ANIM_TIMER)
	timer_1.start()
	yield(timer_1, "timeout")
	timer_1.queue_free()

	var atk_anim = main.atk_scene.instance()
	get_node("/root").add_child(atk_anim)
	atk_anim.position = target.global_position
	atk_anim.get_node("anim").play("strike")

	if attacker_stats[STRENGTH_STAT] > floor(target_stats[STRENGTH_STAT])\
	   or attacker_stats[STRENGTH_STAT] > (target_stats[STRENGTH_STAT] - floor(attacker_stats[REASON_STAT]*.5)):
		pass
	else:
		pass

	var saftey_count = 100
	var throw_anim_speed = 200
	var tiles_nearby = meta.get_adjacent_tiles_in_distance(attacker.current_tile, push_distance)
	var match_row = target.current_tile.row == attacker.current_tile.row
	var match_col = target.current_tile.col == attacker.current_tile.col
	var current_push_dist_col = -1000
	var current_push_dist_row = -1000
	var top_push_dist_col = -1000
	var top_push_dist_row = -1000
	var current_tile_dif = -1000
	var previous_dif = -1000
	var chosen_tile = target.current_tile

	for t in tiles_nearby:
		if t == attacker.current_tile or t == target.current_tile:
			continue
		#print("t.row " + str(t.row))
		#print("t.col " + str(t.col))
		#print("attacker.current_tile.row " + str(attacker.current_tile.row))
		#print("target.current_tile.row " + str(target.current_tile.row))
		#print("attacker.current_tile.col " + str(attacker.current_tile.col))
		#print("target.current_tile.col " + str(target.current_tile.col))
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
		
	var atk_anim2 = main.atk_scene.instance()
	get_node("/root").add_child(atk_anim2)
	atk_anim2.position = target.global_position
	atk_anim2.get_node("anim").play("atk")

	target.get_node("AnimationPlayer").play("hurt")

	var timer = main.make_timer(BASE_HIT_ANIM_TIMER)
	timer.start()
	yield(timer, "timeout")
	timer.queue_free()

	target.current_tile = chosen_tile
	target.position = chosen_tile.global_position

	var post_anim_timer = main.make_timer(BASE_HIT_ANIM_TIMER)
	post_anim_timer.start()
	yield(post_anim_timer, "timeout")
	post_anim_timer.queue_free()

	target.get_node("AnimationPlayer").stop()
	target.get_node("AnimationPlayer").play(target.facing_dir + "knockback")


#######

# MAKE GENERAL TAKE DMG METHOD THAT ALSO TAKE PARAMS TO DETERMINE HURT ANIM AS APPOSED TO ATTACK ANUIM
# IE FOR NOW CALL "ATK", or "HURT" all the time too
####### BRAWLER (TILE MODIFIER CLASS)

#######

####### RANGED (THROWN)

#######

####### RANGED (SHOT)

#######

####### 

####### TILE CHANGE

const SHAPER_SKILL_DIRT_SWEEP = "shaper_skill_1_dirt_sweep"
func shaper_skill_1_dirt_sweep(target, attacker, target_stats, attacker_stats):
	attacker.get_node("AnimationPlayer").stop()
	attacker.get_node("AnimationPlayer").play("healed")

	var pre_anim_timer = main.make_timer(BASE_HIT_ANIM_TIMER)
	pre_anim_timer.start()
	yield(pre_anim_timer, "timeout")
	pre_anim_timer.queue_free()

	var atk_anim = main.atk_scene.instance()
	get_node("/root").add_child(atk_anim)
	atk_anim.position = target.global_position
	atk_anim.get_node("anim").play("fireball")

	var timer = main.make_timer(BASE_HIT_ANIM_TIMER)
	timer.start()
	yield(timer, "timeout")
	timer.queue_free()

	meta.set_tiles_in_path(attacker.current_tile, target.current_tile, meta.DIRT_TYPE, 1)


	var atk_anim2 = main.atk_scene.instance()
	get_node("/root").add_child(atk_anim2)
	atk_anim2.position = target.global_position
	atk_anim2.get_node("anim").play("atk")

	target.get_node("AnimationPlayer").stop()
	target.get_node("AnimationPlayer").play("hurt")
	var player = get_node("/root/player")
	for t in meta.get_adjacent_tiles_in_distance(target.current_tile, 3):
		t.map_tile_type(meta.DIRT_TYPE)
		if player.current_tile == t:
			var timer_2 = main.make_timer(BASE_HIT_ANIM_TIMER)
			timer_2.start()
			yield(timer_2, "timeout")
			timer_2.queue_free()
			meta.attack(attacker, player, true, "standard")
			
		else:
			for enm in get_tree().get_nodes_in_group("enemies"):
				if main.checkIfNodeDeleted(enm) == false and enm.alive and enm.current_tile == t:
					var timer_2 = main.make_timer(BASE_HIT_ANIM_TIMER)
					timer_2.start()
					yield(timer_2, "timeout")
					timer_2.queue_free()
					meta.attack(attacker, enm, true, "standard")
					break
	var post_anim_timer = main.make_timer(POST_ANIM_TIMER)
	post_anim_timer.start()
	yield(post_anim_timer, "timeout")
	post_anim_timer.queue_free()
	target.get_node("AnimationPlayer").stop()
	target.get_node("AnimationPlayer").play(target.facing_dir + "knockback")


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var dmg = 2



func ready_skill(attacker, skill):
	# Prepares chosen skill for attack acrtion
	# set chosen_skill to the chosen skill and map range, etc
	attacker.chosen_skill = skill
	if skill == WRESTLER_SKILL_SWAP:
		attacker.chosen_skill = skill
		attacker.chosen_skill_atk_range = 0
	elif skill == WRESTLER_SKILL_THROW:
		attacker.chosen_skill = skill
		attacker.chosen_skill_atk_range = 0
	elif skill == MELEE_SKILL_PUSH:
		attacker.chosen_skill = skill
		attacker.chosen_skill_atk_range = 0
	elif skill == SHAPER_SKILL_DIRT_SWEEP:
		attacker.chosen_skill = skill
		attacker.chosen_skill_atk_range = 7
	else:
		print("skill not found: " + str(skill))


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.




func skill_1():
	return dmg
