
Door = require "./Door"
World = require "../World"

module.exports =
class @Player extends (require "../Ent")
	constructor: (props, room, world)->
		# existing_player = world.getPlayer props.id
		# if existing_player
		# 	# console.log "use existing Player!", props.id, existing_player.room.ents
		# 	existing_player.remove()
		# 	existing_player.room = room
		# 	existing_player.world = world
		# 	existing_player.controller.world = world
		# 	world.players[existing_player.id] = existing_player
		# 	return existing_player
		
		super
		# console.log "new Player!", @id, @world.players[@id]
		@world.players[@id] = @
		
		@entering = no
		
		# TODO: gamepad controller support
		if @world.onClientSide
			if @id is global.clientPlayerID
				KeyboardController = require "../controllers/KeyboardController"
				@controller = new KeyboardController @, @world
			else
				Controller = require "../Controller"
				@controller = new Controller @, @world
		else
			RemoteController = require "../controllers/RemoteController"
			@controller = new RemoteController @, @world
	
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
					@enterDoor door
				else
					@vx += 0.01 * Math.sign(door.x - @x)
			else if @controller.enterDoor
				@entering = yes
		else
			@entering = no # in case you get pushed away from the door
		
		super
	
	enterDoor: (door)->
		@entering = no
		
		on_client_side = @world.onClientSide
		what_side = "(#{if on_client_side then "client" else "server"}-side)"
		log = (args...)->
			if on_client_side
				console.debug "%c#{what_side}", "color:#05F", args...
			else
				console.log "%c#{what_side}", "color:gray", args...
		log "Enter door", door
		
		leaving_room = @room
		leaving_world = @world
		@remove()
		
		entering_room_id = door.to
		entering_world =
			if door.port
				log "Leaving world", leaving_world
				if on_client_side and @id is global.clientPlayerID
					World = World.World ? World # XXX: Why is require() returning an Object?
					window.worlds_by_port[door.port] ?= new World onClientSide: yes, serverPort: door.port, players: @world.players
					window.world = window.worlds_by_port[door.port]
					log "Entering world", window.world
					window.world
			else
				@world
		
		if on_client_side and @id is global.clientPlayerID
			entering_world.current_room_id = entering_room_id
			entering_world.socket.sendMessage
				enterDoor:
					player: @
					from: room_id: leaving_room.id, port: leaving_world.serverPort
					to: room_id: entering_room_id, port: entering_world.serverPort
		
		# if not entering_world?
		# 	if @world.onClientSide
		# 		console.error "World does not exist with port #{door.port}", what_side
		# 	return
		# entering_room = entering_world.rooms[entering_room_id]
		# if not entering_room?
		# 	console.error "Room does not exist with id '#{entering_room_id}' in", entering_world, what_side
		# 	return
		
		# entering_room.ents.push @
		# 
		# @room = entering_room
		# @world = entering_world
		# @controller.world = entering_world
		# 
		# # try to find a door that's explicitly "from" the room we're leaving
		# exit_door = ent for ent in entering_room.ents when ent instanceof Door and ent.from is leaving_room.id
		# # if there isn't one (which is likely) find a door that would lead back
		# exit_door ?= ent for ent in entering_room.ents when ent instanceof Door and ent.to is leaving_room.id
		# 
		# log "Exit door", exit_door
		# 
		# if exit_door
		# 	@x = exit_door.x
		# 	@y = exit_door.y
		# 	@world.centerViewForNewlyEnteredRoom()
