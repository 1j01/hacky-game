
net = require "net"
Room = require "./Room"
Player = require "./ents/Player"

# Keep track of sockets and close any existing ones (for reloading in development)
global.sockets ?= []
for socket in global.sockets
	socket.removeAllListeners "end"
	socket.end()

module.exports =
class @World
	constructor: ({@onClientSide, @serverPort})->
		@ID_for_inspection = (require "crypto").randomBytes(10).toString("hex")
		@rooms = {}
		@current_room_id = "the second room"
		@view = {cx: 0, cy: 0}
		
		# The client starts out connected to it's own server
		if @onClientSide
			@socket = net.connect port: @serverPort
			global.sockets.push @socket
			@socket.on "end", =>
				console.warn "Disconnected from server!"
			@socket.setEncoding "utf8"
			# TODO/FIXME: handle json that spans multiple data events
			@socket.on "data", (data)=>
				for json in data.trim().split "\n"
					try
						message = JSON.parse json
					catch e
						console.error "failed to parse json message", json
					if message?.room
						@applyRoomUpdate message.room
					else
						console.warn "unknown message"

	toJSON: ->
		{@rooms, @current_room_id}
	
	# TODO: change "applyUpdate"s to "fromJSON"s?
	applyUpdate: ({rooms, @current_room_id})->
		for room in rooms
			@applyRoomUpdate room
	
	applyRoomUpdate: (room)->
		if not room.id?
			throw new Error "Trying to applyRoomUpdate with a room lacking an id (keys: #{Object.keys(room).join ", "})"
		@rooms[room.id] ?= new Room room.id, @
		@rooms[room.id].applyUpdate room
	
	# TODO: should this be moved into the server?
	applyControls: (controls)->
		for player in @getPlayers()
			if player.id is controls.playerID
				player.controller.applyUpdate controls
	
	# TODO: should this be moved into the server?
	enterPlayer: ({from, player})->
		# TODO: dynamic room placement
		# FIXME: don't instantiate a new Player when reentering a player's original world
		entering_room = @rooms["the second room"]
		player = new Player player, entering_room, @
		door = ent for ent in entering_room.ents when ent.type is "OtherworldlyDoor" and ent.port is from.port
		player.x = door.x
		player.y = door.y
		entering_room.ents.push player
	
	getPlayers: ->
		players = []
		for id, room of @rooms
			players = players.concat room.getPlayers()
		players
	
	step: (t)->
		for id, room of @rooms when room.hasPlayers()
			room.step t
	
	getWhereToCenterView: (room, ctx, margin=0)->
		player = room.getPlayer()
		
		cx_to = @view.cx
		cy_to = @view.cy
		
		if ctx.canvas.width >= room.width * 16
			cx_to = room.width / 2
		else if player
			px = (player.x + player.w / 2)
			cx_to = px - margin if px > @view.cx + margin
			cx_to = px + margin if px < @view.cx - margin
		
		if ctx.canvas.height >= room.height * 16
			cy_to = room.height / 2
		else if player
			py = (player.y + player.h / 2)
			cy_to = py - margin if py > @view.cy + margin
			cy_to = py + margin if py < @view.cy - margin
		
		{cx_to, cy_to}
	
	centerViewForNewlyEnteredRoom: ->
		# TODO: center view at game start (once room is loaded)
		return unless @_ctx_
		room = @rooms[@current_room_id]
		{cx_to, cy_to} = @getWhereToCenterView room, @_ctx_
		@view.cx = cx_to
		@view.cy = cy_to
	
	draw: (ctx)->
		@_ctx_ = ctx
		# TODO: room transitions
		
		for id, room of @rooms when id is @current_room_id
			{cx_to, cy_to} = @getWhereToCenterView room, ctx, 2.5
			@view.cx += (cx_to - @view.cx) / 5
			@view.cy += (cy_to - @view.cy) / 5
			
			ctx.save()
			ctx.translate(
				ctx.canvas.width / 2 - @view.cx * 16
				ctx.canvas.height / 2 - @view.cy * 16
			)
			room.draw ctx
			ctx.restore()
