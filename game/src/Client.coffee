
World = require "./World"

module.exports =
class Client
	constructor: ->
		@canvas = document.createElement "canvas"
		@ctx = @canvas.getContext "2d"
		@canvas2x = document.createElement "canvas"
		@ctx2x = @canvas2x.getContext "2d"
		document.body.appendChild @canvas2x
		
		# can be in different worlds
		@transitioning_from_room = null
		@transitioning_to_room = null
		@transitioning_from_door = null
		@transitioning_to_door = null
		@transitioning_from_world = null
		@transitioning_to_world = null
		@visible_world = null
		@transition = null # "basic", "booted"; null = not transitioning
		@transition_time = 0
		
		@last_shown_room = null
		
		@worlds_by_address = new Map

	start: (address)=>
		world = new World onClientSide: yes, serverAddress: address
		@worlds_by_address.set(address, world)
		@visible_world = world
		@animate()

	closeConnections: =>
		@worlds_by_address.forEach (world)->
			world.socket?._socket.destroy()

	animate: =>
		if window.CRASHED
			# TODO: not in production?
			console.log "Client: stopped because of an error"
			return
		requestAnimationFrame @animate
		@visible_world.step()
		@canvas2x.width = innerWidth if @canvas2x.width isnt innerWidth
		@canvas2x.height = innerHeight if @canvas2x.height isnt innerHeight
		@canvas.width = Math.ceil(innerWidth / 2) if @canvas.width isnt Math.ceil(innerWidth / 2)
		@canvas.height = Math.ceil(innerHeight / 2) if @canvas.height isnt Math.ceil(innerHeight / 2)
		@ctx.fillStyle = "black"
		@ctx.fillRect 0, 0, @canvas.width, @canvas.height
		@visible_world.draw @ctx
		
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
					fn = (x, y, t, width, height, door_x, door_y)->
						1 - (Math.hypot(x-door_x, y-door_y)) / width > t
				when "portal"
					transition_duration = 20
					fn = (x, y, t, width, height, door_x, door_y)->
						1 - (Math.hypot(x-door_x, y-door_y)) / width < t
				when "portal-exit"
					transition_duration = 20
					fn = (x, y, t, width, height, door_x, door_y)->
						(Math.hypot(x-door_x, y-door_y)) / width > t
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
					fn = (x, y, t, width, height, door_x, door_y)->
						1 - dist - 0.5 * ((Math.atan2(y-door_y, x-door_x) + dist * 5 + Math.sin(dist * 70)) %% (Math.PI / 5)) < t
				else
					throw new Error "Unknown transition type '#{@transition}'"
			
			unless localStorage.enable_transitions is "true"
				transition_duration = 0
			
			@transition_time += 1 / (1 + transition_duration)
			t = @transition_time
			
			# TODO: use exit door
			door = @transitioning_from_door
			if door?
				door_x = @ctx.canvas.width / 2 + (door.x + door.w/2 - @transitioning_from_world.view.cx) * 16
				door_y = @ctx.canvas.height / 2 + (door.y + door.h/2 - @transitioning_from_world.view.cy) * 16
			else
				door_x = width/2
				door_y = height/2
			
			for i in [0..data.length] by 4
				x = (i/4) % width
				y = (i/4) // width
				if fn(x, y, t, width, height, door_x, door_y)
					# data[i+0] = 0
					# data[i+1] = 0
					# # data[i+2] = 0
					data[i+3] = 0
			
			@ctx.putImageData(id, 0, 0)
			
			if @transition_time >= 1
				@transition_time = 0
				if @transition?.match("exit")
					@transition = null
				else
					@transition = "#{@transition}-exit"
				if @transitioning_to_world
					@visible_world = @transitioning_to_world
					@transitioning_to_world = null
					# TODO: find exit door if applicable
					# TODO: transition back if failed to load world or our player isn't in it
		
		@ctx2x.fillStyle = "black"
		@ctx2x.fillRect 0, 0, @canvas2x.width, @canvas2x.height
		@ctx2x.imageSmoothingEnabled = off
		@ctx2x.drawImage @canvas, 0, 0, @canvas2x.width, @canvas2x.height
		
		# doesn't work
		# shown_room = @visible_world.rooms[@visible_world]
		# if @last_shown_room isnt shown_room
		# 	@visible_world.centerViewForNewlyEnteredRoom()
		# 	@last_shown_room = shown_room
