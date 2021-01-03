extends Node

const debug = false # for dev


# TILES
const BASIC_TILE = preload("res://Sprites/tiles/basic/new border grey tile.png")
const WALL_TILE = preload("res://Sprites/tiles/basic/dark tile.png")

const ENEMY_SPAWN_TILE = preload("res://Sprites/tiles/basic/new border grey tile.png")
const PLAYER_SPAWN_TILE = preload("res://Sprites/tiles/basic/new border grey tile.png")

const FOREST_PATH_TILE_1 = preload("res://Sprites/tiles/environment/forest path til.png")
const FOREST_TILE_1 = preload("res://Sprites/tiles/environment/forest tile 1.png")
const FOREST_TILE_2 = preload("res://Sprites/tiles/environment/forest tile 2.png")


var basic_forest_tiles = [FOREST_TILE_1, FOREST_TILE_2]
var special_forest_tiles = [FOREST_PATH_TILE_1]

const MOUNTAIN_TILE = preload("res://Sprites/tiles/basic/new border grey tile.png")
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
	if Input.is_action_pressed("start"): 
		if current_screen == 'main_menu':
			handle_main_menu_input("start")
		elif current_screen == "battle":
			handle_in_battle_input("start")
			#get_node("/root/main_menu").visible = false
	if Input.is_action_pressed("back"):
		if current_screen == "battle":
			handle_in_battle_input("back")
	elif Input.is_action_pressed("spacebar"):
		if current_screen == "battle":
			handle_in_battle_input("spacebar")


func handle_in_battle_input(action):
	if action == "start":
		var level = get_node("/root/level")
		level.end_turn()
	elif action == "back": 
		if meta.player_turn:
			if not get_node("/root").has_node("player"):
				return
			var player = get_node("/root/player")
			player.reset_turn()
	elif action == "spacebar":
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


func handle_main_menu_input(action):
	if action == "start":
		var l = LEVEL.instance()
		get_node("/root").add_child(l)
		l.set_random_level(l.random_lvl)
		l.spawn_premade_tiles(l.random_lvl)
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


func cameraShake(mag, length):
	randomize()
	if not get_node("/root").has_node("cam"):
		return
	var cam = get_node("/root/cam")
	var magnitude = mag if mag <= 10 else 10
	var timeToShake = length if length <= 4 else 4
	if shaking:
		return
	while timeToShake > 0:
		shaking = true
		var pos = Vector2()
		pos.x = rand_range(-magnitude, magnitude)
		pos.y = rand_range(-magnitude, magnitude)
		cam.position = pos
		timeToShake -= get_process_delta_time()

		var timer = Timer.new()
		timer.set_wait_time(.015)
		timer.set_one_shot(true)
		addToParent(timer, null, true)
		timer.start()
		yield(timer, "timeout")
		timer.queue_free()

	magnitude = 0
	shaking = false


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
