
Door = require "./Door"

module.exports =
class @Player extends (require "../Ent")
	constructor: ->
		super
		@entering = no
		# TODO: allow gamepad controller usage
		controller_type = if @world.onClientSide then "KeyboardController" else "RemoteController"
		Controller = require "../controllers/#{controller_type}"
		@controller = new Controller @, onClientSide: @world.onClientSide
	
	step: (t)->
		@controller.step()
		
		unless @entering
			@vx += 0.03 * @controller.moveX
			
			if @controller.jump and @grounded()
				@vy = -0.56
		
		door = ent for ent in @entsAt @x, @y, @w, @h when ent instanceof Door
		if door?.to?
			if @entering
				if Math.abs(door.x - @x) < 0.1
					@enterRoom door.to
				else
					@vx += 0.01 * Math.sign(door.x - @x)
			else if @controller.enterDoor
				@entering = yes
		else
			@entering = no # in case you get pushed away from the door
		
		super
	
	enterRoom: (id)->
		@entering = no
		
		leaving_room = @room
		entering_room = @world.rooms[id]
		
		if not entering_room?
			console.error "Room does not exist with id #{id} in", @world
			return
		
		@world.current_room_id = id
		
		leaving_room.ents.splice (leaving_room.ents.indexOf @), 1
		entering_room.ents.push @
		
		@room = entering_room
		
		# try to find a door that's explicitly "from" the room we're leaving
		door = ent for ent in entering_room.ents when ent instanceof Door and ent.from is leaving_room.id
		# if there isn't one (which is likely) find a door that would lead back
		door ?= ent for ent in entering_room.ents when ent instanceof Door and ent.to is leaving_room.id
		
		if door
			@x = door.x
			@y = door.y
			@world.centerViewForNewlyEnteredRoom()
