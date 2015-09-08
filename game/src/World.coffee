
Room = require "./Room"

module.exports =
class @World
	constructor: ->
		@rooms = {}
		# TODO: rename to current_room_id
		@current_room = "the second room"
		# TODO: make into worldly coords?
		@view = {cx: 0, cy: 0}
	
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
		for id, room of @rooms # when room.hasPlayers()
			room.step t
	
	getWhereToCenterView: (room, ctx, margin=0)->
		cx_to = @view.cx
		cy_to = @view.cy
		if (
			ctx.canvas.width >= room.width*16 and
			# TODO: split W and H
			ctx.canvas.height >= room.height*16
		)
			cx_to = (room.width*16/2)
			# TODO: split X and Y
			cy_to = (room.height*16/2)
		else
			player = ent for ent in room.ents when ent.type is "Player"
			if player
				px = (player.x + player.w/2) * 16
				py = (player.y + player.h/2) * 16
				cx_to = px - margin if px > @view.cx + margin
				cx_to = px + margin if px < @view.cx - margin
				cy_to = py - margin if py > @view.cy + margin
				cy_to = py + margin if py < @view.cy - margin
		{cx_to, cy_to}
	
	centerViewForNewlyEnteredRoom: ->
		return unless @_ctx_
		room = @rooms[@current_room]
		{cx_to, cy_to} = @getWhereToCenterView room, @_ctx_
		@view.cx = cx_to
		@view.cy = cy_to
	
	draw: (ctx)->
		@_ctx_ = ctx
		# TODO: only draw current room
		# TODO: handle room transitions
		
		for id, room of @rooms when id is @current_room
			{cx_to, cy_to} = @getWhereToCenterView room, ctx, 40
			@view.cx += (cx_to - @view.cx) / 5
			@view.cy += (cy_to - @view.cy) / 5
			
			ctx.save()
			ctx.translate(
				ctx.canvas.width/2 - @view.cx
				ctx.canvas.height/2 - @view.cy
			)
			room.draw ctx
			ctx.restore()
