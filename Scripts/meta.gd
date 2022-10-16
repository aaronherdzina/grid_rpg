extends Node

const GRASS_TYPE = "grass"
const WATER_TYPE = "water"
const GRASS_TYPE_NO_MOVE = "grass blocker"
const DIRT_TYPE = "dirt"
const EMPTY_TYPE = "empty"
const OVERGROWN_GRASS_TYPE = "overgrown"
const FOLIAGE_GRASS_TYPE = "grass_foliage"
const FOLIAGE_WATER_TYPE = "water_foliage"
const FOLIAGE_DIRT_TYPE = "dirt_foliage"
const proximity_mode_type = "prox"
const SPAWN_ENEMY_TYPE = "dirt_foliage"

#####

const BEAR_TYPE = "bear"
const DOG_TYPE = "dog"
const CAT_TYPE = "cat"
const BOAR_TYPE = "boar"
const PUMA_TYPE = "puma"

#####
var BASIC_TYPE = [FOLIAGE_GRASS_TYPE, FOLIAGE_GRASS_TYPE, FOLIAGE_DIRT_TYPE, DIRT_TYPE]
var char_types = [BEAR_TYPE, DOG_TYPE, CAT_TYPE, BOAR_TYPE, PUMA_TYPE]

var standard_atk_type = "standard"
var throw_atk_type = "throw"
var opportunity_atk_type = "opportunity"
var passthrough_atk_type = "passthrough"
var push_atk_type = "push"

var current_level_cols = 10
var current_level_rows = 6
var default_level_cols = 10
var default_level_rows = 6
var player_turn = true
var max_weight = float(99999.0)
var occupied_tile_weight = float(1000.0) # 10000 is min to be unpassible 
var unccupied_tile_weight = float(1.0)
var difficult_terrain_weight = float(2.0)
var wall_tile_weight = float(2000.0)
var dangerous_terrain_weight = float(5.0)

var current_characters_idx = 0
var current_characters = []
var current_character_turn = null
var hovering_on_something = false
var can_spawn_level = true
# Called when the node enters the scene tree for the first time.



var die = {
	"values": [1, 2, 3, 4, 5, 6],
	"tags": []
}


func _ready():
	pass # Replace with function body.


var player_stats = {
	classes.STRENGTH_STAT: 1,
	classes.SPEED_STAT: 1,
	classes.REASON_STAT: 2
}

var course_1 = {
	"cols": 15,
	"rows": 7,
	"tile_list": [ "enemy spawn", "move", "forest path", "move", "move", "move", "move",
				  "move", "water", "wall", "wall", "move", "move", "wall",
				  "move", "water", "move", "wall", "wall", "move", "move",
				  "move", "wall", "wall", "enemy spawn", "move", "move", "move",
				  "move", "wall", "move", "move", "move", "move", "move",
				  "move", "wall", "move", "water", "water", "forest path", "move",
				  "enemy spawn", "wall", "move", "water", "water", "water", "water",
				  "move", "move", "wall", "water", "water", "water", "move",
				  "move", "move", "wall", "enemy spawn", "water", "water", "player spawn",
				  "move", "move", "wall", "wall", "wall", "water", "move",
				  "move", "move", "move", "water", "water", "water", "move",
				  "move", "move", "wall", "water", "wall", "move", "move",
				  "move", "wall", "wall", "water", "wall", "wall", "move",
				  "move", "wall", "wall", "water", "wall", "wall", "move",
				  "move", "move", "move", "move", "move", "move", "enemy spawn",]
	}


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func set_tiles_in_path(start, end, type, width=2):
	var l = get_node("/root/level")
	if not start or not end or not start.current or not end.current:
		print("\n*WARN: start or end in set_tiles_in_path is bad, or successful block of null.*\n start "+str(start)+" end " + str(end) + " \n")
		return
	var point_path = l.level_astar.get_id_path(start.index, end.index)
	for p in point_path:
		for t in l.level_tiles:
			if t.index == p:
				t.map_tile_type(type)
				if width >= 1:
					for t_n in get_adjacent_tiles_in_distance(t, width):
						if t_n != t and rand_range(0, 1) >= .15:
							t_n.map_tile_type(type)
	for t in l.level_tiles:
		meta.helpers_set_edge_tiles(t)


func fix_char_stat_min_vals(char_node):
	""" Ensure no character value goes below a game mechanic needed minimum 
		# energy=1
		# atk_range=1
		# 'other'=0
		# defense=No Limit (negtive defense results into additional dmg recieved)
	"""
	if char_node.energy < 1:
		char_node.energy = 1
	if char_node.current_battle_atk_range < 1:
		char_node.current_battle_atk_range = 1
	if char_node.current_battle_move_distance < 0:
		char_node.current_battle_move_distance = 0
	if char_node.current_battle_attack < 0:
		char_node.current_battle_attack = 0
	if char_node.current_battle_damage < 0:
		char_node.current_battle_damage = 0


