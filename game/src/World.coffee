
Room = require "./Room"

class @World
	constructor: ->
		@rooms = {}
		@current_room = "the second room"
	
	toJSON: ->
		{@rooms, @current_room}
	
	applyUpdate: ({rooms, @current_room})->
		for room in rooms
			@applyRoomUpdate room
	
	applyRoomUpdate: (room)->
		if not room.id?
			throw new Error "Trying to applyRoomUpdate with a room lacking an id (keys: #{Object.keys(room).join ", "})"
		@rooms[room.id] ?= new Room room.id, @
		@rooms[room.id].applyUpdate room
	
	step: (t)->
		# TODO: avoid stepping in rooms that are inactive
		for id, room of @rooms
			room.step t
	
	draw: (ctx)->
		# TODO: only draw current room
		# TODO: handle room transitions
		for id, room of @rooms when id is @current_room
			ctx.save()
			ctx.translate(
				(ctx.canvas.width - room.width*16)/2
				(ctx.canvas.height - room.height*16)/2
			)
			room.draw ctx
			ctx.restore()

module?.exports = @World
