
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
		
		@leaving_room = null
		@entering_room = null
		@entering_room_id = null
		@leaving_door = null
		@entering_door = null
		@leaving_world = null
		@entering_world = null
		
		@transition = null
		@transition_time = 0
		@transition_paused = no
		
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

	getWhereToCenterView: (room, view, ctx, margin=0)=>
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
	centerViewForNewlyEnteredRoom: =>
		room = @current_world.rooms[@current_room_id]
		console.log "centerViewForNewlyEnteredRoom", {room, @current_room_id}
		return unless room
		view = @getView(room)
		{cx_to, cy_to} = @getWhereToCenterView room, view, @ctx
		view.cx = cx_to
		view.cy = cy_to

	enteredRoom: ({entered_room_id, exit_door_id, entered_world})=>
		if @transition? and not @transition.match("exit")
			@transition_time = 0
			@transition = "#{@transition}-exit"
			@transition_paused = no
			@current_world = @entering_world
			if @entering_room_id
				@current_room_id = @entering_room_id
			@centerViewForNewlyEnteredRoom()
			@entering_world = entered_world
			@entering_room_id = entered_room_id
			@entering_room = @current_world.rooms[entered_room_id]
			@entering_door = @entering_room?.getEntByID(exit_door_id)
		else
			@current_world = entered_world
			@current_room_id = entered_room_id

	enterRoom: ({leaving_room, leaving_world, leaving_door, entering_world, entering_room_id, transition})=>
		# NOTE: could simplify and get world from leaving_room
		# or actually just get both ourselves?
		# @current_world and @current_world.rooms[@current_room_id]
		@leaving_room = leaving_room
		@leaving_world = leaving_world
		@leaving_door = leaving_door
		@entering_world = entering_world
		@entering_room_id = entering_room_id
		# NOTE: we cant't necessarily get the Room or Door we're transitioning to yet
		@entering_room = null
		@entering_door = null
		@transition = transition
		@transition_time = 0

	animate: =>
		if window.CRASHED
			# TODO: not in production?
			console.log "Client: stopped because of an error"
			return
		requestAnimationFrame @animate
		# TODO: prevent player movement during transitions
		# currently you're removed immediately but can move during the exit transition
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
			
			unless @transition_paused
				@transition_time += 1 / (1 + transition_duration)
			t = @transition_time
			
			door = @leaving_door
			from_view = @views_by_room.get(@leaving_room)
			if door? and from_view?
				door_x = @canvas.width / 2 + (door.x + door.w/2 - from_view.cx) * 16
				door_y = @canvas.height / 2 + (door.y + door.h/2 - from_view.cy) * 16
			else
				door_x = width/2
				door_y = height/2
			
			exit_door = @entering_door
			to_view = @views_by_room.get(@entering_room)
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
			
			if @transition_time >= 1 and not @transition_paused
				if @transition?.match("exit")
					@transition_time = 0
					@transition = null
					@leaving_room = null
					@entering_room = null
					@leaving_door = null
					@entering_door = null
					@leaving_world = null
					@entering_world = null
					@entering_room_id = null
				else
					if @entering_world
						@transition_paused = yes
						
						@entering_world.socket.sendMessage
							enterRoom:
								player: @leaving_world.getPlayer()
								from: room_id: @leaving_room.id, address: @leaving_world.serverAddress
								to: room_id: @entering_room_id, address: @entering_world.serverAddress
						
						# TODO: after some time, give up on entering the room and transition back
						# if we get enteredRoom after we gave up, it should just switch instantly
						
						# TODO: if you go to a different world, eventually disconnect and destroy the old World
						# (cancel if you come back within some period)
		
		@ctx2x.fillStyle = "black"
		@ctx2x.fillRect 0, 0, @canvas2x.width, @canvas2x.height
		@ctx2x.imageSmoothingEnabled = off
		@ctx2x.drawImage @canvas, 0, 0, @canvas2x.width, @canvas2x.height