func set_new_turn_stats(char_node):
	char_node.current_attack = char_node.current_battle_attack
	char_node.current_damage = char_node.current_battle_damage
	char_node.current_defense = char_node.current_battle_defense
	char_node.current_atk_range = char_node.current_battle_atk_range
	char_node.current_move_distance = char_node.current_battle_move_distance
	char_node.current_opportunity_attacks = char_node.current_battle_opportunity_attacks
	add_passenger_overlay(char_node)
	fix_char_stat_min_vals(char_node)


func add_passenger_overlay(char_node):
	print("add_passenger_overlay called but not finished")
	for p in char_node.passengers:
		if p.type_name == "mouse":
			pass
		elif p.type_name == "porcupine":
			pass
		elif p.type_name == "warbler":
			pass
		elif p.type_name == "porcupine":
			pass


func helpers_set_edge_tiles(tile, set_iso_only=true, left_img=null, top_img=null, right_img=null, bottom_img=null):
	if not tile.current or tile.tile_type == meta.EMPTY_TYPE:
		return
	""" CALLED IN TILE, HAVE 4 CORNER IMGS THAT SET OFF THEIR OWN CONDITION"""
	
	
	""" Logic/Purpose: Give preception of elevation from lowest to highest, desert-greenery-jungle
		desert next to jungle gives darkest edging to seem like the largest incline
		eachother is moderate while water next to greenery and desert look semi even by having..
		... edging that overlays like water spill over
	
	"""
	var standard_color = Color(1, 1, 1, 1)
	var light_faded_edge = Color(1, 1, 1, .5)
	var inset_dark_color = Color(1, 1, 1, 1)
	var inset_color = Color(1, 1, 1, 1)

	"""
	if tile.get_node("edges/top_edge2").visible: tile.get_node("edges/top_edge2").visible = false
	if tile.get_node("edges/left_edge2").visible: tile.get_node("edges/left_edge2").visible = false
	if tile.get_node("edges/right_edge2").visible: tile.get_node("edges/right_edge2").visible = false
	if tile.get_node("edges/bottom_edge2").visible: tile.get_node("edges/bottom_edge2").visible = false
	if tile.get_node("edges/top_edge").visible: tile.get_node("edges/top_edge").visible = false
	if tile.get_node("edges/left_edge").visible: tile.get_node("edges/left_edge").visible = false
	if tile.get_node("edges/right_edge").visible: tile.get_node("edges/right_edge").visible = false
	if tile.get_node("edges/bottom_edge").visible: tile.get_node("edges/bottom_edge").visible = false
	"""
	tile.get_node("edges/bottom_edge").visible = false
	tile.get_node("edges/right_edge").visible = false
	tile.get_node("edges/left_edge").visible = false
	tile.get_node("edges/top_left_edge").visible = false
	tile.get_node("edges/top_edge").visible = false
	tile.get_node("edges/bottom_right_edge").visible = false
	
	var top_edge_z = 1
	var low_edge_z = 0
	if tile.n_top and tile.n_top.tile_subtype != tile.tile_subtype:
		if tile.n_top.tile_subtype == meta.GRASS_TYPE:
			tile.get_node("edges/top_edge").visible = true
			tile.get_node("edges/top_edge").set_texture(main.DARK_GRASS_TILE_EDGE)
			#tile.get_node("edges/top_edge").modulate = standard_color
			tile.get_node("edges/top_edge").z_index = top_edge_z
		elif tile.tile_subtype == meta.WATER_TYPE:
			tile.get_node("edges/top_edge").visible = true
			tile.get_node("edges/top_edge").set_texture(main.DARK_GENERAL_TILE_EDGE)
			#tile.get_node("edges/top_edge").modulate = light_faded_edge
			tile.get_node("edges/top_edge").z_index = low_edge_z

	if tile.n_left and tile.n_left.tile_subtype != tile.tile_subtype:
		if tile.n_left.tile_subtype == meta.GRASS_TYPE:
			tile.get_node("edges/left_edge").visible = true
			tile.get_node("edges/left_edge").set_texture(main.LIGHT_GRASS_TILE_EDGE)
			tile.get_node("edges/left_edge").z_index = top_edge_z
		elif tile.tile_subtype == meta.WATER_TYPE:
			tile.get_node("edges/left_edge").visible = true
			tile.get_node("edges/left_edge").set_texture(main.LIGHTER_GENERAL_TILE_EDGE)
			tile.get_node("edges/left_edge").z_index = low_edge_z

	if tile.n_bottom and tile.n_bottom.tile_subtype != tile.tile_subtype:
		if tile.n_bottom.tile_subtype == meta.GRASS_TYPE:
			tile.get_node("edges/bottom_edge").set_texture(main.GRASS_TILE_OTHER_EDGE)
			tile.get_node("edges/bottom_edge").z_index = top_edge_z
			tile.get_node("edges/bottom_edge").visible = true

	if tile.n_right and tile.n_right.tile_subtype != tile.tile_subtype:
		if tile.n_right.tile_subtype == meta.GRASS_TYPE:
			tile.get_node("edges/right_edge").set_texture(main.GRASS_TILE_OTHER_EDGE)
			tile.get_node("edges/right_edge").z_index = top_edge_z
			tile.get_node("edges/right_edge").visible = true

	if tile.n_left and tile.n_top and tile.n_top_left\
	   and tile.tile_subtype != GRASS_TYPE\
	   and tile.n_left.tile_subtype != GRASS_TYPE\
	   and tile.n_top.tile_subtype != GRASS_TYPE\
	   and tile.n_top_left.tile_subtype == GRASS_TYPE:
			tile.get_node("edges/top_left_edge").set_texture(main.GRASS_TILE_OUTSET_EDGE)
			tile.get_node("edges/top_left_edge").z_index = top_edge_z + 1
			tile.get_node("edges/top_left_edge").visible = true
			tile.get_node("edges/top_left_edge").position = Vector2(-83, -94)
	elif tile.n_left and tile.n_top and tile.n_top_left\
	   and tile.tile_subtype != GRASS_TYPE\
	   and tile.n_left.tile_subtype == GRASS_TYPE\
	   and tile.n_top.tile_subtype == GRASS_TYPE:
			tile.get_node("edges/top_left_edge").set_texture(main.GRASS_TILE_INSET_EDGE)
			tile.get_node("edges/top_left_edge").z_index = top_edge_z + 1
			tile.get_node("edges/top_left_edge").visible = true
			tile.get_node("edges/top_left_edge").position = Vector2(-91, -101)
