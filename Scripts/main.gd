extends Node

const debug = false # for dev


# TILES
const BASIC_TILE = preload("res://Sprites/tiles/new style/standard/standard grass tile.png")
const WALL_TILE = preload("res://Sprites/tiles/new style/unique/standard water tile.png")

const ENEMY_SPAWN_TILE = preload("res://Sprites/tiles/new style/unique/enm spawn tile.png")
const PLAYER_SPAWN_TILE = preload("res://Sprites/tiles/new style/standard/bright tile.png")

const FOREST_PATH_TILE_1 = preload("res://Sprites/tiles/new style/unique/rock tile.png")
const WATER_TILE_1 = preload("res://Sprites/tiles/new style/unique/standard water tile.png")
const WATER_TILE_2 = preload("res://Sprites/tiles/new style/unique/standard water tile.png")

const DMG_EFFECT_SCENE = preload("res://Scenes/dmgEffect.tscn")

var basic_water_tiles = [WATER_TILE_1, WATER_TILE_2]
var special_forest_tiles = [FOREST_PATH_TILE_1]

const MOUNTAIN_TILE = preload("res://Sprites/tiles/new style/standard/mid tile.png")
#######


const LEVEL = preload("res://Scenes/level.tscn")
const TILE = preload("res://Scenes/tile.tscn")
const ENEMY = preload("res://Scenes/enemy.tscn")
const PLAYER = preload("res://Scenes/player.tscn")
#### SAVE LOAD VARS
var game_name = 'game_name'
var playerFilepath = "user://" + str(game_name) + "_playerData_.data"
var dataFilepath = "user://" + str(game_name) + "_gameData_.data"
# Game data like preferred settings, global stats like playTime, gloal/continous scoring, e.c.t, ..
var gameData = {

	}

# Player specific settings like score, class, health e.c.t..
var playerData = {
	}
#### END OF SAVE LOAD VARS


#### MENU VARS
const popupMenu = preload("res://Scenes/popupMenu.tscn")
var holdMenu = null
var waitToProcessMenuClick = false
var optionsMenu = null
var confirmOptionMenu = null
var goToMainMenu = false
var shouldQuit = false

var shaking = false

var current_screen = 'main_menu'
#### END OF MENU VARS

#### CONTROLLER
var useController = true
var controllerCursorObj = false
#### END OF CONTROLLER

var zoom_increment = .2
var cam_move_vel = 50
#### MAIN READY/PROCESS
#func _ready():
#	pass


#func _process(delta):
#	pass
#### END OF MAIN READY/PROCESS



#### SAVE LOAD FUNCS
var debug_remove_save_file = true

func loadGameData(onlyGameData=false):
	print("loading...")
	var file = File.new()
	if file.file_exists(dataFilepath) and not debug_remove_save_file:
		file.open(dataFilepath, File.READ)
		gameData = file.get_var()
		file.close()
		print("loaded " + str(dataFilepath))
	elif debug_remove_save_file and game_name in dataFilepath:
		var dir = Directory.new()
		dir.remove(dataFilepath)
		print('removed save dataFilepath, does it exist? ' + str(file.file_exists(dataFilepath)))
	else:
		print(str(dataFilepath) + " not found.")
	pass

func loadPlayerData(onlyGameData=false):
	print("loading...")
	var file = File.new()
	if file.file_exists(playerFilepath):
		file.open(playerFilepath, File.READ)
		playerData = file.get_var()
		file.close()
		print("loaded " + str(playerFilepath))
	else:
		print(str(playerFilepath) + " not found.")
	pass

func saveGameData():
	print("Saving... " + str(dataFilepath))
	var file = File.new()
	file.open(dataFilepath, File.WRITE)
	file.store_var(gameData)
	file.close()
	print("saved " + str(dataFilepath))
	pass

func savePlayerData():
	print("Saving... " + str(playerFilepath))
	var file = File.new()
	file.open(dataFilepath, File.WRITE)
	file.store_var(playerData)
	file.close()
	print("Saved " + str(playerFilepath))
	pass

#### END OF SAVE LOAD FUNCS



#### INPUT FUNCS #MOVE TO INPUT ONLY NODE/SCRIPT

