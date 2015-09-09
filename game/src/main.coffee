
net = require "net"
World = require "./World"

# A local world, simulated for Dead Reckoning
# This is the only world that is drawn
@world = new World onClientSide: yes

# Close any existing socket (for reloading in development)
if global.socket
	global.socket.removeAllListeners "end"
	global.socket.end()

# The client starts out connected to it's own server
global.server.getPort (port)->
	global.socket = self.socket = net.connect {port}
	socket.on "end", ->
		console.warn "Disconnected from server!"
	socket.setEncoding "utf8"
	socket.on "data", (data)->
		for json in data.trim().split "\n"
			try
				message = JSON.parse json
			catch e
				console.error "failed to parse json message", json
			if message?.room
				world.applyRoomUpdate message.room
			else
				console.warn "unknown message"

# Create the drawing surface and animate and step the game
canvas = document.createElement "canvas"
document.body.appendChild canvas
ctx = canvas.getContext "2d"
do animate = ->
	return if window.CRASHED
	requestAnimationFrame animate
	canvas.width = innerWidth
	canvas.height = innerHeight
	ctx.fillStyle = "black"
	ctx.fillRect 0, 0, canvas.width, canvas.height
	world.step()
	world.draw ctx
