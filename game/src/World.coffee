
net = require "net"
JSONSocket = require "json-socket"
Room = require "./Room"
Player = require "./ents/Player"

module.exports =
class @World
	constructor: ({@onClientSide, @serverAddress, @players={}})->
		@["[[ID]]"] = (require "crypto").randomBytes(10).toString("hex")
		@rooms = {} # TODO: use Map
		
		# The client starts out connected to its own server
		# On the client side, the World connects to a server
		# On the server side, the Server has a World
		
		if @onClientSide
			@socket = new JSONSocket new net.Socket
			[host, port] = @serverAddress.replace(/tcp:(\/\/)?/, "").split(":")
			@socket.connect {host, port}
			@socket.on "close", =>
				console.warn "Disconnected from server! (socket close)"
				client.worlds_by_address.delete(@serverAddress)
				@bootPlayerToLocalWorld()
			@socket.on "message", (message)=>
				# TODO: standard {type, data} messaging would probably be cleaner
				# actually just use socket.io
				if message?.room
					@applyRoomUpdate message.room
				else if message?.enteredRoom
					entered_room_id = message.enteredRoom.room_id
					exit_door_id = message.enteredRoom.exit_door_id
					console.log "Entered room:", entered_room_id
					client.enteredRoom({entered_room_id, exit_door_id, entered_world: @})
				else
					console.warn "Unhandled message:", message
			@socket.on "error", (err)=>
				# ECONNRESET, ECONNREFUSED, ETIMEDOUT, EPIPE...
				console.error "Socket error: #{err}"

	bootPlayerToLocalWorld: ->
		player = @getPlayer()
		global.server.getAddress (address)=>
			if address is @serverAddress
				console.error "Would boot player to the local server #{address} but they're already there"
				return
			console.warn "Booting player to #{address}"
			entering_world = client.worlds_by_address.get(address)
			unless entering_world
				console.error "No world #{address} in", client.worlds_by_address
				return
			entering_room_id = "the second room" # XXX: hardcoded (and silly) value
			leaving_world = @
			entering_room = entering_world.rooms[entering_room_id]
			if entering_room?
				exit_door = ent for ent in entering_room.ents when ent.type is "OtherworldlyDoor" and ent.address is @serverAddress
			client.enterRoom
				leaving_room: player.room
				leaving_world: player.world
				leaving_door: null
				entering_world: entering_world
				entering_room_id: entering_room_id
				entering_room: entering_room
				entering_door: exit_door
				# booted: yes
				transition: "booted"
				# TODO: rename entering_door/leaving_door for clarity,
				# probably entering_room_door/leaving_room_door

	toJSON: ->
		{@rooms}
	
	# TODO: rename "applyUpdate" methods to "fromJSON"?
	# to match toJSON methods and to better connote the implicit creation
	applyUpdate: ({rooms})->
		for room in rooms
			@applyRoomUpdate room
	
	applyRoomUpdate: (room)->
		if not room.id?
			throw new Error "Trying to applyRoomUpdate with a room lacking an id (keys: #{Object.keys(room).join ", "})"
		@rooms[room.id] ?= new Room room.id, @
		@rooms[room.id].applyUpdate room
	
	getPlayer: (id = global.clientPlayerID)->
		@players[id]
	
	step: (t)->
		for id, room of @rooms when room.hasPlayers()
			room.step t