func _input(event):
   # Mouse in viewport coordinates
	if Input.is_action_pressed("ui_quit"): 
		handle_main_menu_input("ui_quit")
	elif Input.is_action_pressed("start"): 
		if current_screen == 'main_menu':
			handle_main_menu_input("start")
		elif current_screen == "battle":
			handle_in_battle_input("start")
			#get_node("/root/main_menu").visible = false
	elif Input.is_action_pressed("back"):
		if current_screen == "battle":
			handle_in_battle_input("back")
	elif Input.is_action_pressed("spacebar"):
		if current_screen == "battle":
			handle_in_battle_input("spacebar")
	elif Input.is_action_pressed("scroll_forward"):
		if current_screen == "battle":
			handle_in_battle_input("scroll_forward")
	elif Input.is_action_pressed("scroll_back"):
		if current_screen == "battle":
			handle_in_battle_input("scroll_back")
	elif Input.is_action_pressed("up"):
		if current_screen == "battle":
			handle_in_battle_input("up")
	elif Input.is_action_pressed("down"):
		if current_screen == "battle":
			handle_in_battle_input("down")
	elif Input.is_action_pressed("left"):
		if current_screen == "battle":
			handle_in_battle_input("left")
	elif Input.is_action_pressed("right"):
		if current_screen == "battle":
			handle_in_battle_input("right")


func handle_in_battle_input(action):
	if action == "start":
		var level = get_node("/root/level")
		level.end_turn()
	elif action == "scroll_forward":
		if get_node("/root").has_node("player"):
			var player = get_node("/root/player")
			if player.get_node("cam_body/cam").zoom.x > .5:
				player.get_node("cam_body/cam").zoom.x -= zoom_increment
				player.get_node("cam_body/cam").zoom.y -= zoom_increment
				var overlay = player.get_node("cam_body/cam/overlays and underlays")
				overlay.set_scale(player.get_node("cam_body/cam").zoom)
	elif action == "scroll_back":
		if get_node("/root").has_node("player"):
			var player = get_node("/root/player")
			if player.get_node("cam_body/cam").zoom.x < 1.5:
				player.get_node("cam_body/cam").zoom.x += zoom_increment
				player.get_node("cam_body/cam").zoom.y += zoom_increment
				var overlay = player.get_node("cam_body/cam/overlays and underlays")
				overlay.set_scale(player.get_node("cam_body/cam").zoom)
	elif action == "back": 
		if meta.player_turn:
			if not get_node("/root").has_node("player"):
				return
			var player = get_node("/root/player")
			player.reset_turn()
	elif action == "spacebar":
		if meta.can_spawn_level:
			meta.can_spawn_level = false
			meta.remove_enemies()
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
			l.randomize_level(l.random_lvl)
			#l.spawn_premade_tiles(l.random_lvl)
			current_screen = 'battle'
		##### old below
		"""
		for enm in get_tree().get_nodes_in_group("enemies"):
			enm.queue_free()
		if get_node("/root").has_node("player"):
			var p = get_node("/root/player")
			p.queue_free()
		for lvl in get_tree().get_nodes_in_group("levels"):
			lvl.remove_tiles()
			lvl.queue_free()
		var timer1 = Timer.new()
		timer1.set_wait_time(1.5)
		timer1.set_one_shot(true)
		get_node("/root").add_child(timer1)
		timer1.start()
		yield(timer1, "timeout")
		timer1.queue_free()
		var l = LEVEL.instance()
		get_node("/root").add_child(l)
		l.set_random_level(l.random_lvl)
		l.spawn_premade_tiles(l.random_lvl)
		current_screen = 'battle'
		"""
	if action == "up":
		if get_node("/root").has_node("player"):
			var p = get_node("/root/player")
			p.get_node("cam_body").position.y -= round(cam_move_vel * .5)
	elif action == "down":
		if get_node("/root").has_node("player"):
			var p = get_node("/root/player")
			p.get_node("cam_body").position.y += round(cam_move_vel * .5)
	if action == "left":
		if get_node("/root").has_node("player"):
			var p = get_node("/root/player")
			p.get_node("cam_body").position.x -= round(cam_move_vel * .5)
	elif action == "right":
		if get_node("/root").has_node("player"):
			var p = get_node("/root/player")
			p.get_node("cam_body").position.x += round(cam_move_vel * .5)


