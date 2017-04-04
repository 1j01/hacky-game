
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
			c.on "end", =>
				# console.debug "a client disconnected", c
				@clients.splice(@clients.indexOf(c), 1)
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
					if to.address isnt from.address
						# find an otherworldly door
						# TODO: support more than two 
						# FIXME: from.address will be a local/private address so this wouldn't work
						# exit_door = ent for ent in entering_room.ents when ent.type is "OtherworldlyDoor" and ent.address is from.address
						exit_door = ent for ent in entering_room.ents when ent.type is "OtherworldlyDoor"
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
		starting_room = @world.rooms[@world.current_room_id]
		player = new Player {id: "p#{Math.random()}", x: 8, y: 3, type: "Player"}, starting_room, @world
		starting_room.ents.push player
		global.clientPlayerID = player.id
		
		
		# Find other clients and create doors to other worlds
		interuniversal_doors = {}
		@discovery_iid = setInterval =>
			discover (err, addresses)=>
				return console.error err if err
				
				# console.log "Other client addresses:", addresses
				
				for address, door of interuniversal_doors
					unless address in addresses
						# TODO: animate closing
						console.log "Close door", door
						door.remove()
						delete interuniversal_doors[address]
				
				for address in addresses when not interuniversal_doors[address]
					interuniversal_doors[address] = door = new OtherworldlyDoor {
						address
						id: address
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
