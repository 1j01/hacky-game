
require "coffee-script/register"
World = require "./src/World"
Server = require "./src/Server"

# TODO: maybe wrap this stuff up in a Client or Game class?

canvas = document.createElement "canvas"
ctx = canvas.getContext "2d"
canvas2x = document.createElement "canvas"
ctx2x = canvas2x.getContext "2d"
document.body.appendChild canvas2x

animate = ->
	return if window.CRASHED
	requestAnimationFrame animate
	window.visible_world.step()
	# global.server?.world.step()
	canvas2x.width = innerWidth if canvas2x.width isnt innerWidth
	canvas2x.height = innerHeight if canvas2x.height isnt innerHeight
	canvas.width = Math.ceil(innerWidth / 2) if canvas.width isnt Math.ceil(innerWidth / 2)
	canvas.height = Math.ceil(innerHeight / 2) if canvas.height isnt Math.ceil(innerHeight / 2)
	ctx.fillStyle = "black"
	ctx.fillRect 0, 0, canvas.width, canvas.height
	window.visible_world.draw ctx
	
	if window.transition
		id = ctx.getImageData(0, 0, canvas.width, canvas.height)
		{data, width, height} = id
		
		switch window.transition
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
				throw new Error "Unknown transition type '#{window.transition}'"
		
		unless localStorage.enable_transitions is "true"
			transition_duration = 0
		
		window.transition_time += 1 / (1 + transition_duration)
		t = window.transition_time
		
		# TODO: use exit door
		door = window.transitioning_from_door
		if door?
			door_x = ctx.canvas.width / 2 + (door.x + door.w/2 - window.transitioning_from_world.view.cx) * 16
			door_y = ctx.canvas.height / 2 + (door.y + door.h/2 - window.transitioning_from_world.view.cy) * 16
		else
			door_x = width/2
			door_y = height/2
		
		for i in [0..data.length] by 4
			x = (i/4) % width
			y = (i/4) // width
			# if fn(x / id.width, y / id.height, t)
			if fn(x, y, t, width, height, door_x, door_y)
				# data[i+0] = 0
				# data[i+1] = 0
				# # data[i+2] = 0
				data[i+3] = 0
		
		# ctx.fillStyle = "black"
		# ctx.fillRect 0, 0, canvas.width, canvas.height
		ctx.putImageData(id, 0, 0)
		
		if window.transition_time >= 1
			window.transition_time = 0
			# window.transition =
			# 	switch window.transition
			# 		when "enter-door"
			# 			"exit-door"
			# 		when "enter-portal"
			# 			"exit-portal"
			# 		when "getting-booted"
			# 			"booted-exit"
			# 		else
			# 			null
			if window.transition?.match("exit")
				window.transition = null
			else
				window.transition = "#{window.transition}-exit"
			if window.transitioning_to_world
				window.visible_world = window.transitioning_to_world
				window.transitioning_to_world = null
				# TODO: find exit door if applicable
				# TODO: transition back if failed to load world (with our player in it)
	
	ctx2x.fillStyle = "black"
	ctx2x.fillRect 0, 0, canvas2x.width, canvas2x.height
	ctx2x.imageSmoothingEnabled = off
	ctx2x.drawImage canvas, 0, 0, canvas2x.width, canvas2x.height

# can be in different worlds
window.transitioning_from_room = null
window.transitioning_to_room = null
window.transitioning_from_door = null
window.transitioning_to_door = null
window.transitioning_from_world = null
window.transitioning_to_world = null
window.visible_room = null
window.transition = null # "basic", "booted"; null = not transitioning
window.transition_time = 0

window.worlds_by_address = new Map

window.addEventListener "unload", =>
	global.server?.close()
	global.peer?.close()
	worlds_by_address.forEach (world)->
		world.socket?._socket.destroy()

console.log "Starting server"
global.server = new Server (err)->
	console.error err if err

global.server.getAddress (address)->
	world = new World onClientSide: yes, serverAddress: address
	window.worlds_by_address.set(address, world)
	window.visible_world = world
	animate()
