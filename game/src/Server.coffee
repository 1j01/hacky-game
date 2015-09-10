
# Each client hosts a server
# The client starts out connected to it's server
# If a connection fails with a remote server, you get booted back to the local server

net = require "net"
JSONSocket = require "json-socket"
hack = require "./savegame"
discover = require "./discover"
World = require "./World"
Door = require "./ents/Door"
OtherworldlyDoor = require "./ents/OtherworldlyDoor"
Player = require "./ents/Player"

loaded = no

getFreePort = do ->
	port = 45035
	(cb)->
		port += 1
		server = net.createServer()
		server.listen port, ->
			server.once 'close', -> cb port
			server.close()
		server.on 'error', (err)->
			getFreePort cb

module.exports =
class Server
	constructor: ->
		@world = new World onClientSide: no
		
		clients = []
		
		send_all_data = =>
			for c in clients
				for id, room of @world.rooms
					c.sendMessage {room}
		
		send_ents = =>
			for c in clients
				for id, room of @world.rooms
					c.sendMessage {room: {id: room.id, ents: room.ents}}
		
		@server = net.createServer (socket)=>
			c = new JSONSocket socket
			# console.debug "a client connected", c
			clients.push c
			c.on "end", =>
				# console.debug "a client disconnected", c
				clients.splice (clients.indexOf c), 1
			c.on "message", (message)=>
				if message?.controls
					{controls} = message
					for player in @world.getPlayers()
						if player.id is controls.playerID
							player.controller.applyUpdate controls
				else if message?.enterDoor
					{from, to, player} = message?.enterDoor
					entering_room = @world.rooms[to.room_id]
					player = new Player player, entering_room, @world
					entering_room.ents.push player
					
					# if going between worlds
					if to.port isnt from.port
						# find an otherworldly door
						exit_door = ent for ent in entering_room.ents when ent.type is "OtherworldlyDoor" and ent.port is from.port
					else
						# try to find a door that's explicitly "from" the room we're leaving
						exit_door = ent for ent in entering_room.ents when ent instanceof Door and ent.from is from.room_id
						# if there isn't one (which is likely) find a door that would lead back
						exit_door ?= ent for ent in entering_room.ents when ent instanceof Door and ent.to is from.room_id
					
					if exit_door
						player.x = exit_door.x
						player.y = exit_door.y
				else
					console.warn "Unhandled message:", message
			send_all_data()
		
		getFreePort (@port)=>
			@server.listen @port
		
		@iid = setInterval =>
			if global.window?.CRASHED
				console.log "Server: stopping, since the client crashed"
				@close()
				return
			@world.step()
			send_ents()
		, 1000 / 60
		# TODO: maybe step the server from the client?
		
		@slower_iid = setInterval =>
			send_all_data()
			# TODO: save
			# TODO: only save if there has been activity
			# if loaded
			# 	hack.save @world, (err)=>
			# 		console.error err if err
		, 500
		
		@world.applyRoomUpdate
			id: "the second room"
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
			ents: [
				{id: 2, x: 2, y: 1, type: "Door", to: "the third room"}
				{id: 0, x: 1, y: 1, type: "Enemy"}
			]
		
		@world.applyRoomUpdate
			id: "the third room"
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
		
		@world.applyRoomUpdate
			id: "the fourth room"
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
		
		starting_room = @world.rooms[@world.current_room_id]
		player = new Player {id: "p#{Math.random()}", x: 8, y: 3, type: "Player"}, starting_room, @world
		starting_room.ents.push player
		global.clientPlayerID = player.id
		
		# Find other clients and create doors to other worlds
		interuniversal_doors = {}
		@discovery_iid = setInterval =>
			discover (err, ports)=>
				return console.error err if err
				# console.log "Other client ports:", ports
				
				for port, door of interuniversal_doors
					unless +port in ports
						# TODO: animate closing
						console.log "Close door", door
						door.remove()
						delete interuniversal_doors[port]
				
				for port in ports when not interuniversal_doors[port]
					interuniversal_doors[port] = door = new OtherworldlyDoor {
						port
						id: "tcp://localhost:#{port}"
						to: "the second room"
						x: 12
						y: 5
						type: "OtherworldlyDoor"
					}, starting_room, @world
					starting_room.ents.push door
		, 500
		
		
		# hack.load (err, world)=>
		# 	if err
		# 		console.error err # TODO: visible error
		# 	else if world
		# 		console.log "Game loaded", world
		# 		@world.applyUpdate world
		# 		loaded = yes
		# 	else
		# 		console.log "Start new game"
		# 		loaded = yes
	
	getPort: (callback)->
		iid = setInterval =>
			if @port
				clearInterval iid
				callback @port
		, 50
	
	close: ->
		@server.close()
		clearInterval @iid
		clearInterval @slower_iid
		clearInterval @discovery_iid
