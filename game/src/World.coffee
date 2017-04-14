
net = require "net"
JSONSocket = require "json-socket"
Room = require "./Room"
Player = require "./ents/Player"

module.exports =
class @World
	constructor: ({@onClientSide, @serverAddress, @players={}})->
		@["[[ID]]"] = (require "crypto").randomBytes(10).toString("hex")
		@rooms = {}
		
		# The client starts out connected to its own server
		if @onClientSide
			@socket = new JSONSocket new net.Socket
			[host, port] = @serverAddress.replace(/tcp:(\/\/)?/, "").split(":")
			@socket.connect {host, port}
			@socket.on "close", =>
				console.warn "Disconnected from server! (socket close)"
				client.worlds_by_address.delete(@serverAddress)
				@bootPlayerToLocalWorld()
			@socket.on "message", (message)=>
				if message?.room
					@applyRoomUpdate message.room
				else if message?.enteredRoom
					# client.current_world = @
					client.transitioning_to_room_id = message.enteredRoom.id
					client.transitioning_to_world = @
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
			client.current_world = entering_world
			client.current_room_id = entering_room_id
			entering_world.socket.sendMessage
				enterRoom:
					player: player
					from: booted: yes, address: leaving_world.serverAddress
					to: room_id: entering_room_id, address: entering_world.serverAddress

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
