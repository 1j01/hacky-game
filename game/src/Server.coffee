
# Each client hosts a server
# The client starts out connected to its local server
# If a connection fails with a remote server, you'll get booted back to the local server

net = require "net"
ip_address = require("ip").address()
JSONSocket = require "json-socket"
ssdp = require "./discovery/super-ssdp"
{App} = nw
hack = require "./savegame"
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
				@clients.splice(@clients.indexOf(c), 1)
				console.debug "player disconnected, removing", c.player
				c.player?.remove()
			c.on "error", (err)=>
				console.error "Serverside socket error: ", err, "for client", c
			c.on "message", (message)=>
				if message?.controls
					{controls} = message
					player = @world.getPlayer(controls.playerID)
					player?.controller.applyUpdate controls
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
					
					# XXX(?): can we guarantee sending this after we've sent the room to the client?
					# with their Player in it?
					# I'm guessing not, and maybe that's related to..
					# FIXME: client can get stuck without a Player in existence
					# setTimeout => # for simulating latency
					c.sendMessage
						enteredRoom: room_id: entering_room.id, exit_door_id: exit_door.id
					# , 500
				else
					console.warn "Unhandled message:", message
			
			send_all_data_to_new_client(c)
		
		@_getPort_callbacks = []
		getFreePort (port)=>
			@server.listen port, (err)=>
				return callback(err) if err
				# NOTE: not setting @port until now where we callback
				# because otherwise there'll be a race condition
				# since @getPort would callback immediately
				@port = port
				for getPort_cb in @_getPort_callbacks
					getPort_cb(@port)
				@_getPort_callbacks = [] # unref
				callback()
		
		@iid = setInterval =>
			if window.CRASHED
				# TODO: not in production?
				console.log "Server: stopping because of an error"
				@close ->
					console.log "Server: stopped"
				return
			@world.step()
			send_ents()
		, 1000 / 60
		
		@slower_iid = setInterval =>
			send_world_updates()
			# TODO: save (only if there has been activity)
			# if loaded
			# 	hack.save @world, (err)=>
			# 		console.error err if err
		, 500
		
		initWorld(@world)
		
		hub_room = @world.rooms["the second room"] # XXX: hardcoded (and silly) value
		# TODO: uuid
		# TODO: define spawn point in room data
		player = new Player {id: "p#{Math.random()}", x: 8, y: 3, type: "Player"}, hub_room, @world
		hub_room.ents.push player
		global.clientPlayerID = player.id
		# TODO: maybe the client should request to enter the room initially
		
		# Find other clients and create doors to other worlds
		otherworldly_doors = new Map
		door_placement_x = 12
		
		@getAddress (address)=>
			peer = global.peer = ssdp.createPeer
				name: App.manifest.name
				version: App.manifest.version
				url: address
				serviceType: "urn:1j01-github-io:service:game-server:1"
			peer.start()
			peer.on "found", (address)=>
				if otherworldly_doors.has(address)
					door = otherworldly_doors.get(address)
					if door.locked
						console.log "Unlock", door, "(#{address} might be viable again)"
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
					console.log "Found peer, opening", door
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
	
	getAddress: (callback)->
		@getPort (port)->
			address = "tcp://#{ip_address}:#{port}"
			callback address
	
	close: (callback)->
		for c in @clients
			c._socket.destroy()
		@server.close(callback)
		clearInterval(@iid)
		clearInterval(@slower_iid)
		clearInterval(@discovery_iid)