func make_timer(time=0):
	var timer = Timer.new()
	timer.set_wait_time(time)
	timer.set_one_shot(true)
	get_node("/root").add_child(timer)
	return timer



func handle_main_menu_input(action):
	if action == "start":
		# OLD
		#var l = LEVEL.instance()
		#get_node("/root").add_child(l)
		#l.set_random_level(l.random_lvl)
		#l.spawn_premade_tiles_old(l.random_lvl)
		#current_screen = 'battle'
		
		# NEW
		var l = LEVEL.instance()
		get_node("/root").add_child(l)
		l.set_full_level(l.random_lvl)
		l.spawn_premade_tiles(l.random_lvl, false, meta.course_1)
		current_screen = 'battle'
	elif action == "ui_quit":
		if not waitToProcessMenuClick:
			waitToProcessMenuClick = true
			for btns in get_tree().get_nodes_in_group("btnsToRemove"):
				btns.queue_free()
			holdMenu = main.instancer(popupMenu, null, true, "btnsToRemove")
			# Adding wait to avoid multi clicks
			var timer = Timer.new()
			timer.set_wait_time(.5)
			timer.set_one_shot(true)
			addToParent(timer, null, true)
			timer.start()
			yield(timer, "timeout")
			timer.queue_free()
			# end of wait
			waitToProcessMenuClick = false
#### END OF INPUT FUNCS


#### HELPER FUNCS
func checkIfNodeDeleted(nodeToCheck, eraseNode=false):
	if 'Deleted' in str(nodeToCheck) or 'Object:0' in str(nodeToCheck):
		if eraseNode:
			print('should erase?')
		return true
	return false

# add nodes to check wether we should allowing clicking
func canClick(nodesAsStrIfDefinedClickIsFalse=[], parentToCheck=get_node("/root")):
	for node in nodesAsStrIfDefinedClickIsFalse:
		if parentToCheck.has_node(node):
			return false
	return true


func saveAndQuit(shouldSave=true):
	if shouldSave:
		pass
	get_tree().quit()


func cameraShake(cam, mag, timeToShake):
	randomize()
	if not get_node("/root").has_node("player"):
		return
	meta.can_spawn_level = false
	if shaking:
		return
	while timeToShake > 0:
		shaking = true
		var pos = Vector2()
		pos.x = rand_range(-mag, mag)
		pos.y = rand_range(-mag, mag)
		if cam and checkIfNodeDeleted(cam) == false:
			cam.position = pos
		timeToShake -= get_process_delta_time()

		var timer = Timer.new()
		get_node("/root").add_child(timer)
		timer.set_wait_time(.015)
		timer.set_one_shot(true)
		timer.start()
		yield(timer, "timeout")
		timer.queue_free()

	shaking = false
	meta.can_spawn_level = true


func instancer(objToInstance=null, parent=null, addDeferred=false, addToThisGroup=null, returnObj=true):
	# Check for accurate data
	if objToInstance != null:
		var newObj = objToInstance.instance()

		## add Specific parent or swap to root
		addToParent(newObj, parent, addDeferred)
		
		## add this obj to group if we wanted to
		if addToThisGroup != null:
			newObj.add_to_group(addToThisGroup)
		
		# Return Object back
		if returnObj:
			return newObj

	# Give feedback for issues
	else:
		print("Failed object is: " + str(objToInstance))


func addToParent(objRecievingParent=null, parent=null, addDeferred=false):
	var root = get_tree().get_root()
	# Check for accurate data
	if objRecievingParent != null:

		## If no parent given use root node
		if parent == null:
			parent = root

			### check if it already has  parent
			if not objRecievingParent.get_parent():

				#### Check if calling deferred or not
				if addDeferred:
					parent.call_deferred("add_child", objRecievingParent)
				else:
					parent.add_child(objRecievingParent)

	# Give feedback for issues
	else:
		print("Failed attempting to add a parent to: " + str(objRecievingParent))

#### END OF HELPER FUNCS
