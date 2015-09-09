
World = require "./World"

# Create the drawing surface and animate and step the game
canvas = document.createElement "canvas"
document.body.appendChild canvas
ctx = canvas.getContext "2d"
animate = ->
	return if window.CRASHED
	requestAnimationFrame animate
	canvas.width = innerWidth
	canvas.height = innerHeight
	ctx.fillStyle = "black"
	ctx.fillRect 0, 0, canvas.width, canvas.height
	world.step()
	world.draw ctx

@worlds_by_port = {}
global.server.getPort (port)=>
	@worlds_by_port[port] =
	@world = new World onClientSide: yes, serverPort: port
	animate()
