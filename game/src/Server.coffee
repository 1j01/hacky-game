
# Each client hosts a server
# The client starts out connected to its local server
# If a connection fails with a remote server, you'll get booted back to the local server

net = require "net"
JSONSocket = require "json-socket"
hack = require "./savegame"
discover = require "./discovery/discover"
World = require "./World"
{initWorld} = require "./world-data"
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
	constructor: (callback)->
		@world = new World onClientSide: no
		
		@clients = []
		
		send_all_data_to_new_client = (c)=>
			for id, room of @world.rooms
				c.sendMessage {room}
		
		send_world_updates = =>
			# NOTE: currently nothing makes a room "active"
			for id, room of @world.rooms when room.active
				for c in @clients
					c.sendMessage {room}
		
		send_ents = =>
			for c in @clients
				for id, room of @world.rooms
					c.sendMessage {room: {id: room.id, ents: room.ents}}
		
		@server = net.createServer (socket)=>
			c = new JSONSocket socket
			# console.debug "a client connected", c
			@clients.push(c)
			c.on "close", =>
				# console.debug "a client disconnected", c
				@clients.splice(@clients.indexOf(c), 1)
				console.debug "player disconnected, removing", c.player
				c.player?.remove()
			c.on "error", (err)=>
				console.error "Serverside socket error: ", err, "for client", c
			c.on "message", (message)=>
				if message?.controls
					{controls} = message
					for player in @world.getPlayers()
						if player.id is controls.playerID
							player.controller.applyUpdate controls
				else if message?.enterRoom
					{from, to, player} = message?.enterRoom
					entering_room = @world.rooms[to.room_id]
					player = new Player player, entering_room, @world
					c.player = player
					entering_room.ents.push player
					
					# if going between worlds
					if to.address isnt from.address
						# find an otherworldly door
						exit_door = ent for ent in entering_room.ents when ent.type is "OtherworldlyDoor" and ent.address is from.address
						# TODO: handle no exit door; is this a situation that can come up with some network configurations?
						# I guess if you connect to a remote server, and on that server there's a door to another server,
						# if you go to that server and then get gooted, there won't necessarily be a door in your home world
						# that corresponds to that server
						# exit_door = ent for ent in entering_room.ents when ent.type is "OtherworldlyDoor"
						if exit_door and from.booted
							player.vx = -0.4
							player.vy = -0.3
							exit_door.locked = yes
					else
						# TODO: we should probably just have door IDs and link to specific doors
						# try to find a door that's explicitly "from" the room we're leaving
						exit_door = ent for ent in entering_room.ents when ent instanceof Door and ent.from is from.room_id
						# if there isn't one (which is likely) find a door that would lead back
						exit_door ?= ent for ent in entering_room.ents when ent instanceof Door and ent.to is from.room_id
					
					if exit_door
						player.x = exit_door.x
						player.y = exit_door.y
				else
					console.warn "Unhandled message:", message
			send_all_data_to_new_client(c)
		
		@_getPort_callbacks = []
		getFreePort (@port)=>
			@server.listen @port, (err)=>
				return callback(err) if err
				for getPort_cb in @_getPort_callbacks
					getPort_cb(@port)
				@_getPort_callbacks = [] # unref
				callback()
		
		@iid = setInterval =>
			if global.window?.CRASHED
				console.log "Server: stopping, since the client crashed"
				@close ->
					console.log "Server: stopped"
				return
			@world.step()
			send_ents()
		, 1000 / 60
		# TODO: maybe step the server from the client?
		# @iid = setInterval =>
		# 	send_ents()
		# , 1000 / 1
		
		@slower_iid = setInterval =>
			send_world_updates()
			# TODO: save (only if there has been activity)
			# if loaded
			# 	hack.save @world, (err)=>
			# 		console.error err if err
		, 500
		
		initWorld(@world)
		
		# TODO: set current_room_id when adding the player
		hub_room = @world.rooms[@world.current_room_id]
		player = new Player {id: "p#{Math.random()}", x: 8, y: 3, type: "Player"}, hub_room, @world
		hub_room.ents.push player
		global.clientPlayerID = player.id
		
		
		# Find other clients and create doors to other worlds
		otherworldly_doors = new Map
		door_placement_x = 12
		# discover (err, addresses)=>
		# 	return console.error err if err
		# 	# console.log "Other client addresses:", addresses
		# 	for address, door of otherworldly_doors
		# 		unless address in addresses
		# 			# TODO: animate closing
		# 			console.log "Close door", door
		# 			door.remove()
		# 			delete otherworldly_doors[address]
		discover (peer)=>
			peer.on "found", (address)->
				# console.log "Found peer!", address
				if otherworldly_doors.has(address)
					door = otherworldly_doors.get(address)
					if door.locked
						console.log "Unlock", door, "(might be viable again)"
						door.locked = no
				else
					door = new OtherworldlyDoor {
						address
						id: address
						to: "the second room"
						x: door_placement_x
						y: 5
						type: "OtherworldlyDoor" # XXX: is this really necessary?
					}, hub_room, @world
					door_placement_x -= 3
					otherworldly_doors.set(address, door)
					hub_room.ents.push(door)
			# TODO: unfind peers
		
		
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
		if @port
			callback(@port)
		else
			@_getPort_callbacks.push(callback)
	
	close: (callback)->
		for c in @clients
			c._socket.destroy()
		@server.close(callback)
		clearInterval(@iid)
		clearInterval(@slower_iid)
		clearInterval(@discovery_iid)
