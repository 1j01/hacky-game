
World = require "./World"

canvas = document.createElement "canvas"
ctx = canvas.getContext "2d"
canvas2x = document.createElement "canvas"
ctx2x = canvas2x.getContext "2d"
document.body.appendChild canvas2x

animate = ->
	return if window.CRASHED
	requestAnimationFrame animate
	world.step()
	canvas2x.width = innerWidth
	canvas2x.height = innerHeight
	canvas.width = Math.ceil innerWidth / 2
	canvas.height = Math.ceil innerHeight / 2
	ctx.fillStyle = "black"
	ctx.fillRect 0, 0, canvas.width, canvas.height
	world.draw ctx
	
	ctx2x.imageSmoothingEnabled = off
	ctx2x.drawImage canvas, 0, 0, canvas2x.width, canvas2x.height

@worlds_by_port = {}
global.server.getPort (port)=>
	@worlds_by_port[port] =
	@world = new World onClientSide: yes, serverPort: port
	animate()
