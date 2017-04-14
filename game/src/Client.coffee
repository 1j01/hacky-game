
World = require "./World"

module.exports =
class Client
	constructor: ->
		@canvas = document.createElement "canvas"
		@ctx = @canvas.getContext "2d"
		@canvas2x = document.createElement "canvas"
		@ctx2x = @canvas2x.getContext "2d"
		document.body.appendChild @canvas2x
		
		# NOTE: ideally we could just have a current_room and infer the world from that
		@current_world = null
		@current_room_id = "the second room"
		
		# NOTE: if I'm going to use these for logic, maybe I should name them entering_* and leaving_*
		@transitioning_from_room = null
		@transitioning_to_room = null
		@transitioning_to_room_id = null
		@transitioning_from_door = null
		@transitioning_to_door = null
		@transitioning_from_world = null
		@transitioning_to_world = null
		
		@transition = null
		@transition_time = 0
		
		@worlds_by_address = new Map
		@views_by_room = new Map

	start: (address)=>
		world = new World onClientSide: yes, serverAddress: address
		@worlds_by_address.set(address, world)
		@current_world = world
		@animate()

	closeConnections: =>
		@worlds_by_address.forEach (world)->
			world.socket?._socket.destroy()

	getView: (room)=>
		if @views_by_room.has(room)
			view = @views_by_room.get(room)
		else
			view = {cx: 0, cy: 0}
			@views_by_room.set(room, view)
		view

	getWhereToCenterView: (room, view, ctx, margin=0)->
		player = room.getPlayer()
		
		cx_to = view.cx
		cy_to = view.cy
		
		if ctx.canvas.width >= room.width * 16
			cx_to = room.width / 2
		else if player
			px = (player.x + player.w / 2)
			cx_to = px - margin if px > view.cx + margin
			cx_to = px + margin if px < view.cx - margin
		
		if ctx.canvas.height >= room.height * 16
			cy_to = room.height / 2
		else if player
			py = (player.y + player.h / 2)
			cy_to = py - margin if py > view.cy + margin
			cy_to = py + margin if py < view.cy - margin
		
		{cx_to, cy_to}

	# TODO: center view at game start (once room is loaded)
	centerViewForNewlyEnteredRoom: ->
		room = @current_world.rooms[@current_room_id]
		return unless room
		view = @getView(room)
		{cx_to, cy_to} = @getWhereToCenterView room, view, @ctx
		view.cx = cx_to
		view.cy = cy_to

	animate: =>
		if window.CRASHED
			# TODO: not in production?
			console.log "Client: stopped because of an error"
			return
		requestAnimationFrame @animate
		# TODO: prevent player movement during transitions
		@current_world.step()
		@canvas2x.width = innerWidth if @canvas2x.width isnt innerWidth
		@canvas2x.height = innerHeight if @canvas2x.height isnt innerHeight
		@canvas.width = Math.ceil(innerWidth / 2) if @canvas.width isnt Math.ceil(innerWidth / 2)
		@canvas.height = Math.ceil(innerHeight / 2) if @canvas.height isnt Math.ceil(innerHeight / 2)
		@ctx.fillStyle = "black"
		@ctx.fillRect 0, 0, @canvas.width, @canvas.height
		
		room = @current_world.rooms[@current_room_id]
		return unless room
		view = @getView(room)
		{cx_to, cy_to} = @getWhereToCenterView room, view, @ctx, 2.5
		view.cx += (cx_to - view.cx) / 5
		view.cy += (cy_to - view.cy) / 5
		
		@ctx.save()
		@ctx.translate(
			~~(@canvas.width / 2 - view.cx * 16)
			~~(@canvas.height / 2 - view.cy * 16)
		)
		room.draw @ctx, view
		@ctx.restore()
		
		enable_transitions = localStorage.enable_transitions is "true"
		
		if @transition
			id = @ctx.getImageData(0, 0, @canvas.width, @canvas.height)
			{data, width, height} = id
			
			switch @transition
				when "door"
					transition_duration = 20
					fn = (x, y, t, width, height, door_x, door_y)->
						1 - (Math.hypot(x-door_x, y-door_y)) / width < t
				when "door-exit"
					transition_duration = 20
					fn = (x, y, t, width, height, door_x, door_y, exit_door_x, exit_door_y)->
						(Math.hypot(x-exit_door_x, y-exit_door_y)) / width > t
				when "portal"
					transition_duration = 20
					fn = (x, y, t, width, height, door_x, door_y)->
						1 - (Math.hypot(x-door_x, y-door_y)) / width < t
				when "portal-exit"
					transition_duration = 20
					fn = (x, y, t, width, height, door_x, door_y, exit_door_x, exit_door_y)->
						(Math.hypot(x-exit_door_x, y-exit_door_y)) / width > t
				when "booted"
					transition_duration = 100
					fn = (x, y, t, width, height, door_x, door_y)->
						# 1 - (Math.hypot(x-door_x, y-door_y)) / width + (0.1 * Math.atan2(y-door_y, x-door_x) % 0.1) < t
						# dist = Math.hypot(x-door_x, y-door_y) / width
						# 1 - dist + ((0.1 * Math.atan2(y-door_y, x-door_x) - dist) % 0.1) < t
						# 1 - dist + 0.5 * ((Math.atan2(y-door_y, x-door_x) - dist) % 0.5) < t
						# 1 - dist - 0.5 * ((Math.atan2(y-door_y, x-door_x) + dist * 5 + Math.sin(dist * 70)) %% (Math.PI / 5)) < t
						1 - dist - 0.5 * ((Math.atan2(y-door_y, x-door_x) + dist * 5 + Math.sin(dist * 20)) %% (Math.PI / 5)) < t
				when "booted-exit"
					transition_duration = 100
					fn = (x, y, t, width, height, door_x, door_y, exit_door_x, exit_door_y)->
						1 - dist - 0.5 * ((Math.atan2(y-door_y, x-door_x) + dist * 5 + Math.sin(dist * 70)) %% (Math.PI / 5)) < t
				else
					throw new Error "Unknown transition type '#{@transition}'"
			
			unless enable_transitions
				transition_duration = 0
			
			@transition_time += 1 / (1 + transition_duration)
			t = @transition_time
			
			door = @transitioning_from_door
			from_view = @views_by_room.get(@transitioning_from_room)
			if door? and from_view?
				door_x = @canvas.width / 2 + (door.x + door.w/2 - from_view.cx) * 16
				door_y = @canvas.height / 2 + (door.y + door.h/2 - from_view.cy) * 16
			else
				door_x = width/2
				door_y = height/2
			
			exit_door = @transitioning_to_door
			to_view = @views_by_room.get(@transitioning_to_room)
			if exit_door? and to_view?
				exit_door_x = @canvas.width / 2 + (exit_door.x + exit_door.w/2 - to_view.cx) * 16
				exit_door_y = @canvas.height / 2 + (exit_door.y + exit_door.h/2 - to_view.cy) * 16
			else
				exit_door_x = width/2
				exit_door_y = height/2
			
			for i in [0..data.length] by 4
				x = (i/4) % width
				y = (i/4) // width
				if fn(x, y, t, width, height, door_x, door_y, exit_door_x, exit_door_y)
					# data[i+0] = 0
					# data[i+1] = 0
					# # data[i+2] = 0
					data[i+3] = 0
			
			if enable_transitions
				@ctx.putImageData(id, 0, 0)
			
			if @transition_time >= 1
				@transition_time = 0
				if @transition?.match("exit")
					@transition = null
					@transitioning_from_room = null
					@transitioning_to_room = null
					@transitioning_from_door = null
					@transitioning_to_door = null
					@transitioning_from_world = null
					@transitioning_to_world = null
					@transitioning_to_room_id = null
				else
					@transition = "#{@transition}-exit"
				if @transitioning_to_world
					@current_world = @transitioning_to_world
					if @transitioning_to_room_id
						@current_room_id = @transitioning_to_room_id
					@centerViewForNewlyEnteredRoom()
					
					@transitioning_to_world.socket.sendMessage
						enterRoom:
							player: @transitioning_from_world.getPlayer()
							from: room_id: @transitioning_from_room.id, address: @transitioning_from_world.serverAddress
							to: room_id: @transitioning_to_room_id, address: @transitioning_to_world.serverAddress
					
					# TODO: pause on black, wait for enteredRoom message,
					# and transition back if failed to enter room
					# (if we get enteredRoom after we gave up, it should just switch instantly)
					# TODO: eventually disconnect from and destroy old world (if you go to a different world)
					# (cancel if you come back within some period)
		
		@ctx2x.fillStyle = "black"
		@ctx2x.fillRect 0, 0, @canvas2x.width, @canvas2x.height
		@ctx2x.imageSmoothingEnabled = off
		@ctx2x.drawImage @canvas, 0, 0, @canvas2x.width, @canvas2x.height