######
######



func set_end_and_start_turn_tile_based_details(char_node, tile):
	print("setting end/start turn buffs w/" + str(tile.description))
	char_node.current_atk_range += tile.end_and_start_turn_atk_range
	char_node.current_defense += tile.end_and_start_turn_defense
	char_node.current_attack += tile.end_and_start_turn_attack 
	char_node.current_damage += tile.end_and_start_turn_damage
	char_node.noise += tile.end_and_start_turn_vol
	char_node.health += tile.end_and_start_turn_hp
	char_node.current_move_distance += tile.end_and_start_turn_move


func set_passthrough_tile_based_details(char_node, tile):
	print("setting passthrough buffs w/" + str(tile.description))
	char_node.current_atk_range += tile.passthrough_atk_range
	char_node.current_defense += tile.passthrough_defense
	char_node.current_attack += tile.passthrough_attack 
	char_node.current_damage += tile.passthrough_damage
	char_node.noise += tile.passthrough_vol
	char_node.health += tile.passthrough_hp
	char_node.current_move_distance += tile.passthrough_move


func check_if_in_pt_atk_range(enm=null):
	""" no enm val? then assume its for player """
	var player = get_node("/root/player")
	var moving_char = enm if enm else player
	var large_check_needed = false
	if not player and not enm:
		print("called check_if_in_pt_atk_range but not moving nodes found")
		return
	if moving_char == player:
		for enm in get_tree().get_nodes_in_group("enemies"):
			if enm.alive and enm.current_pt_dmg > 0:
				var tiles_in_range = meta.get_adjacent_tiles_in_distance(enm.current_tile, enm.current_pt_range, enm.atk_tile_pattern_name)
				for t in tiles_in_range:
					if t.index == player.current_tile.index:
						var attack_details = {
							"damage": player.current_pt_dmg,
							"attack_name": passthrough_atk_type
						}
						take_damage(player, attack_details, moving_char, false)
						return
	elif player.alive and player.current_pt_dmg > 0:
		var tiles_in_range = meta.get_adjacent_tiles_in_distance(player.current_tile, player.current_pt_range, "fill")
		for n in tiles_in_range:
			if n.index == moving_char.current_tile.index:
				var attack_details = {
					"damage": player.current_pt_dmg,
					"attack_name": passthrough_atk_type
				}
				take_damage(player, attack_details, moving_char, false)
				return


func generate_level_goal():
	return "destroy"


func spawn_new_level():
	can_spawn_level = false
	remove_enemies()
	if get_node("/root").has_node("player"):
		var p = get_node("/root/player")
		p.queue_free()
	var timer1 = Timer.new()
	timer1.set_wait_time(.5)
	timer1.set_one_shot(true)
	get_node("/root").add_child(timer1)
	timer1.start()
	yield(timer1, "timeout")
	timer1.queue_free()
	var l = get_node("/root/level")
	l.current_turn = 0
	l.randomize_level(l.random_lvl)
	#l.spawn_premade_tiles(l.random_lvl)
	spawn_enemies()
	main.current_screen = 'battle'


func spawn_enemies(amount=0):
	# base range on tiles, if we don't have a lot of tile we don't want a lot of animals
	# also maybe set tiles to spawn enms, so we can more easily just do as many as needed
	var l = get_node("/root/level")
	var enms = amount if amount > 0 else floor(rand_range(1,8))
	for idx in range(0, enms):
		randomize()
		#print("checking for enm  " + str(idx) + "...")
		for index in range(0, len(l.level_tiles) -1):
			var t = l.level_tiles[len(l.level_tiles) -1 -index]
			if t.spawn_enemies and not t.picked_for_spawn and t.tile_type != meta.EMPTY_TYPE:
				var e = main.ENEMY.instance()
				get_node("/root").add_child(e)
				e.id = idx
				e.char_type = meta.char_types[rand_range(0, len(meta.char_types) - 1)]
				e.char_name = e.char_type + " " + str(idx)
				e.spawn(t)
				t.picked_for_spawn = true
				#print("spawn_enm " + str(e) + " at tile " + str(t) + " (" + str(t.index) + ")")
				break

	main.current_screen = 'battle'


