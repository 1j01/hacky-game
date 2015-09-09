
Door = require "./Door"
KeyboardController = require "../controllers/KeyboardController"

module.exports =
class @Player extends (require "../Ent")
	constructor: ->
		super
		@entering = no
		@controller = new KeyboardController
	
	toJSON: ->
		o = {}
		for k, v of @ when k isnt "controller"
			o[k] = v
		o
	
	step: (t)->
		@controller.step()
		
		unless @entering
			@vx += 0.03 * @controller.moveX
			
			if @controller.jump and @grounded()
				@vy = -0.56
		
		@prev_keys = {}
		for k, v of @keys
			@prev_keys[k] = v
		
		door = ent for ent in @entsAt @x, @y, @w, @h when ent instanceof Door
		if door?.to?
			if @entering
				if Math.abs(door.x - @x) < 0.1
					@enterRoom door.to
					@entering = no
				else
					@vx += 0.01 * Math.sign(door.x - @x)
			else if @controller.enterDoor
				@entering = yes
		else
			@entering = no # in case you get pushed away from the door
		
		super
	
	enterRoom: (id)->
		world = @getWorld()
		leaving_room = @getRoom()
		entering_room = world.rooms[id]
		# console.log "enter room #{id}"
		if not entering_room?
			console.error "Room does not exist with id #{id} in", world
		# console.log {leaving_room, entering_room}
		world.current_room_id = id
		leaving_room.ents.splice (leaving_room.ents.indexOf @), 1
		reincarnation = new Player @, entering_room, world
		entering_room.ents.push reincarnation
		# try to find a door that's explicitly "from" the room we're leaving
		door = ent for ent in entering_room.ents when ent instanceof Door and ent.from is leaving_room.id
		# if there isn't one (which is likely) find a door that would lead back
		door ?= ent for ent in entering_room.ents when ent instanceof Door and ent.to is leaving_room.id
		if door
			reincarnation.x = door.x
			reincarnation.y = door.y
			world.centerViewForNewlyEnteredRoom()
