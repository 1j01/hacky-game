
Door = require "./Door"
World = require "../World"

Controller = require "../controllers/Controller"
KeyboardController = require "../controllers/KeyboardController"
ServersideController = require "../controllers/ServersideController"

keyboard_controller = new KeyboardController

module.exports =
class @Player extends (require "./Ent")
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
		
		# NOTE: ideally @controller would be an injected dependency,
		# but I'm not sure how that would work when ents can be created generically
		# TODO: gamepad controller support
		@unsynced
			controller:
				if @world.onClientSide
					if @id is global.clientPlayerID
						keyboard_controller
					else
						new Controller
				else
					new ServersideController
		
		# FIXME: (race condition) player can get stuck without controls if a Player is created in non-active world
		# could make controller send controls to an array of world sockets, but that wouldn't be ideal
		# should call setPlayer on controller of visible player when updating
		@controller.setPlayer(@)
	
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
			# it would be weird if you automatically entered indefinitely later
		
		super
	
	enterDoor: (door)->
		@entering = no
		return if door.locked
		
		on_client_side = @world.onClientSide
		server_or_client_side_indication = "(#{if on_client_side then "client" else "server"}-side)"
		log = (args...)->
			if on_client_side
				console.debug "%c#{server_or_client_side_indication}", "color:#05F", args...
			else
				console.log "%c#{server_or_client_side_indication}", "color:gray", args...
		log "Enter door", door
		
		leaving_room = @room
		leaving_world = @world
		@remove()
		
		entering_room_id = door.to
		entering_world =
			if door.address
				log "Leaving world", leaving_world
				if on_client_side and @id is global.clientPlayerID
					{World} = World if World.World # XXX: Why is require() returning an Object?
					world = client.worlds_by_address.get(door.address)
					world ?= new World onClientSide: yes, serverAddress: door.address, players: @world.players
					client.worlds_by_address.set(door.address, world)
					# client.visible_world = world
					log "Entering world", world
					world
			else
				@world
		
		if on_client_side and @id is global.clientPlayerID
			# NOTE: we don't a Room to set client.transitioning_to_room to at this point
			client.transitioning_from_room = @room
			client.transitioning_from_world = @world
			client.transitioning_from_door = door
			client.transitioning_to_world = world
			client.transition = "portal"
			# TODO: wait for a signal from the new world's socket before switching visible worlds
			entering_world.current_room_id = entering_room_id
			entering_world.socket.sendMessage
				enterRoom:
					player: @
					from: room_id: leaving_room.id, address: leaving_world.serverAddress
					to: room_id: entering_room_id, address: entering_world.serverAddress