func spawn_item(level, spawn_tile):
	var item = main.ITEM_SCENE.instance()
	get_node("/root").add_child(item)
	item.position = spawn_tile.global_position
	spawn_tile.has_item = true



func map_char(enm_type, char_node):
	print("mapping " + str(enm_type))
	if enm_type == meta.BEAR_TYPE:
		var payload = {
				"name": enm_type,
				"move": classes.BEAR_BASE_MOVE,
				"attacks": classes.BEAR_BASE_ATTACKS,
				"attack_range": classes.BEAR_BASE_ATTACK_RANGE,
				"health": classes.BEAR_BASE_HEALTH,
				"defense": classes.BEAR_BASE_DEFENSE,
				"damage": classes.BEAR_BASE_DMG,
				"toughness": classes.BEAR_BASE_TOUGHNESS,
				"evasion": classes.BEAR_BASE_EVASION
			}
		set_base_stats(payload, char_node)
		classes.verify_char_stat_total(payload)
	elif enm_type == meta.DOG_TYPE:
		var payload = {
				"name": enm_type,
				"move": classes.DOG_BASE_MOVE,
				"attacks": classes.DOG_BASE_ATTACKS,
				"attack_range": classes.DOG_BASE_ATTACK_RANGE,
				"health": classes.DOG_BASE_HEALTH,
				"defense": classes.DOG_BASE_DEFENSE,
				"damage": classes.DOG_BASE_DMG,
				"toughness": classes.DOG_BASE_TOUGHNESS,
				"evasion": classes.DOG_BASE_EVASION
			}
		set_base_stats(payload, char_node)
		classes.verify_char_stat_total(payload)
	else:
		print("Enm type ("+str(enm_type)+") not mapped... Setting randomized stats for now")
		randomize()
		var payload = {
				"name": enm_type,
				"move": floor(rand_range(3, 8)),
				"attacks": floor(rand_range(1, 4)),
				"attack_range": floor(rand_range(1, 4)),
				"health": floor(rand_range(5, 30)),
				"defense": floor(rand_range(0, 15)),
				"damage": floor(rand_range(1, 4)),
				"toughness": floor(rand_range(0, 5)),
				"evasion": floor(rand_range(0, 3))
			}
		set_base_stats(payload, char_node)
		classes.verify_char_stat_total(payload)


func set_base_stats(payload, char_node):
	###### INIT base default stats
	# Set base stats (default_) then later use default_ to set..
	# in round stats (current_) and in battle stats (current_battle_)
	char_node.default_attack = payload["attacks"]
	char_node.default_atk_range = payload["attack_range"]
	char_node.default_damage = payload["damage"]
	char_node.default_health = payload["health"]
	char_node.default_energy = 3
	char_node.default_defense = payload["defense"]
	char_node.default_toughness = payload["toughness"]
	char_node.default_evasion = payload["evasion"]
	char_node.default_distance = payload["move"]
	########
	
	# Set in round stats (current_) and in battle stats (current_battle_) ..
	# .. Based on character's base stats (default_)
	
	# HEALTH / MOVE #
	char_node.current_move_distance = char_node.default_distance
	char_node.current_battle_move_distance = char_node.default_distance

	char_node.health = char_node.default_health
	char_node.current_battle_health  = char_node.default_health

	### ATK / DMG / ATK RANGE ###
	char_node.current_attack = char_node.default_attack
	char_node.current_battle_attack = char_node.default_attack

	char_node.current_damage = char_node.default_damage
	char_node.current_battle_damage = char_node.default_damage
	
	char_node.current_atk_range = char_node.default_atk_range
	char_node.current_battle_atk_range = char_node.default_atk_range

	#### DEF / TOUGHNESS / EVASION####
	# DEF does not regen (like armor breaking)
	## toughness regenerates each round (like regaining composure, hydrating, salve/bandges, or idk.. magic, etc, )
	char_node.current_defense = char_node.default_defense
	char_node.current_battle_defense = char_node.default_defense
	
	char_node.current_toughness = char_node.default_toughness
	char_node.current_battle_toughness = char_node.default_toughness

	char_node.current_evasion = char_node.default_evasion
	char_node.current_battle_evasion = char_node.default_evasion
	##### MISC #####
	char_node.energy = char_node.default_energy



func set_default_round_stats(char_node):
	char_node.current_attack = char_node.default_attack - char_node.battle_attack_debuff
	char_node.current_damage = char_node.default_damage - char_node.battle_damage_debuff
	char_node.current_defense = char_node.default_defense - char_node.battle_defense_debuff
	char_node.current_toughness = char_node.default_toughness - char_node.battle_toughness_debuff
	char_node.current_evasion = char_node.default_evasion - char_node.battle_evasion_debuff
	char_node.current_atk_range = char_node.current_atk_range
	char_node.current_move_distance = char_node.default_distance - char_node.battle_move_debuff
	char_node.energy = char_node.default_energy - char_node.battle_energy_debuff


