
Room = require "./Room"

module.exports =
class @World
	constructor: ->
		@rooms = {}
		@current_room_id = "the second room"
		@view = {cx: 0, cy: 0}
	
	toJSON: ->
		{@rooms, @current_room_id}
	
	applyUpdate: ({rooms, @current_room_id})->
		for room in rooms
			@applyRoomUpdate room
	
	applyRoomUpdate: (room)->
		if not room.id?
			throw new Error "Trying to applyRoomUpdate with a room lacking an id (keys: #{Object.keys(room).join ", "})"
		@rooms[room.id] ?= new Room room.id, @
		@rooms[room.id].applyUpdate room
	
	applyControl: (control)->
		# on the server, control a player
		# TODO!
	
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
