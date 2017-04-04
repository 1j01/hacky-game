
Player = require "./ents/Player"

rooms =
	"the second room":
		tiles: """
		              ■▩
		              ■▩
		▬■■◤          ■▩
		              ■▩
		              ■▩
		▬    ◢■■■■  ■■■▩
		    ◢■▩▩▩■  ■▩▩▩
		■■■■■■▩▩▩■  ■▩▩▩
		""" # ■▩▬◢◤◥◣◫
		# TODO: define spawn points for OtherworldlyDoors and enemies in the world data
		# with single-character IDs ("ABC...")
		# or with a level editor
		ents: [
			{id: 2, x: 3, y: 1, type: "Door", to: "the third room"}
			{id: 0, x: 2, y: 1, type: "Enemy"}
		]
	"the third room":
		tiles: """
			■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
			■                                                                         ■
			■                                                                         ■
			■                                                                         ■
			■                                                                         ■
			■                                                                         ■
			■                                                                         ■
			■                               ◣                                         ■
			■                               ◥■■■■■◣                                   ■
			■                                     ◥             ◥■■■■■◤               ■
			■                                                                         ■
			■                                                                         ■
			■                                         ◥■■■■■                          ■
			■                                              ■                          ■
			■                                              ■▬▬▬▬■■■■■◤                ■
			■                 ◢■■■■■■◣                     ■    ■                     ■
			■                ◢■◤   ◥■■                     ■    ■                     ■
			■               ◢■■◣    ◥■                     ◥▬▬▬▬◤                     ■
			■              ◢■◤ ◥◣    ■                                                ■
			■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
		""" # ■▩▬◢◤◥◣◫
		ents: [
			{id: 0, x: 30, y: 17, type: "Door", to: "the second room"}
			# {id: 0, x: 20, y: 5, type: "Enemy"} hahaha
			{id: 3, x: 20, y: 5, type: "Enemy"}
			{id: 4, x: 10, y: 5, type: "Enemy"}
			{id: 5, x: 71, y: 17, type: "Door", to: "the fourth room"}
			{id: 6, x: 22, y: 17, type: "HiddenDoor", from: "the fourth room", to: "the second room"}
		]
	"the fourth room":
		tiles: """
			■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
			■           ■                                                             ■
			■           ■                                                             ■
			■           ■                                                             ■
			■           ■                                                             ■
			■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
		""" # ■▩▬◢◤◥◣◫
		ents: [
			# {id: 0, x: 3, y: 3, type: "Door", from: "the third room"}
			# {id: 1, x: 71, y: 3, type: "Door", to: "the third room"}
			{id: 0, x: 15, y: 3, type: "Door", to: "the third room"}
			{id: 1, x: 71, y: 3, type: "Door", to: "the third room", from: "the third room"} # FIXME: this door also goes to the thing
		]

exports.initWorld = (world)->
	for key, room_def of rooms
		room_def.id = key
		world.applyRoomUpdate(room_def)
	
	# world.current_room_id = "the third room"
	# # starting_room = world.rooms[world.current_room_id]
	# starting_room = rooms[world.current_room_id]
	# player = new Player {id: "p#{Math.random()}", x: 8, y: 3, type: "Player"}, starting_room, world
	# starting_room.ents.push player
	# global.clientPlayerID = player.id