func check_if_in_op_atk_range(enm=null):
	""" no enm val? then assume its for player """
	var player = get_node("/root/player")
	var moving_char = enm if enm else player
	var large_check_needed = false
	if not player and not enm:
		print("called check_if_in_op_atk_range but not moving nodes found")
		return
	if moving_char == player:
		for enm in get_tree().get_nodes_in_group("enemies"):
			if enm.alive and enm.current_opportunity_attacks > 0:
				var tiles_in_range = meta.get_adjacent_tiles_in_distance(enm.current_tile, enm.current_atk_range, enm.atk_tile_pattern_name)
				for t in tiles_in_range:
					if t.index == player.current_tile.index:
						#check_if_player_attackable()
						#get_tree().paused = true
						player.get_node("cam_body/cam").current = false
						enm.get_node("cam_body/cam").current = true
						enm.handle_overheard_text("Opportunity Attack...", true)
						enm.enm_specific_attack_details()
						var tmr = main.make_timer(enm.atk_anim_delay)
						tmr.start()
						yield(tmr, "timeout")
						tmr.queue_free()
						
						if enm.current_opportunity_attacks > 0:
							attack(enm, player, false, opportunity_atk_type)
							enm.current_opportunity_attacks -= 1
						if enm.current_opportunity_attacks < 0:
							enm.current_opportunity_attacks = 0
						enm.handle_overheard_text("", false)
			
						var timer1 = main.make_timer(enm.between_atk_delay)
						timer1.start()
						yield(timer1, "timeout")
						timer1.queue_free()

						player.get_node("cam_body/cam").current = true
						if enm and main.checkIfNodeDeleted(enm) == false:
							enm.get_node("cam_body/cam").current = false
						return
	elif player.alive and player.current_opportunity_attacks > 0:
		var tiles_in_range = meta.get_adjacent_tiles_in_distance(player.current_tile, player.current_atk_range, "fill")
		for n in tiles_in_range:
			if n.index == moving_char.current_tile.index:
				print("p op atks: " + str(player.current_opportunity_attacks))
				var remaining_atks = player.current_opportunity_attacks

				var pre_atk_timer = main.make_timer(.50)
				pre_atk_timer.start()
				yield(pre_atk_timer, "timeout")
				pre_atk_timer.queue_free()

				if player.current_opportunity_attacks > 0:
					player.attack(moving_char, false, opportunity_atk_type)
					player.current_opportunity_attacks -= 1
				if player.current_opportunity_attacks < 0:
					player.current_opportunity_attacks = 0

				var timer1 = main.make_timer(.25)
				timer1.start()
				yield(timer1, "timeout")
				timer1.queue_free()

				print("p op2 atks: " + str(player.current_opportunity_attacks))
				return


func reset_char_sprite_pos(char_sprite):
	char_sprite.position = Vector2(-5, -75)


func remove_enemies():
	for enm in get_tree().get_nodes_in_group("enemies"):
		enm.remove_enemy()


func set_turn_order_info():
	var max_chars = 5
	var turn_order = []
	var l = get_node("/root/level")
	l.remove_icons()
	l.round_turn_icons = []
	if meta.player_turn:
		var icon = main.CHAR_HUD_ICON.instance()
		get_node("/root").add_child(icon)
		icon.get_node("title").set_text("Player")
		l.round_turn_icons.append(icon)

	#for enm_round in l.round_turns:
	for enm in get_tree().get_nodes_in_group("enemies"):
		if enm.alive:
			var icon = main.CHAR_HUD_ICON.instance()
			get_node("/root").add_child(icon)
			icon.get_node("title").set_text(enm.char_name)
			l.round_turn_icons.append(icon)
	
	if !meta.player_turn:
		var icon = main.CHAR_HUD_ICON.instance()
		get_node("/root").add_child(icon)
		icon.get_node("title").set_text("Player")
		turn_order.append(icon)
		l.round_turn_icons.append(icon)



func reset_graphics_and_overlays(keep_popouts=false, tile=null):
	var l = get_node("/root/level")
	var player = get_node("/root/player")
	if player and player.has_node("cam_body/cl/text_overlay_node"):
		player.get_node("cam_body/cl/text_overlay_node/tile_text").set_text("")
	for t in l.level_tiles:
		t.modulate = Color(1, 1, 1, 1)
		if t.get_node("popout_container").visible:
			t.get_node("popout_container").visible = keep_popouts
			t.displaying_popout = keep_popouts
		else:
			t.displaying_popout = false
			t.get_node("popout_container").visible = false
		if t.tile_type != WATER_TYPE:
			t.get_node("AnimationPlayer").stop()
		t.get_node("background").modulate = t.default_background_color
		t.get_node("Sprite").modulate = Color(1, 1, 1, 1)
		t.z_index = 0
	if tile:
		tile.displaying_popout = true
		tile.get_node("popout_container").visible = true
	#for enm in get_tree().get_nodes_in_group("enemies"):
	#	enm.z_index = 5
	l.change_turn_display_name(player)


func set_char_anims(char_node, char_action, char_current_tile, char_target_tile):
	var target_tile_dif_row = abs(char_current_tile.row - char_target_tile.row)
	var target_tile_dif_col = abs(char_current_tile.col - char_target_tile.col)

	if char_action == "move":
		# cardinal directions only
		if char_current_tile.row == char_target_tile.row or\
			char_current_tile.col == char_target_tile.col:
				# moving horizontal
				if target_tile_dif_row > target_tile_dif_col:
					# moving right
					if char_current_tile.row < char_target_tile.row:
						char_node.facing_dir = "bl_"
						return "fr_walk_anim"
					else: # moving left
						char_node.facing_dir = "fr_"
						return "bl_walk_anim"
				else: # moving vertical
					# if moving down
					if char_current_tile.col < char_target_tile.col:
						char_node.facing_dir = "br_"
						return "fl_walk_anim"
					else: # if moving up
						char_node.facing_dir = "fl_"
						return "br_walk_anim"
		else: # moving at a diagnol

			# TODO: Below is just copied to use same anims
				# moving mostly horizontal
				if target_tile_dif_row > target_tile_dif_col:
					# moving right
					if char_current_tile.row < char_target_tile.row:
						char_node.facing_dir = "fr_"
						return "fr_walk_anim"
					else: # moving left
						char_node.facing_dir = "bl_"
						return "bl_walk_anim"
				else: # moving vertical
					# if moving down
					if char_current_tile.col < char_target_tile.col:
						char_node.facing_dir = "fl_"
						return "fl_walk_anim"
					else: # if moving up
						char_node.facing_dir = "br_"
						return "br_walk_anim"


func get_tile_in_line_from_target_tile(char_node, dist, start_tile, dir="horizontal"):
	### FIX THIS FILE
	var l = get_node("/root/level")
	var idx = -1
	var tile_found_in_dist = 0
	for t in l.level_tiles:
		if t.row == start_tile.row or t.col == start_tile.col: # must ensure we don't hit the A* logic to move around stuff, so stay in line
			tile_found_in_dist += 1
			char_node.path.append(t)
			if t.tile_type != WATER_TYPE:
				t.get_node("AnimationPlayer").stop()
			if len(char_node.path) > char_node.current_move_distance:
				pass
			elif t.can_move:
				char_node.path.append(t)
	if tile_found_in_dist >= dist:
		pass
	#var point_path = l.level_astar.get_id_path(start_tile.index, target_tile.index)


func knockback(dist, attacker, defender):
	var l = get_node("/root/level")
	#get_tile_in_line_from_target_tile(defender, dist, defender.current_tile)
	#get_adjacent_tiles_in_distance(defender, )


func roll_dice(successes_needed=0, roll_target=0, dice=[], chosen_tile=null):
	randomize()
	var min_roll = die["values"][0]
	var max_roll = die["values"][len(die["values"])-1]
	var successes = 0
	var total_dice_val_difference = 0
	var total_rolled = 0
# warning-ignore:unused_variable
	var player = get_node("/root/player")
	for die in dice:
		var result = die["values"][round(rand_range(0, len(die["values"]) - 1))]
		var accuracy_mod = 0
		print("Rolling a " + str(die))
		if chosen_tile and accuracy_mod != 0:
			print("\nResult is: " + str(result))
			result += accuracy_mod
			print("adding accuracy mod. Result: " + str(result))
		for tag in die["tags"]:
			if "+1 Accuracy" in tag:
				result += 1
			elif "-1 Accuracy" in tag:
				result -= 1
		print("before correction roll result: " + str(die))
		if result < min_roll:
			result = min_roll
		if result > max_roll:
			result = max_roll
		die["roll_result"] = result
	for die in dice:
		total_rolled += die["roll_result"]
		if die["roll_result"] >= roll_target:
			successes += 1
		total_dice_val_difference = roll_target - die["roll_result"]

	return {"success": successes >= successes_needed, "hit_difference": total_dice_val_difference, "dice": dice, "total": total_rolled}


func take_damage(attacker, attack_details, defender, is_player=false):
	if not defender or not defender.alive\
	   or not attacker or not attacker.alive:
		return 0
	var player = get_node("/root/player")
# warning-ignore:unused_variable
	var l = get_node("/root/level")
	var current_damage = int(attack_details["damage"]) if attack_details["damage"] else 0
	var hold_defense = defender.current_defense
	var attacker_facing = attacker.get_node("Sprite").name.split("_")[0]
	var defender_facing = defender.get_node("Sprite").name.split("_")[0]
	
	if hold_defense < 0: hold_defense = 0
	if not is_player and player != defender and not player.invisible:
		defender.chasing_player = true
	if defender.current_defense > 0:
		defender.current_defense -= current_damage
		current_damage -= hold_defense

	defender.health -= current_damage
	print(attacker.char_name + ' attacked ' + defender.char_name + ' for ' + str(attack_details["damage"]))
	if defender.health <= 0:
		if not is_player:
			defender.defeat_enemy()
		else:
			print("player is dead")
	return current_damage if current_damage else 0


# warning-ignore:unused_argument
func get_char_dmg(attacker, defender):
	var roll_result = roll_dice(0, 0, [die])
	var dmg = roll_result["total"] #attacker.current_damage
	#if attacker.stealth: dmg += attacker.stealth_dmg_bonus
	return floor(dmg + attacker.current_damage)


func is_target_in_range(attacker, target):
	var is_in_attack_range = false
	var adjacent_tiles_in_range = meta.get_adjacent_tiles_in_distance(attacker.current_tile, attacker.current_atk_range+attacker.chosen_skill_atk_range, "fill")
	for tile in adjacent_tiles_in_range:
		if target.current_tile.index == tile.index:
			is_in_attack_range = true
	return is_in_attack_range

func attack(attacker, defender, player_attacking=false, attack_name="Standard"):
	""" Check tile, see if enemy is there and we are in range, if so attack (keep
		stats if we want to undo the attack) ELSE do the move to tile stuff
	"""
	var player = get_node("/root/player")
	var hit = false

	if not is_target_in_range(attacker, defender):
		return false

	var attack_details = {
		"damage": get_char_dmg(attacker, defender),
		"attack_name": attack_name
	}
	if attacker.can_atk and attacker.current_attack > 0 and main.checkIfNodeDeleted(defender) == false and defender.alive:
		attacker.can_atk = false
		attacker.current_attack -= 1
		hit = true
		var dmg_taken = take_damage(attacker, attack_details, defender, not player_attacking)
		defender.get_node("AnimationPlayer").stop()
		if dmg_taken <= 0:
			dmg_taken = 0
			defender.get_node("AnimationPlayer").play("attack_dodged")
		else:
			defender.get_node("AnimationPlayer").play("hurt")
			var shake_vel = attack_details["damage"]
			if shake_vel < 5:
				shake_vel = 5
			elif shake_vel > 20:
				shake_vel = 20
			main.cameraShake(attacker.get_node("cam_body/cam"), shake_vel, .4)
			var dmg_effect = main.DMG_EFFECT_SCENE.instance()
			get_node("/root").call_deferred("add_child", dmg_effect)
			dmg_effect.position = defender.global_position
			dmg_effect.set_new_text("-"+str(attack_details["damage"]), dmg_effect.hurt_red_color)

		var l = get_node("/root/level")
		l.change_turn_display_name(defender)
		
	var l = get_node("/root/level")
	if main.checkIfNodeDeleted(l) == false:
		if l.is_player_stealth():
			player.get_node("cam_body/cam/overlays and underlays/stealth_overlay").visible = true
			player.get_node("cam_body/cam/overlays and underlays/chased_overlay").visible = false
		else:
			player.get_node("cam_body/cam/overlays and underlays/stealth_overlay").visible = player.invisible
			player.get_node("cam_body/cam/overlays and underlays/chased_overlay").visible = not player.invisible
	attacker.reset_can_atk()
	return hit

func get_vol_range(is_player=true, node_making_noise=null):
	if not node_making_noise:
		return
# warning-ignore:unused_variable
	var val = 0
	if is_player:
		if node_making_noise.stealh: val -= node_making_noise.stealth_noise_val
	return 

func get_character_display_text(character):
# warning-ignore:unused_variable
	var character_node = character
	var char_name = str(character.char_name)
	var character_stats = " -- " + str(character.char_name) + " -- "
	var additional_details = ""
	# additional_details are anything else we want to show, status effects, even if they are more "character stats"
	# they are just not the 'main' ones
	if character.IS_PLAYER:
		character_node = character_node.get_node("cam_body/cl")
		character_node.get_node("card/type_text").set_text("- "+str(character.char_type))
	character_node.get_node("card/health_text").set_text(str(character.health))
	character_node.get_node("card/name_text").set_text("- "+str(character.char_name))
	character_node.get_node("card/atk_dmg_text").set_text(str(character.current_attack) + "/" + str(character.current_battle_attack)+" * ("+str(character.current_damage)+") ")
	character_node.get_node("card/def_text").set_text(str(character.current_defense) + "/" + str(character.current_battle_defense))
	character_node.get_node("card/def_text").set_text(str(character.current_toughness) + "/" + str(character.current_battle_toughness))
	character_node.get_node("card/misc_text").set_text(str(character.current_move_distance) + "/" + str(character.current_battle_move_distance))
	character_node.get_node("card/move_dist").set_text(str(character.current_move_distance) + "/" + str(character.current_battle_move_distance))
	
	
	# character_stats += "\nHP: " + str(character.health)
	# if character.health < character.starting_turn_health:
	#character_stats += " / " + str(character.starting_turn_health)
	#character_stats += " ---- DEF: " + str(character.current_defense)
	#character_stats += " / " + str(character.current_battle_defense)

	character_stats += "\nEnergy: " + str(character.energy)
	#if character.energy < character.default_energy:
	character_stats += " / " + str(character.default_energy)

	character_stats += " ---- Move: " + str(character.current_move_distance)
	#if character.current_battle_move_distance < character.remaining_move:
	character_stats += " / " + str(character.current_battle_move_distance)
	
	character_stats += "\nATK: " + str(character.current_attack)
	#if character.current_attack < character.current_battle_attack:
	character_stats += " / " + str(character.current_battle_attack)

	character_stats += " ---- DMG: " + str(character.current_damage)
	#if character.current_damage < character.current_battle_damage:
	character_stats += " / " + str(character.current_battle_damage)
	
	if meta.player_turn:
		additional_details += "\nNOISE: " + str(character.noise) + " tile radius."
	#return [character_stats, additional_details]



func get_adjacent_tiles_in_distance(tile=null, distance=1, type="fill"):
	if not tile:
		return null
	var l = get_node("/root/level")
	var all_adjacent_tiles = []
	var tile_count = len(l.level_tiles)
	var tile_index = tile.index
	
	# Fill all adjacent
	# cross up down left right
	# star all directions but not inbetween tiles
	
	if type == "fill":
		for t in l.level_tiles:
			if t.col >= tile.col - distance and t.col <= tile.col + distance and\
			   t.row >= tile.row - distance and t.row <= tile.row + distance:
				all_adjacent_tiles.append(t)

	else:
		for i in range(1, distance+1):
# warning-ignore:unused_variable
			var point_neighbors = []
			#point_neighbors = l.level_astar.get_point_connections(tile.index)
			var above_tile_idx = tile_index - (l.current_rows * i)
			var above_right_tile_idx = tile_index - (l.current_rows * i) + i
			var above_left_tile_idx = tile_index - (l.current_rows * i) - i
	
			var right_tile_idx = tile_index + i
			var below_tile_idx = tile_index + (l.current_rows * i)
			var below_right_tile_idx = tile_index + (l.current_rows * i) + i
			var below_left_tile_idx = tile_index + (l.current_rows * i) - i
		
			var left_tile_idx = tile_index - i
			# print('above_tile_idx ' + str(above_tile_idx))
			if tile.col > - 1 + i and above_tile_idx >= 0 and above_tile_idx < tile_count and main.checkIfNodeDeleted(l.level_tiles[above_tile_idx]) == false:
				all_adjacent_tiles.append(l.level_tiles[above_tile_idx])
			if type == "fill" or type == "star":
				if tile.col > - 1 + i and tile.row < l.current_rows-i and above_right_tile_idx >= 0 and above_right_tile_idx < tile_count and main.checkIfNodeDeleted(l.level_tiles[above_right_tile_idx]) == false:
					all_adjacent_tiles.append(l.level_tiles[above_right_tile_idx])
		
				if tile.col > - 1 + i and tile.row > -1 + i and above_left_tile_idx >= 0 and above_left_tile_idx < tile_count and main.checkIfNodeDeleted(l.level_tiles[above_left_tile_idx]) == false:
					all_adjacent_tiles.append(l.level_tiles[above_left_tile_idx])
	
			if tile.row < l.current_rows-i and right_tile_idx >= 0 and right_tile_idx < tile_count and main.checkIfNodeDeleted(l.level_tiles[right_tile_idx]) == false:
				all_adjacent_tiles.append(l.level_tiles[right_tile_idx])
		
			if tile.col < l.current_cols-i and below_tile_idx >= 0 and below_tile_idx < tile_count and main.checkIfNodeDeleted(l.level_tiles[below_tile_idx]) == false:
				all_adjacent_tiles.append(l.level_tiles[below_tile_idx])
			
			if type == "fill" or type == "star":
				if tile.col > - 1 + i and tile.row < l.current_rows-i and below_right_tile_idx >= 0 and below_right_tile_idx < tile_count and main.checkIfNodeDeleted(l.level_tiles[below_right_tile_idx]) == false:
					all_adjacent_tiles.append(l.level_tiles[below_right_tile_idx])
		
				if tile.col > - 1 + i and tile.row > -1 + i and below_left_tile_idx >= 0 and below_left_tile_idx < tile_count and main.checkIfNodeDeleted(l.level_tiles[below_left_tile_idx]) == false:
					all_adjacent_tiles.append(l.level_tiles[below_left_tile_idx])
		
			if tile.row > -1 + i and left_tile_idx >= 0 and left_tile_idx < tile_count and main.checkIfNodeDeleted(l.level_tiles[left_tile_idx]) == false:
				all_adjacent_tiles.append(l.level_tiles[left_tile_idx])
		
	return all_adjacent_tiles


func get_closest_adjacent_tile(starting_node, target_node, random=false, is_player=false):
	""" Get closest tile based on adjacent tiles. target_node needs to be a tile """
	var lowest_cost = null
	var hold_tile = null
	var found_tile = null
	var target_tile = null
	var rand_list = []
	var player = get_node("/root/player")
	for n in target_node.neighbors:
		if n.can_move:
			if random:
				if not is_player and player and player.current_tile.index != n.index:
					rand_list.append(n)
				for next_n in n.neighbors:
					if not is_player and player and player.current_tile.index != next_n.index:
						rand_list.append(next_n)
			else:
				if hold_tile == null:
					hold_tile = n
				if lowest_cost == null or starting_node.global_position.distance_to(n.global_position) <= lowest_cost:
					lowest_cost = starting_node.global_position.distance_to(n.global_position)
					found_tile = n
	
	if random and len(rand_list) > 0:
		target_tile = rand_list[rand_range(0, len(rand_list))]
	elif found_tile != null:
		target_tile = found_tile
	elif hold_tile != null:
		target_tile = hold_tile

	return target_tile


func loadClassDetails(classDict):
	
	# overwrite class details in meta.CharacterClass
	pass
